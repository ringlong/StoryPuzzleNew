//
//  PieceView.m
//  Puzzle
//
//  Created by Andrea Barbon on 19/04/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
//

#import "PieceView.h"
#import "PuzzleController.h"
#import "GroupView.h"

@implementation PieceView

- (void)setup {
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    self.pan.delegate = self;
    self.pan.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.pan];
    
    UIRotationGestureRecognizer *rot = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];    
    [self addGestureRecognizer:rot];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rotateTap:)];
    tap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tap];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)pulse {    
    if (self.delegate.loadingGame) {
        return;
    }
    
    if (self.group && !self.group.isPositioned) {
        [self.group pulse];
        return;
        
    }
    
    [self removeFromSuperview];
    [self.delegate.view insertSubview:self aboveSubview:[self.delegate upperPositionedThing]];
    
    CATransform3D trasform = CATransform3DScale(self.layer.transform, 1.15, 1.15, 1);

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.toValue = [NSValue valueWithCATransform3D:trasform];
    animation.autoreverses = YES;
    animation.duration = 0.3;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.repeatCount = 2;
    [self.layer addAnimation:animation forKey:@"pulseAnimation"];
    
    return;
}

#pragma mark - GESTURE HANDLING

- (BOOL)isNeighborOf:(PieceView*)piece {
    for (PieceView *p in [self allTheNeighborsBut:nil]) {
        if (p.number == piece.number) {
            return YES;
        }
    }
    
    return NO;
}

- (CGPoint)sum:(CGPoint)a plus:(CGPoint)b {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

- (void)translateWithVector:(CGPoint)traslation {
    CGPoint newOrigin = [self sum:self.origin plus:traslation];
    CGRect newFrame = CGRectMake(newOrigin.x, newOrigin.y, self.width, self.height);
    self.frame = newFrame;
}

- (void)movedNeighborhoodExcludingPieces:(NSMutableArray*)excluded {
    
    for (NSInteger j = 0; j< self.neighbors.count; j++) {
        
        NSInteger i = [self.neighbors[j] integerValue];
        
        if (i < self.delegate.NumberSquare) {
            PieceView *piece = [self.delegate pieceWithNumber:i];
            
            BOOL present = NO;
            for (PieceView *p in excluded) {
                if (piece == p) {
                    present = YES;
                }
            }
            
            if (!present) {
                [excluded addObject:piece];
                [piece movedNeighborhoodExcludingPieces:excluded];
                [self.delegate pieceMoved:piece];
            }
        }
    }
    
}

- (void)translateNeighborhoodExcluding:(NSMutableArray*)excluded WithVector:(CGPoint)traslation {
    
    for (NSInteger j = 0; j < _neighbors.count; j++) {
        
        NSInteger i = [_neighbors[j] integerValue];
        
        if (i < _delegate.NumberSquare) {
            PieceView *piece = [_delegate pieceWithNumber:i];
            
            BOOL present = NO;
            for (PieceView *p in excluded) {
                if (piece == p) {
                    present = YES;
                }
            }
            
            if (!present) {
                [piece translateWithVector:traslation];
                [excluded addObject:piece];
                [piece translateNeighborhoodExcluding:excluded WithVector:traslation];
            }
        }
    }
    
}

- (BOOL)areTherePiecesBeingRotated {
    BOOL rotating = NO;
    for (PieceView *p in _delegate.pieces) {
        if (p.isRotating && !p.isFree) {
            return YES;
        }
    }

    return rotating;
}

- (void)move:(UIPanGestureRecognizer *)gesture {
    if (!self.userInteractionEnabled) {
        return;
    }
    if (_delegate.imageView.alpha == 1) {
        [_delegate toggleImageWithDuration:0.5];
    }
    
    CGPoint traslation = [gesture translationInView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.superview bringSubviewToFront:self];
        
        _oldPosition = [self realCenter];
        tr = 0;
        _delegate.drawerStopped = [_delegate drawerStoppedShouldBeStopped];
    }
    
    if (_isFree || _isLifted) { //In the board
        NSMutableArray *excluded = @[self].mutableCopy;
        
        if (!_group) {
            [self translateWithVector:traslation];
            [self translateNeighborhoodExcluding:excluded WithVector:traslation];
        } else {
            [_group translateWithVector:traslation];
        }
        
        [gesture setTranslation:CGPointZero inView:self.superview];
        
        if (gesture.state == UIGestureRecognizerStateEnded) {
            if (!_group) {
                [_delegate pieceMoved:self];
                if (_isFree) {
                    [self removeFromSuperview];
                    [_delegate.view insertSubview:self belowSubview:_delegate.drawerView];
                }
            } else {
                [_delegate groupMoved:_group];
                [_group removeFromSuperview];
                [_delegate.view insertSubview:_group aboveSubview:[_delegate upperGroupBut:_group]];
            }
        }
        
    } else { //Inside the drawer
        CGFloat xBound = 5;
        CGFloat yBound = 3;
        
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            if (!_delegate.drawerStopped && (ABS(traslation.x) < _delegate.piceSize/xBound || ABS(tr)>_delegate.piceSize/yBound )) {
                tr += ABS(traslation.y);
                [_delegate panDrawer:gesture];
            } else {
                [self translateWithVector:CGPointMake(traslation.x, 0)];
                [gesture setTranslation:CGPointZero inView:self.superview];
                self.isLifted = YES;
                if (_delegate.imageView.alpha == 1) {
                    [_delegate toggleImageWithDuration:0.5];
                }
            }
        } else {
            if (!_delegate.drawerStopped && (ABS(traslation.y) < _delegate.piceSize/xBound || ABS(tr)>_delegate.piceSize/yBound )) {
                tr += ABS(traslation.x);
                [_delegate panDrawer:gesture];
            } else {
                [self translateWithVector:CGPointMake(0, traslation.y)];
                [gesture setTranslation:CGPointZero inView:self.superview];
                self.isLifted = YES;
                if (_delegate.imageView.alpha == 1) {
                    [_delegate toggleImageWithDuration:0.5];
                }
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [_delegate touchesBegan:touches withEvent:event];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    
}

- (void)rotate:(UIRotationGestureRecognizer*)gesture {
    
    if (!self.hasNeighbors) {
        
        float rotation = [gesture rotation];
        
        if (gesture.state == UIGestureRecognizerStateEnded ||
            gesture.state == UIGestureRecognizerStateCancelled ||
            gesture.state == UIGestureRecognizerStateFailed) {
            
            NSInteger t = floor(ABS(_tempAngle) / M_PI_4);
            
            if (t % 2 == 0) {
                t /= 2;
            } else {
                t= (t + 1) / 2;
            }
            
            rotation = _tempAngle / ABS(_tempAngle) * t * M_PI_2 - _tempAngle;
            
            _angle += rotation;
            _angle = [PuzzleController computeFloat:_angle modulo:2 * M_PI];
            [self setAngle:_angle];
            
            //DLog(@"Angle = %.2f, Rot = %.2f, added +/- %d", angle, rotation, t);
            
            [UIView animateWithDuration:0.2 animations:^{
                
                self.transform = CGAffineTransformRotate(self.transform, rotation);
                
            } completion:^(BOOL finished) {

                self.isRotating = NO;
                _delegate.drawerView.userInteractionEnabled = YES;
                [_delegate pieceRotated:self];
            }];
            
            _tempAngle = 0;
   
        } else if (gesture.state == UIGestureRecognizerStateBegan ||
                   gesture.state == UIGestureRecognizerStateChanged) {
            
            _delegate.drawerView.userInteractionEnabled = NO;
            
            self.isRotating = YES;
            self.transform = CGAffineTransformRotate(self.transform, rotation);
            _tempAngle += rotation;
            _angle += rotation;

        }
        
        [gesture setRotation:0];
    }
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {

    CGPoint newPoint = CGPointMake(view.width * anchorPoint.x, view.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.width * view.layer.anchorPoint.x, view.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint pos = view.layer.position;
    
    pos.x -= oldPoint.x;
    pos.x += newPoint.x;
    
    pos.y -= oldPoint.y;
    pos.y += newPoint.y;
    
    view.layer.position = pos;
    view.layer.anchorPoint = anchorPoint;
}

- (void)rotateTap:(UITapGestureRecognizer *)gesture {
    if (!self.userInteractionEnabled) {
        return;
    }
        
    _angle += M_PI_2;
    _angle = [PuzzleController computeFloat:_angle modulo:2 * M_PI];
    [self setAngle:_angle];
    
    if (!_group) {
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformRotate(self.transform, M_PI_2);
        } completion:^(BOOL finished) {
            [_delegate pieceRotated:self];
        }];
    } else {
        CGPoint point = self.center;
        _group.boss.isBoss = NO;
        _group.boss = self;
        self.isBoss = YES;

        [self setAnchorPoint:CGPointMake(point.x / _group.bounds.size.width, point.y / _group.bounds.size.height) forView:_group];
        
        _group.angle += M_PI_2;
        _group.angle = [PuzzleController computeFloat:_group.angle modulo:2 * M_PI];
        
        CGAffineTransform transform = _group.transform;
        transform = CGAffineTransformRotate(transform, M_PI_2);
        
        [UIView animateWithDuration:0.2 animations:^{
            _group.transform = transform;
        } completion:^(BOOL finished) {
            [_delegate pieceRotated:self];
        }];
                
    }
}

#pragma mark - DRAWING

- (void)drawEdgeNumber:(NSInteger)n ofType:(NSInteger)type inContext:(CGContextRef)ctx {
    
    CGFloat x = CGRectGetWidth(self.bounds);
    CGFloat y = CGRectGetHeight(self.bounds);
    CGFloat p = self.padding;
    CGFloat width = x - 2 * p;
    CGFloat height = y - 2 * p;
    
    // 1:逆时针，inside， 0:顺时针， outside
    int clockwise = type < 0 ? 1 : 0;
    
    CGFloat radius = width / 6;

    CGPoint a = CGPointZero;            // 起始端点
    CGPoint b = CGPointZero;            // 结束端点
    CGPoint control = CGPointZero;      // 贝塞尔曲线控制点
    CGPoint center = CGPointZero;       // 圆心
    CGPoint keyPoint = CGPointZero;     // 位置点
    CGFloat startAngle = 0;
    CGFloat endAngle = 0;
    
    CGFloat keyPointOffsetEdge = radius * (1.3 - M_SQRT1_2);        // 相对于边的偏移量
    CGFloat keyPointOffsetCenter = radius * M_SQRT1_2;            // 相对于中线的偏移量
    CGFloat circleCenterOffset = 1.3 * radius;                         // 圆心相对于边的偏移量
    CGFloat controlPointOffset = 5;                                    // 控制点偏移量
    
    CGFloat centerPosition = 0;
    switch (n) {
        case 1:
            // Top
            a = CGPointMake(p, p);
            b = CGPointMake(x - p, p);
            centerPosition = p + width / 2;
            if (clockwise) {
                // Inside
                control = CGPointMake(centerPosition, p - controlPointOffset);
                center = CGPointMake(centerPosition, p + circleCenterOffset);
                keyPoint = CGPointMake(centerPosition - keyPointOffsetCenter, p + keyPointOffsetEdge);
                startAngle = -3 * M_PI_4;
                endAngle = -M_PI_4;
            } else {
                // Outside
                control = CGPointMake(centerPosition, p + controlPointOffset);
                center = CGPointMake(centerPosition, p - circleCenterOffset);
                keyPoint = CGPointMake(centerPosition - keyPointOffsetCenter, p - keyPointOffsetEdge);
                startAngle = 3 * M_PI_4;
                endAngle = M_PI_4;
            }
            break;
        case 2:
            // Right
            a = CGPointMake(x - p, p);
            b = CGPointMake(x - p, y - p);
            centerPosition = p + height / 2;
            if (clockwise) {
                // Inside
                control = CGPointMake(x - p + controlPointOffset, centerPosition);
                center = CGPointMake(x - p - circleCenterOffset, centerPosition);
                keyPoint = CGPointMake(x - p - keyPointOffsetEdge, centerPosition - keyPointOffsetCenter);
                startAngle = -M_PI_4;
                endAngle = M_PI_4;
            } else {
                // Outside
                control = CGPointMake(x - p - controlPointOffset, centerPosition);
                center = CGPointMake(x - p + circleCenterOffset, centerPosition);
                keyPoint = CGPointMake(x - p + keyPointOffsetEdge, centerPosition - keyPointOffsetCenter);
                startAngle = -3 * M_PI_4;
                endAngle = 3 * M_PI_4;
            }
            break;
        case 3:
            // Bottom
            a = CGPointMake(x - p, y - p);
            b = CGPointMake(p, y - p);
            centerPosition = p + width / 2;
            if (clockwise) {
                // Inside
                control = CGPointMake(centerPosition, y - p + controlPointOffset);
                center = CGPointMake(centerPosition, y - p - circleCenterOffset);
                keyPoint = CGPointMake(centerPosition + keyPointOffsetCenter, y - p - keyPointOffsetEdge);
                startAngle = M_PI_4;
                endAngle = 3 * M_PI_4;
            } else {
                // Outside
                control = CGPointMake(centerPosition, y - p - controlPointOffset);
                center = CGPointMake(centerPosition, y - p + circleCenterOffset);
                keyPoint = CGPointMake(centerPosition + keyPointOffsetCenter, y - p + keyPointOffsetEdge);
                startAngle = -M_PI_4;
                endAngle = -3 * M_PI_4;
            }
            break;
        case 4:
            // Left
            a = CGPointMake(p, y - p);
            b = CGPointMake(p, p);
            centerPosition = p + height / 2;
            if (clockwise) {
                // Inside
                control = CGPointMake(p - controlPointOffset, centerPosition);
                center = CGPointMake(p + circleCenterOffset, centerPosition);
                keyPoint = CGPointMake(p + keyPointOffsetEdge, centerPosition + keyPointOffsetCenter);
                startAngle = 3 * M_PI_4;
                endAngle = -3 * M_PI_4;
            } else {
                // Outside
                control = CGPointMake(p + controlPointOffset, centerPosition);
                center = CGPointMake(p - circleCenterOffset, centerPosition);
                keyPoint = CGPointMake(p - keyPointOffsetEdge, centerPosition + keyPointOffsetCenter);
                startAngle = M_PI_4;
                endAngle = -M_PI_4;
            }
            break;
        default:
            break;
    }

    if (type) {
        CGContextAddQuadCurveToPoint(ctx, control.x, control.y, keyPoint.x, keyPoint.y);
        CGContextAddArc(ctx, center.x, center.y, radius, startAngle, endAngle, clockwise);
        CGContextAddQuadCurveToPoint(ctx, control.x, control.y, b.x, b.y);
    } else {
        CGContextAddLineToPoint(ctx, b.x, b.y);
    }
}


- (void)drawRect:(CGRect)rect {
    
    if (!_delegate.loadingGame && !_delegate.creatingGame) {
        [_delegate prepareForLoading];
        [_delegate loadPuzzle:_delegate.puzzleDB];
        return;
    }
    
    _padding = self.width * 0.23;
    float LINE_WIDTH = self.width * 0.005;
        
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 0.2);
    CGContextSetLineWidth(ctx, LINE_WIDTH);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, self.padding, self.padding);

    for (NSInteger i = 1; i < 5; i++) {
        NSInteger e = _edges[i - 1].integerValue;
        [self drawEdgeNumber:i ofType:e inContext:ctx];
    }

    CGContextClip(ctx);
    [_image drawInRect:CGRectMake(0, 0, self.width, self.height)];

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, self.padding, self.padding);
    
    for (NSInteger i = 1; i < 5; i++) {
        NSInteger e = _edges[i - 1].integerValue;
        [self drawEdgeNumber:i ofType:e inContext:ctx];
    }
    
    CGContextDrawPath(ctx, kCGPathStroke);
    
    _delegate.loadedPieces++;    
    DLog(@"Piece #%d drawn, loadedPieces %d", number, _delegate.loadedPieces);
    [_delegate moveBar];
    
    NSInteger pieceNumber = (_delegate.NumberSquare - _delegate.missedPieces);

    if (_delegate.loadedPieces > pieceNumber) {
        DLog(@"loadedPieces resetted");
        _delegate.loadedPieces = 0;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PiecesNotifications" object:self];
    
    if (_delegate.loadedPieces == pieceNumber && !_delegate.duringGame) {
        [_delegate allPiecesLoaded];
    } else {
        [_delegate performSelectorOnMainThread:@selector(addAnothePieceToView) withObject:nil waitUntilDone:NO];
    }
    /*
    label = [[UILabel alloc] initWithFrame:self.bounds];
    label.text = [NSString stringWithFormat:@"%@", @(self.number)];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    [self addSubview:label];
    */
}

- (NSInteger)edgeNumber:(NSInteger)i {
    return _edges[i].integerValue;
}

- (void)setNeighborNumber:(NSInteger)i forEdge:(NSInteger)edge {
    NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:4];
    
    for (NSInteger j=0; j<4; j++) {
        
        if (j == edge) {
            [temp addObject:@(i)];
        } else {
            [temp addObject:[_neighbors objectAtIndex:j]];
        }
        
    }
    
    _neighbors = [[NSArray alloc] initWithArray:temp];
    
    _hasNeighbors = YES;
    
}

- (BOOL)isCompleted {
    for (NSNumber *n in _neighbors) {
        if (n.integerValue == _delegate.NumberSquare) {
            return NO;
        }
    }
    return YES;
}

- (NSArray *)allTheNeighborsBut:(NSMutableArray *)excluded {
    if (!excluded) {
        excluded = [[NSMutableArray alloc] init];
    }
    
    [excluded addObject:self];
    
    NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:_delegate.NumberSquare - 1];
    for (NSInteger j = 0; j < self.neighbors.count; j++) {
        NSInteger i = [self.neighbors[j] integerValue];
        
        if (i < _delegate.NumberSquare) {
            PieceView *otherPiece = [_delegate pieceWithNumber:i];
            
            BOOL present = NO;
            for (PieceView *p in excluded) {
                if (otherPiece.number == p.number) {
                    present = YES;
                }
            }
            
            if (!present) {
                [temp addObject:otherPiece];
            }
        }
    }            
    
    NSMutableArray *temp2 = [[NSMutableArray alloc] initWithArray:temp];
    [excluded addObjectsFromArray:temp];

    for (PieceView *p in temp2) {
        [temp addObjectsFromArray:[p allTheNeighborsBut:excluded]];
    }

    return [NSArray arrayWithArray:temp];
}

- (void)setPositionInDrawer:(NSInteger)positionInDrawer_ {
    _positionInDrawer = positionInDrawer_;
}

- (void)setIsPositioned:(BOOL)isPositioned_ {
    if (isPositioned_ && !_isPositioned && !_delegate.loadingGame) {
        //[self pulse];
    }
        
    _isPositioned = isPositioned_;
    self.userInteractionEnabled = !_isPositioned;

}

#pragma mark -

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (CGPoint)realCenter {
    return  CGPointMake(self.frame.origin.x + self.frame.size.width / 2, self.frame.origin.y + self.frame.size.height / 2);
}

@end
