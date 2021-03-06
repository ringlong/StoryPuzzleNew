//
//  PieceView.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PieceView;
@class PuzzleController;
@class GroupView;


@protocol PieceViewProtocol

- (void)pieceMoved:(PieceView*)piece;
- (void)pieceRotated:(PieceView*)piece;

@end


@interface PieceView : UIView <UIGestureRecognizerDelegate> {
    float tr;
    UILabel *label;
}

//@property (nonatomic, assign) id<PieceViewProtocol> delegate;
@property (nonatomic, assign) PuzzleController *delegate;


@property (nonatomic, retain) NSArray<NSNumber *> *edges;
@property (nonatomic, retain) NSArray *neighbors;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIView *centerView;
@property (nonatomic, retain) UIPanGestureRecognizer *pan;

@property (nonatomic, retain) GroupView *group;

@property (nonatomic) BOOL isPositioned;
@property (nonatomic) BOOL isLifted;
@property (nonatomic) BOOL isFree;
@property (nonatomic) BOOL isRotating;
@property (nonatomic) BOOL isBoss;
@property (nonatomic) BOOL hasNeighbors;

@property (nonatomic) CGPoint oldPosition;

@property (nonatomic) NSInteger number;
@property (nonatomic) NSInteger position;
@property (nonatomic) NSInteger positionInDrawer;
@property (nonatomic) NSInteger moves;
@property (nonatomic) NSInteger rotations;

@property (nonatomic) float angle;
@property (nonatomic) float size;
@property (nonatomic) float padding;
@property (nonatomic) float tempAngle;

- (void)move:(UIPanGestureRecognizer*)gesture;
- (void)rotate:(UIRotationGestureRecognizer*)gesture;
- (void)rotateTap:(UITapGestureRecognizer*)gesture;

- (NSInteger)edgeNumber:(NSInteger)i;
- (void)setNeighborNumber:(NSInteger)i forEdge:(NSInteger)edge;
- (NSArray *)allTheNeighborsBut:(NSMutableArray *)excluded;
- (CGPoint)realCenter;
- (void)pulse;
- (BOOL)isCompleted;

@end
