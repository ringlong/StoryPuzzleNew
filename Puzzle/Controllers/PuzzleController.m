//
//  PuzzleController.m
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#define PIECE_NUMBER 4
#define ORG_TIME 0.5

#define IMAGE_SIZE_BOUND_IPAD (2 * PIECE_SIZE_IPAD)
#define IMAGE_SIZE_BOUND_IPHONE (3 * PIECE_SIZE_IPHONE)

#define JPG_QUALITY 1
#define SHAPE_QUALITY_IPAD 1
#define SHAPE_QUALITY_IPHONE 3

#import "PuzzleController.h"
#import "AppDelegate.h"
#import "GroupView.h"
#import "LoadGameController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

NSString * const kPieceNumberChangedNotification = @"PieceNumberChanged";

@interface PuzzleController ()

@property (nonatomic, strong) UIButton *nextButton;

@end

@implementation PuzzleController

@synthesize operationQueue, managedObjectContext, persistentStoreCoordinator;

#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (IS_iPad){
        _panningSwitch.hidden = YES;
    } else {
        _imageSize *= 0.5;
        _panningSwitch.transform = CGAffineTransformScale(_panningSwitch.transform, 0.8, 0.8);
    } 
    
    directions_numbers = NSArray.new;
    directions_positions = NSArray.new;
    _imageSize = QUALITY;
    
    self.view.backgroundColor = [UIColor puzzleBackgroundColor];
    _drawerView.backgroundColor = [UIColor clearColor];
    self.view.frame = [UIScreen mainScreen].bounds;
      
    [self computePieceSize];
    
    // Add the images;
    _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _imageView.alpha = 0;
    [self.view addSubview:_imageView];
    
    _imageViewLattice = [[UIImageView alloc] initWithImage:_image];
    
    _puzzleComplete = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 58)];
    _puzzleComplete.text = @"Puzzle Complete";
    _puzzleComplete.textColor = [UIColor whiteColor];
    _puzzleComplete.font = [UIFont fontWithName:@"Bello-Pro" size:50];
    [self.view addSubview:_puzzleComplete];
    _puzzleComplete.hidden = YES;
    
    // Resize the drawer
    _drawerView.height = drawerSize;
    _drawerView.width = UIScreen.screenHeight;
    _drawerView.top = UIScreen.screenHeight - drawerSize;
    stepperDrawer.top = drawerSize;
    stepperDrawer.left = 10;
    
    // Add the menu
    _menu = [[MenuController alloc] init];
    _menu.delegate = self;
    _menu.duringGame = NO;
    _menu.view.center = self.view.center;
    [self.view addSubview:_menu.view];
    
    
    // Add the puzzleCompletedController
    NSString *nibName = @"PuzzleCompletedController_iPhone";
    _completedController = [[PuzzleCompletedController alloc] initWithNibName:nibName bundle:nil];
    _completedController.delegate = self;
    [self.view addSubview:_completedController.view];
    _completedController.view.center = CGPointMake(self.view.center.x, UIScreen.screenHeight - 30);
    _completedController.view.alpha = 0;
    
    //gesture recognizers
    [self addGestures];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSArray *)directionsUpdated_numbers {
    // up = 0, right = 1, down = 2, left = 3
    return @[@(-1), @(_pieceNumber), @1, @(-_pieceNumber)];
}

- (NSArray *)directionsUpdated_positions {
    return @[@(-1), @(3 * _pieceNumber), @1, @(-3 * _pieceNumber)];
}

- (void)setup {
    _pieceNumber = PIECE_NUMBER;
    _NumberSquare = _pieceNumber * _pieceNumber;
    self.view.frame = [UIScreen mainScreen].bounds;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    
    [super awakeFromNib];
    [self setup];
}

#pragma mark - score

- (void)addPoints:(NSInteger)add {
    _score += add;
    [self updatescoreLabel];
}

- (void)updatescoreLabel {
    scoreLabel.text = @(_score).stringValue;
}

- (NSInteger)pointsForPiece:(PieceView *)piece {
    NSInteger points = 1000 + (piece.moves ? 1000 / piece.moves : 0) + 1000 / (piece.rotations + 1) + _NumberSquare * 1000 / (NSInteger)(_elapsedTime + 10);
//    int points = 1000 + 1000/piece.moves + 1000/(piece.rotations+1) + _NumberSquare*1000/(int)(_elapsedTime+10);
    return points;
}

#pragma mark - Puzzle

- (void)showNextButton {
    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setTitle:@"Next" forState:UIControlStateNormal];
    _nextButton.titleLabel.font = [UIFont fontWithName:@"Bello-Pro" size:40];
    _nextButton.frame = CGRectMake((self.view.bounds.size.width - 100) / 2, 450, 100, 40);
    [self.view addSubview:_nextButton];
    
    [_nextButton addTarget:self action:@selector(showNextGame:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showCompleteImage {
    [self centerCompletedImage];
    
    [self.view bringSubviewToFront:_puzzleComplete];

    [UIView animateWithDuration:1 animations:^{
        _puzzleComplete.hidden = NO;
    }];
    
    _puzzleComplete.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1 / 1.8, 1 / 1.8);
    
    [UIView beginAnimations:@"pulseAnimation" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationRepeatAutoreverses:YES];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationRepeatCount:2.5];
    [UIView setAnimationDelegate:self];
    
    _puzzleComplete.transform = CGAffineTransformScale(_puzzleComplete.transform, 1.8, 1.8);
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (finished.boolValue) {
        if ([animationID isEqualToString:@"pulseAnimation"]) {
            float f = UIScreen.screenWidth / (_pieceNumber + 1) / (_piceSize - 2 * _padding);
            
            [UIView animateWithDuration:1.5 animations:^{
                _completedController.view.alpha = 1;
            }];
            
            [UIView animateWithDuration:0.5 animations:^{
    
            } completion:^(BOOL finished) {
                [self resizeLatticeToScale:f];
            }];
            
            float translation = 0;
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                translation = -UIScreen.screenWidth / 2 + _puzzleComplete.bounds.size.height / 2;
            } else {
                translation = -UIScreen.screenHeight / 2 + _puzzleComplete.bounds.size.height / 2;
            }
            translation += 30;
            
            if (!didRotate) {
                translation += 20;
            }

            [UIView animateWithDuration:1 animations:^{
                _puzzleComplete.transform = CGAffineTransformMakeTranslation(0, translation);
            }];
        }
        
        [self.managedObjectContext deleteObject:_puzzleDB];
    }
}

- (void)loadPuzzle:(Puzzle *)puzzleDB_ {
    _puzzleDB = puzzleDB_;
    loadingFailed = NO;
    
    [self prepareForNewPuzzle];
    [self computePieceSize];
        
    if (_puzzleDB) {
        [self removeOldPieces];
        [self setPieceNumber:[_puzzleDB.pieceNumber intValue]];
    
        _image = [UIImage imageWithData:_puzzleDB.image.data];
        _groups = [[NSMutableArray alloc] initWithCapacity:_NumberSquare/2];
        _elapsedTime = [_puzzleDB.elapsedTime floatValue];
        percentageLabel.text = [NSString stringWithFormat:@"%.0f %%", [_puzzleDB.percentage floatValue]];
        _moves = _puzzleDB.moves.intValue;
        _rotations = _puzzleDB.rotations.intValue;
        _score = _puzzleDB.score.intValue;
        [self updatescoreLabel];
        
        DLog(@"_score = %d, piece number = %d, percentage = %d", _score, _NumberSquare, [puzzleDB.percentage intValue]);
        
        if (_puzzleDB.percentage.intValue==100) {
            _puzzleCompete = YES;
            [_menu startNewGame:nil];
            return;
        }
        [self createPuzzleFromSavedGame];
    } else {
        [_menu startNewGame:nil];
    }
}

- (IBAction)toggleMenu:(UIButton *)sender {
    _menu.duringGame = (_puzzleDB != nil);
    [_nextButton removeFromSuperview];
    [self.view bringSubviewToFront:_menu.obscuringView];
    [self.view bringSubviewToFront:_menu.view];
    [self.view bringSubviewToFront:_menuButtonView];
    [_menu toggleMenuWithDuration:(sender != nil) * 0.5];
//    _menu.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    [self presentViewController:_menu animated:YES completion:NULL];
}

- (void)prepareForLoading {
    _menu.duringGame = (_puzzleDB != nil);
    [self.view bringSubviewToFront:_menu.obscuringView];
    [self.view bringSubviewToFront:_menu.game.view];
    [self.view bringSubviewToFront:_menuButtonView];
    _menu.game.view.frame = CGRectMake(0, 0, _menu.game.view.width, _menu.game.view.height);
    _menu.mainView.frame = CGRectMake(_menu.mainView.width, 0, _menu.mainView.width, _menu.mainView.height);
    [_menu toggleMenuWithDuration:0];
}

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)puzzleSaved:(NSNotification *)saveNotification {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(puzzleSaved:) withObject:saveNotification waitUntilDone:NO];
    } else {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
        _puzzleDB = [self lastSavedPuzzle];
    }
}

- (void)merged:(NSNotification *)saveNotification {
    
}

- (void)addPiecesToView {
    if ([NSThread isMainThread]) {
        for (PieceView *p in _pieces) {
            [self.view addSubview:p];
        }
    } else {
        [self performSelectorOnMainThread:@selector(addPiecesToView) withObject:nil waitUntilDone:NO];
    }
}

- (void)allPiecesLoaded {
    if (loadingFailed) {
        return;
    }
    _duringGame = YES;
    for (PieceView *p in _pieces) {
        if (!p.isFree) {
            p.frame = CGRectMake(0, 0, _piceSize, _piceSize);
        }
    }

    BOOL debugging = NO;
    
    if (debugging) {
        for (PieceView *p in _pieces) {
            p.isFree = YES;
            p.isPositioned = YES;
            [self movePiece:p toLatticePoint:p.number animated:NO];
        }
        [_imageViewLattice removeFromSuperview];
        
    } else {
        drawerFirstPoint = CGPointMake(-4, 5);
        if (_loadingGame) {
            _pieces = [self shuffleArray:_pieces];
            for (PieceView *p in _pieces) {
                [self isPositioned:p];
            }

            [self resetSizeOfAllThePieces];
            [self shuffleAngles];
            [self refreshPositions];
            [self organizeDrawerWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
            [self checkNeighborsForAllThePieces];
            [self updatePercentage];
            _loadingGame = NO;
        } else {
            _puzzleDB = [self lastSavedPuzzle];
            DLog(@"Name: %@", puzzleDB.name);
            [self resetSizeOfAllThePieces];
            [self shuffle];
            [self updatePercentage];
            [self organizeDrawerWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
            _creatingGame = NO;
        }
        [self bringDrawerToTop];
    }

    [_menu.game gameStarted];
    self.view.userInteractionEnabled = YES;
    [self resetLatticePositionAndSizeWithDuration:0.0];
}

- (void)loadingFailed {
    
    loadingFailed = YES;
    _menu.duringGame = NO;
    [_menu.game loadingFailed];
    [_puzzleOperation cancel];
    self.view.userInteractionEnabled = YES;
    [_menu toggleMenuWithDuration:0];
    
}

- (void)centerCompletedImage {
    _puzzleComplete.center = self.view.center;
}

- (void)prepareForNewPuzzle {
    DLog(@"Preparing for new puzzle");
    
    [self.view bringSubviewToFront:_lattice];
    [self.view bringSubviewToFront:_drawerView];
    [self.view bringSubviewToFront:HUDView];
    
    _missedPieces = 0;
    _loadedPieces = 0;

    _panningSwitch.alpha = 0.5;
    _drawerView.alpha = 1;
    percentageLabel.alpha = 1;
    _elapsedTimeLabel.alpha = 1;
    scoreLabel.alpha = 1;

    _drawerStopped = NO;
    panningMode = NO;
    _duringGame = NO;
    
    _puzzleComplete.hidden = YES;
    _completedController.view.alpha = 0;
    
    if (!_loadingGame) {
        _elapsedTime = 0.0;
        _score = 0;
        scoreLabel.text = @"0 ";
    }
    
    directions_numbers = [NSArray arrayWithArray:[self directionsUpdated_numbers]];
    directions_positions = [NSArray arrayWithArray:[self directionsUpdated_positions]];
    [self computePieceSize];
    [self createLattice];
    drawerFirstPoint = CGPointMake(-4, 5);
    
    // add the importer to an operation queue for background processing (works on a separate thread)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myNotificationResponse:) name:@"GTCNotification" object:nil];
    _puzzleOperation = [[CreatePuzzleOperation alloc] init];
    _puzzleOperation.delegate = self;
    _puzzleOperation.loadingGame = _loadingGame;
    _puzzleOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
}

- (void)myNotificationResponse:(NSNotification *)note {
    NSNumber *count = note.object;
    [self.view addSubview:_pieces[count.integerValue]];
}

- (void)updateView:(NSNumber *)count {
    [self.view addSubview:_pieces[count.integerValue]];
}

- (void)createPuzzleFromSavedGame {
    _loadingGame = YES;
    self.view.userInteractionEnabled = NO;    
    [self prepareForNewPuzzle];

    _menu.game.view.frame = CGRectMake(0, 0, _menu.game.view.width, _menu.game.view.height);
    
    _image = [UIImage imageWithData:_puzzleDB.image.data];
    
    _imageView.image = _image;
    _imageView.frame = CGRectMake(0, 0, UIScreen.screenWidth, _image.size.height * UIScreen.screenWidth / _image.size.width);
    _imageViewLattice.image = _image;
    
    [_menu.game startLoading];
    
    dispatch_queue_t main_queue = dispatch_get_main_queue();
    dispatch_async(main_queue, ^{
        [self createPieces];
        dispatch_async(main_queue, ^{
            [self addAnothePieceToView];
        });
    });
}

- (void)createPuzzleFromImage:(UIImage *)image {
    _loadingGame = NO;
    _creatingGame = YES;
    _moves = 0;
    _rotations = 0;
    
    [self prepareForNewPuzzle];
    dispatch_queue_t main_queue = dispatch_get_main_queue();
    dispatch_async(main_queue, ^{
        [self createPieces];
        dispatch_async(main_queue, ^{
            [self addAnothePieceToView];
        });
    });
}

- (void)createPieces {
    DLog(@"Creating pieces");
    float imageSizeBound = IS_iPad ? IMAGE_SIZE_BOUND_IPAD : IMAGE_SIZE_BOUND_IPHONE;
    float shapeQuality = IS_iPad ? SHAPE_QUALITY_IPAD : SHAPE_QUALITY_IPHONE;
    
    NSMutableArray<PieceView *> *arrayPieces = [[NSMutableArray alloc] initWithCapacity:_NumberSquare];
    NSMutableArray *array;
    
    if (_loadingGame) {
        if (!self.image) {
            return;
        }
    } else {
        // Compute the optimal part size
        float partSize = _image.size.width / (_pieceNumber * 0.7);
        if (partSize > imageSizeBound) {
            partSize = imageSizeBound;
        }
        
        // and split the big image using computed size
        float f = _pieceNumber * partSize * 0.7;
        _image = [_image imageCroppedToSquareWithSide:f];
        _imageView.image = _image;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        array = [[NSMutableArray alloc] initWithArray:[self splitImage:_image partSize:partSize]];
    }
    
    if (_loadingGame) {
    
        for (NSInteger i = 0; i < _pieceNumber; i++) {
            for (NSInteger j = 0; j < _pieceNumber; j++) {
                CGRect rect = CGRectMake( 0, 0, shapeQuality * _piceSize, shapeQuality * _piceSize);

                Piece *pieceDB = [self pieceOfCurrentPuzzleDB:j + _pieceNumber * i];
                if (pieceDB) {
                    PieceView *piece = [[PieceView alloc] initWithFrame:rect];
                    piece.delegate = self;
                    piece.image = [UIImage imageWithData:pieceDB.image.data];
                    piece.number = j + _pieceNumber * i;
                    piece.size = _piceSize;
                    piece.isFree = [pieceDB isFreeScalar];
                    piece.position = [pieceDB.position intValue];
                    piece.angle = [pieceDB.angle floatValue];
                    piece.moves = [pieceDB.moves intValue];
                    piece.rotations = [pieceDB.rotations intValue];
                    piece.transform = CGAffineTransformMakeRotation(piece.angle);
        
                    NSNumber *n = @(_NumberSquare);
                    piece.neighbors = @[n, n, n, n];
                    
                    NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:4];
                    [a addObject:pieceDB.edge0];
                    [a addObject:pieceDB.edge1];
                    [a addObject:pieceDB.edge2];
                    [a addObject:pieceDB.edge3];
                    piece.edges = [NSArray arrayWithArray:a];
                    [arrayPieces addObject:piece];
                }
            }
        }
        
    } else {
        for (int i = 0; i < _pieceNumber; i++){
            
            for (int j = 0; j < _pieceNumber; j++){
                
                CGRect rect = CGRectMake( 0, 0, shapeQuality * _piceSize, shapeQuality * _piceSize);
                
                PieceView *piece = [[PieceView alloc] initWithFrame:rect];
                piece.delegate = self;
                piece.image = array[j + _pieceNumber * i];
                piece.number = j + _pieceNumber * i;
                piece.size = _piceSize;
                piece.position = -1;
                NSNumber *n = @(_NumberSquare);
                piece.neighbors = @[n, n, n, n];

                NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:4];
                
                for (int k = 0; k < 4; k++) {
                    int e = arc4random_uniform(3) + 1;
                    if (arc4random_uniform(2) > 0) {
                        e *= -1;
                    }
                    [a addObject:@(e)];
                }
                
                if (i > 0) {
                    NSInteger l = arrayPieces.count - _pieceNumber;

                    NSInteger e = [arrayPieces[l].edges[1] integerValue];
                    [a replaceObjectAtIndex:3 withObject:@(-e)];
                }
                
                if (j > 0) {
                    int e = [[[[arrayPieces lastObject] edges] objectAtIndex:2] intValue];
                    [a replaceObjectAtIndex:0 withObject:@(-e)];
                }
                
                if (i == 0) {
                    [a replaceObjectAtIndex:3 withObject:@0];
                }
                if (i == _pieceNumber - 1) {
                    [a replaceObjectAtIndex:1 withObject:@0];
                }
                if (j == 0) {
                    [a replaceObjectAtIndex:0 withObject:@0];
                }
                if (j == _pieceNumber - 1) {
                    [a replaceObjectAtIndex:2 withObject:@0];
                }                
                piece.edges = [NSArray arrayWithArray:a];                
                
                [arrayPieces addObject:piece];
            }
        }
    
    } //end if loadingGame   
    
    _pieces = [[NSMutableArray alloc] initWithArray:arrayPieces];
    
    _loadedPieces = 0;
            
    [self.operationQueue addOperations:[NSArray arrayWithObject:_puzzleOperation] waitUntilFinished:NO];
}

- (void)addAnothePieceToView {
    if (_loadedPieces >= _pieces.count) {
        return;
    }
    
    [self.view insertSubview:_pieces[_loadedPieces] belowSubview:_menu.obscuringView];
}

- (void)moveBar {
    float a = (float)_loadedPieces;
    float b = (float)_NumberSquare;
    
    if (_loadingGame) {
        b = _NumberSquare;
    }
    _menu.game.progressView.progress = a / b;
}

- (NSArray *)splitImage:(UIImage *)im partSize:(float)partSize {
    
    float x = _pieceNumber;
    float y= _pieceNumber;
    
    float padding_temp = partSize * 0.23;
    
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:_NumberSquare];
    for (int i = 0; i < x; i++){
        for (int j = 0; j < y; j++){
            CGRect rect = CGRectMake(i * (partSize - 2 * padding_temp) - padding_temp,
                                     j * (partSize - 2 * padding_temp) - padding_temp,
                                     partSize,
                                     partSize);
            [arr addObject:[im subimageWithRect:rect]];
        }
    }
    
    DLog(@"Image splitted");

    return arr;
}

- (BOOL)isPuzzleComplete {
    if (_puzzleCompete) {
        return YES;
    } else {
        for (PieceView *p in _pieces) {
            if (!p.isPositioned && !p.group.isPositioned) {
                return NO;
            }
        }
        [self puzzleCompleted];
    }
    return _puzzleCompete;
}

- (void)toggleImage:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan && _menu.view.alpha == 0) {
        [self toggleImageWithDuration:0.5];
    }
}

- (void)toggleImageWithDuration:(float)duration {
    [UIView animateWithDuration:duration animations:^{
        if (_imageView.alpha == 0) {
            _menuButtonView.userInteractionEnabled = NO;
            [self.view bringSubviewToFront:_imageView];
            _imageView.alpha = 1;
        } else if (_imageView.alpha == 1) {
            _menuButtonView.userInteractionEnabled = YES;
            _imageView.alpha = 0;
        }
    }];
}

- (IBAction)puzzleCompleted {
    _puzzleCompete = YES;
    [self stopTimer];
    [_completedController updateValues];

    [UIView animateWithDuration:2 animations:^{
        _drawerView.alpha = 0;
        _panningSwitch.alpha = 0;
        percentageLabel.alpha = 0;
        _elapsedTimeLabel.alpha = 0;
        scoreLabel.alpha = 0;
        for (UIView *v in _lattice.pieces) {
            v.alpha = 0;
        }
    } completion:^(BOOL finished) {
        [self saveGame];
        [self.view bringSubviewToFront:_lattice];
        [self.view bringSubviewToFront:_completedController.view];
        [self.view bringSubviewToFront:HUDView];
    }];
    
    [self showCompleteImage];
    [self showNextButton];
}

- (IBAction)restartPuzzle:(id)sender {
    [self createPuzzleFromImage:_image];
}

- (void)showNextGame:(UIButton *)sender {
    self.pieceNumber += 1;
    [self toggleMenu:nil];
    [self.menu startNewGame:nil];
    [sender removeFromSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPieceNumberChangedNotification object:nil];
}

#pragma mark - Gesture handling
- (void)addGestures {
    _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    _pinch.delegate = self;
    [self.view addGestureRecognizer:_pinch];
    
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    _pan.delegate = self;
    [_pan setMinimumNumberOfTouches:1];
    [_pan setMaximumNumberOfTouches:2];
    
    _panDrawer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDrawer:)];
    [_panDrawer setMinimumNumberOfTouches:1];
    [_panDrawer setMaximumNumberOfTouches:1];
    [_drawerView addGestureRecognizer:_panDrawer];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPressure = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(toggleImage:)];
    [longPressure setMinimumPressDuration:0.5];
    [self.view addGestureRecognizer:longPressure];
}

- (void)doubleTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:_lattice];
    movingPiece = nil;
    
    for (int i = 0; i < 9 * _NumberSquare; i++) {
        CGRect rect = _lattice.pieces[i].frame;
        if ([self point:point isInFrame:rect]) {
            movingPiece = [self pieceWithPosition:i];
        }
    }
    
    if (movingPiece) {
        [movingPiece rotateTap:gesture];
    } else {
        [self resetLatticePositionAndSizeWithDuration:0.5];
    }
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:_lattice];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        movingPiece = nil;
        for (int i = 0; i < 9 * _NumberSquare; i++) {
            CGRect rect = _lattice.pieces[i].frame;
            if ([self point:point isInFrame:rect]) {
                DLog(@"Position %d ", i);
                movingPiece = [self pieceWithPosition:i];
            }
        }
    }
    
    if (movingPiece && !panningMode) {
        [movingPiece move:gesture];
        return;
    }
    
    if (_menu.view.alpha == 0) {
        CGPoint traslation = [gesture translationInView:_lattice.superview];
        _lattice.transform = CGAffineTransformTranslate(_lattice.transform, traslation.x/_lattice.scale, traslation.y/_lattice.scale);
        [self refreshPositions];
        [gesture setTranslation:CGPointZero inView:_lattice.superview];
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    if (CGRectContainsPoint(_drawerView.frame, [gesture locationInView:self.view])) {
        return;
    }
    
    float z = [gesture scale];
    
    CGPoint point = CGPointMake([gesture locationInView:_lattice].x, [gesture locationInView:_lattice].y);
    [self setAnchorPoint:point forView:_lattice];
    
    [self resizeLatticeToScale:_lattice.scale*z];
    
    [gesture setScale:1];
}

- (void)resizeLatticeToScale:(float)newScale {

    float z = newScale/_lattice.scale;
        
    if (_lattice.scale*z*3*_pieceNumber*(_piceSize-2*_padding)>UIScreen.screenWidth && _lattice.scale*z*_piceSize<UIScreen.screenWidth) {
    
        _lattice.scale = newScale;

        _lattice.transform = CGAffineTransformScale(_lattice.transform, z, z);
        
        for (GroupView *g in _groups) {
            
            g.transform = CGAffineTransformScale(g.transform, z, z);
        }
        
        [self refreshPositions];        
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return (gestureRecognizer == _pan && otherGestureRecognizer == _pinch) ||
            (gestureRecognizer == _pinch && otherGestureRecognizer == _pan);
}



#pragma mark -
#pragma mark Groups

- (void)groupMoved:(GroupView *)group {
    
    CGRect frame;
    
    for (NSInteger i = 9 * _NumberSquare - 1; i > -1; i--) {
        
        frame = [self frameOfLatticePiece:i];
        if ([self group:group isInFrame:frame]) {
            
            [self moveGroup:group toLatticePoint:i animated:YES];
            
            return;
        }
    }

    [self moveGroup:group toLatticePoint:group.boss.position animated:YES];

}

- (UIView *)upperGroupBut:(GroupView *)group {
    
    for (NSInteger i =[self.view.subviews count] - 1; i > -1; i--) {
        
        GroupView *g = [self.view.subviews objectAtIndex:i];
        if ([g isKindOfClass:[GroupView class]] && g!=group) {
            return g;
        }
    }
    
    return _lattice;
}

- (void)createNewGroupForPiece:(PieceView*)piece {
    
    if ([self isTheFuckingPiecePositioned:piece] && !_loadingGame) {
        return;
    }
        
    GroupView *newGroup = nil;
    
    //Checks if a group already exists in the neighborhood
    for (PieceView *p in [piece allTheNeighborsBut:nil]) {
        if (p.group!=nil && p!=piece) {
            newGroup = p.group;
            break;
        }
    }
    
    if (!newGroup) {
        
        float w = 0.5 * [[UIScreen mainScreen] bounds].size.height;
        
        newGroup = [[GroupView alloc] initWithFrame:CGRectMake(0, 0, w, w)];
        newGroup.boss = piece;
        newGroup.transform = _lattice.transform;
        newGroup.delegate = self;
        newGroup.isPositioned = (piece.isPositioned && _loadingGame);

        
        piece.isBoss = YES;
        piece.transform = CGAffineTransformScale(piece.transform, 1/_lattice.scale, 1/_lattice.scale);
        [self addPiece:piece toGroup:newGroup];
        
        for (PieceView *p in [piece allTheNeighborsBut:nil]) {
            p.isBoss = NO;
            [self addPiece:p toGroup:newGroup];
        }
        
        [_groups addObject:newGroup];
        [self.view insertSubview:newGroup aboveSubview:[self upperGroupBut:newGroup]];
        
        if ([self isTheFuckingPiecePositioned:piece]) {
            newGroup.isPositioned = YES;
        }
        
        DLog(@"New group created, isPositioned = %d. Groups count %d", newGroup.isPositioned, [groups count]);
        
    } else {

        piece.isBoss = NO;

        if (piece.group!=newGroup) {
            
            [self addPiece:piece toGroup:newGroup];
            DLog(@"Piece #%d added to existing group", piece.number);

        }        
    }
    
    [self moveGroup:newGroup toLatticePoint:newGroup.boss.position animated:NO];
    
}

- (void)addPiece:(PieceView*)piece toGroup:(GroupView*)group {
        
    if ([self isTheFuckingPiecePositioned:piece] && !_loadingGame) {
        return;
    }
    
    if (piece.group == group) {
        return;
    } else {
        piece.group = group;
    }

    DLog(@"%s", __PRETTY_FUNCTION__);

    piece.isBoss = NO;
    [piece removeFromSuperview];
    [group.pieces addObject:piece];
    
    [group addSubview:piece];
    
    //Reset piece size
    piece.transform = group.boss.transform;
    
    CGPoint relative = [self coordinatesOfPiece:piece relativeToPiece:group.boss];
    
    CGAffineTransform matrix = CGAffineTransformMakeRotation(group.boss.angle-group.angle);
    relative = [self applyMatrix:matrix toVector:relative];
    
    float w = [[_lattice objectAtIndex:0] bounds].size.width+4;
    
    CGPoint trans = CGPointMake(relative.y*w, relative.x*w);
    
    piece.center = CGPointMake(group.boss.center.x+trans.x, group.boss.center.y+trans.y);
}

- (void)moveGroup:(GroupView *)group toLatticePoint:(NSInteger)i animated:(BOOL)animated {
    
    PieceView *piece = group.boss;
    piece.position = i;

    CGPoint centerLattice = [self centerOfLatticePiece:i];
    CGPoint centerGroup = group.center;
    CGPoint centerPiece = piece.center;
            centerPiece = [self.view convertPoint:centerPiece fromView:group];
    CGPoint difference = CGPointMake(-centerPiece.x+centerGroup.x, -centerPiece.y+centerGroup.y);
    
    CGPoint newCenter = CGPointMake((centerLattice.x+difference.x), (centerLattice.y+difference.y));
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            group.center = newCenter;
        } completion:^(BOOL finished) {
            [self updatePositionsInGroup:group withReferencePiece:group.boss];
            [self checkNeighborsForGroup:group];
            [self updatePercentage];
            [self updateGroupDB:group];
        }];
    } else {
        group.center = newCenter;
    }
}

- (BOOL)group:(GroupView *)group isInFrame:(CGRect)frame {
    
    PieceView *piece = group.boss;
    CGPoint center = [group.superview convertPoint:piece.center fromView:group];
    return frame.origin.x < center.x && frame.origin.y < center.y;
}

- (void)updatePositionsInGroup:(GroupView*)group withReferencePiece:(PieceView*)boss {
    
    
    for (PieceView *p in group.pieces) {
        
        if (p != boss) {
            CGPoint relativePosition = [self coordinatesOfPiece:p relativeToPiece:boss];
            CGAffineTransform matrix = CGAffineTransformMakeRotation(boss.angle);
            relativePosition = [self applyMatrix:matrix toVector:relativePosition];

            p.position = boss.position + relativePosition.x + 3*_pieceNumber*relativePosition.y;
        }
    }
    
    
    if ([self isPositioned:group.boss]) {
        
        for (PieceView *p in _pieces) {
            
            if (p.group == group) {
                
                [self isPositioned:p];   
            }
        }
        group.userInteractionEnabled = NO;
    }
}

- (void)updateGroupDB:(GroupView*)group{
        
    for (PieceView *piece in group.pieces) {
        
        //Update piece in the DB
        Piece *pieceDB = [self pieceOfCurrentPuzzleDB:piece.number];
        pieceDB.position = @(piece.position);
        pieceDB.angle = @(piece.angle);
    }

    [self saveGame];
    
}

- (void)checkNeighborsForAllThePieces {
    
    for (PieceView *p in _pieces) {
        if (p.isFree) {
            [self checkNeighborsOfPiece:p];
            if (p.hasNeighbors) {
                [self createNewGroupForPiece:p];
            }
        }
    }    
    

}

- (void)checkNeighborsForGroup:(GroupView*)group {
    
    DLog(@"Starting %s", __FUNCTION__);

    for (int i = 0; i < group.pieces.count; i++) {
        
        PieceView *p = [group.pieces objectAtIndex:i];
        
        if (!p.isCompleted) {
            [self checkNeighborsOfPiece:p];
        }
    }
}



#pragma mark -
#pragma mark Pieces

- (void)pieceMoved:(PieceView *)piece {
    
    CGPoint point = piece.center;   
    
    if (!piece.hasNeighbors) {
        
        BOOL outOfDrawer;
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            outOfDrawer = point.y<UIScreen.screenHeight-drawerSize;
        } else {
            outOfDrawer = point.x>drawerSize-self.padding;
        }
        
        point = [_drawerView convertPoint:point fromView:self.view];
        
        
        if (![_drawerView pointInside:point withEvent:nil]) {
            if (!piece.isFree && ![self pieceIsOut:piece]) {
                piece.isFree = YES;
            }
        } else {
            piece.isFree = NO;
            piece.position = -1;
            [self updatePieceDB:piece];
            [UIView animateWithDuration:0.5 animations:^{
                float scale = _piceSize/piece.frame.size.width;
                piece.transform = CGAffineTransformScale(piece.transform, scale, scale);
            }];
        }
    } else {
        piece.isFree = YES;
    }
    
    if (piece.isFree) {
        piece.moves++;
        _moves++;
    }
    
    if (piece.isFree) {
        
        if ([self pieceIsOut:piece]) {
            [UIView animateWithDuration:0.5 animations:^{
                
                for (PieceView *p in [piece allTheNeighborsBut:nil]) {
                    CGRect rect = p.frame;
                    rect.origin.x = p.oldPosition.x-p.frame.size.width/2;
                    rect.origin.y = p.oldPosition.y-p.frame.size.height/2;
                    p.frame = rect;
                    p.position = [self positionOfPiece:p];
                }
                CGRect rect = piece.frame;
                rect.origin.x = piece.oldPosition.x-piece.frame.size.width/2;
                rect.origin.y = piece.oldPosition.y-piece.frame.size.height/2;
                piece.frame = rect;                
                piece.position = [self positionOfPiece:piece];
            }];
            
        } else {
            
            for (NSInteger i = 9 * _NumberSquare - 1; i > -1; i--) {
                CGRect frame = [self frameOfLatticePiece:i];
                if ([self piece:piece isInFrame:frame]) {
                    [self movePiece:piece toLatticePoint:i animated:YES];
                    break;
                }
            }
        }
    }
    
    piece.isLifted = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        [self organizeDrawerWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }];

    piece.oldPosition = [piece realCenter];
    
    if (panningMode && piece.isFree) {
        piece.userInteractionEnabled = NO;
    }
}

- (NSInteger)positionOfPiece:(PieceView *)piece {
    for (NSInteger i = 9 * _NumberSquare - 1; i > -1; i--) {
        
        CGRect frame = [self frameOfLatticePiece:i];
        
        if ([self piece:piece isInFrame:frame]) {
            return i;
        }
    }
    return -1;
}

- (void)pieceRotated:(PieceView *)piece {
    
    if (piece.isFree) {
        piece.rotations++;
        _rotations++;
    }
    
    if (!piece.group) {
        for (PieceView *p in [piece allTheNeighborsBut:nil]) {
            p.oldPosition = [p realCenter];
            p.position = [self positionOfPiece:p];
        }
        piece.oldPosition = [piece realCenter];
        piece.position = [self positionOfPiece:piece];

        [self isPositioned:piece];

    } else { //In a group
        
        for (PieceView *p in piece.group.pieces) {
            
            p.angle = piece.angle;
        }

        [self updatePositionsInGroup:piece.group withReferencePiece:piece];
    }
    
    if (piece.group) {
        
        [self checkNeighborsForGroup:piece.group];
        
    } else {
        
        [self checkNeighborsOfPiece:piece];
        if (piece.hasNeighbors) {
            [self createNewGroupForPiece:piece];
        }
    }
    
    [self updatePieceDB:piece];
    [self updatePercentage];
    
    
}

- (PieceView *)pieceAtPosition:(NSInteger)j {
    
    for (PieceView *p in _pieces) {
        
        if (p.position == j) {
            return p;
        }
    }
    
    return nil;
}

- (BOOL)shouldCheckNeighborsOfPiece:(PieceView *)piece inDirection:(NSInteger)r {
    
    if (piece.position != 0) {
        return YES;
/*
        if (r==2 && (piece.position+1)%_pieceNumber==0) {
            DLog(@"bottom piece (#%d) checking down", piece.number);
            return NO;
        }
        if (r==0 && (piece.position)%_pieceNumber==0) {
            DLog(@"top piece (#%d) checking up", piece.number);
            return NO;
        }
        if (r==3 && (piece.position)/_pieceNumber==_pieceNumber-1) {
            DLog(@"right piece (#%d) checking right", piece.number);
            return NO;
        }
        if (r==1 && (piece.position)/_pieceNumber==0) {
            DLog(@"left piece (#%d) checking left", piece.number);
            return NO;
        }
        
        return YES;
 */
    } else {
        return (r == 1 || r == 2);
    }
    
}

- (int)rotationFormAngle:(float)angle {
    int rotation = 3;
    
    if (angle < 1) {
        rotation = 0;
    } else if (angle < 3) {
        rotation = 1;
    } else if (angle < 4) {
        rotation = 2;
    }
    
    return rotation;
}

- (void)checkNeighborsOfPiece:(PieceView*)piece {
    
    int rotation = [self rotationFormAngle:piece.angle];    
    
    PieceView *otherPiece;
    NSInteger j = piece.position;
    
    if (j == -1) {
        return;
    }
    
    for (NSInteger direction = 0; direction < 4; direction++) {
        
        NSInteger r = direction + rotation % 4;
        if (r >= directions_positions.count) {
            return;
        }
        NSInteger i = [directions_positions[r] integerValue];
        NSInteger l = [directions_numbers[direction] integerValue];
        
        // Looks for neighbors
        if (j + i >= 0 && j + i < 9 * _NumberSquare &&
            [self shouldCheckNeighborsOfPiece:piece inDirection:r]) {
            
            otherPiece = [self pieceAtPosition:j + i];
            
            DLog(@"j+i = %d ; numbers are %d and %d for pieces #%d, and #%d. Direction = %d, rotation = %d, r = %d",j+i, piece.number+l, otherPiece.number,  piece.number, otherPiece.number, direction, rotation, r);    
            
            DLog(@"Checking position %d, number+l = %d, otherPiece.number = %d", piece.number+i, piece.number+l, otherPiece.number);
            
            if (otherPiece != nil) {
                
                if (otherPiece.isFree) {
                    
                    DLog(@"Angles are %.1f (piece) and %.1f (other)\n\n", piece.angle, otherPiece.angle);
                    
                    
                    if (piece.number+l==otherPiece.number) {
                        
                        
                        if ((ABS(piece.angle-otherPiece.angle)<M_PI/4)) {
                            
                            if ([[piece.neighbors objectAtIndex:direction%4] integerValue] != otherPiece.number) {
                                
                                [otherPiece setNeighborNumber:piece.number forEdge:(direction+2)%4];
                                [piece setNeighborNumber:otherPiece.number forEdge:direction%4];
                                
                                piece.hasNeighbors = YES;
                                otherPiece.hasNeighbors = YES;
                                
                                if (!_loadingGame &&
                                    !(Is_Device_Playing_Music) &&
                                    ![self isTheFuckingPiecePositioned:piece]) {
                                }
                                
                                if ((![self isTheFuckingPiecePositioned:piece] || ![self isTheFuckingPiecePositioned:otherPiece]) && !_loadingGame) {
                                                                        
                                    if (otherPiece.group!=nil && !otherPiece.group.isPositioned) {
                                        
                                        if (piece.group!=nil) {
                                            for (PieceView *p in piece.group.pieces) {
                                                [self addPiece:p toGroup:otherPiece.group];
                                            }
                                        } else {
                                            [self addPiece:piece toGroup:otherPiece.group];
                                        }
                                        
                                    } else if (piece.group!=nil && !piece.group.isPositioned) {
                                        
                                        if (otherPiece.group!=nil) {
                                            for (PieceView *p in otherPiece.group.pieces) {
                                                [self addPiece:p toGroup:piece.group];
                                            }
                                        } else {
                                            [self addPiece:otherPiece toGroup:piece.group];
                                        }
                                        
                                    }
                                }
                            }
                            
                        } else {
                            //DLog(@"0 -------> Wrong angles. They are %.1f and %.1f for pieces #%d and #%d", piece.angle, otherPiece.angle, piece.number, otherPiece.number);
                        }
                    } else {
                        //DLog(@"-------> Wrong numbers. They are %d and %d for pieces #%d, and #%d. Direction = %d, rotation = %d, r = %d", piece.number+l, otherPiece.number, piece.number, otherPiece.number, direction, rotation, r);
                        
                    }
                }
                
            }else {
                
                //DLog(@"NIL");
                
            }
            
        } else {
            //DLog(@"Shouldn't check");
        }
        
    }
    
    //DLog(@"\n");
    
}

- (BOOL)isTheFuckingPiecePositioned:(PieceView  *)piece {
    return (firstPiecePlace + 3 * _pieceNumber * (piece.number / _pieceNumber) + (piece.number % _pieceNumber) == piece.position);
}

- (BOOL)isPositioned:(PieceView*)piece  {
    if (piece.isFree && ([self isTheFuckingPiecePositioned:piece]) && ABS(piece.angle) < 1) {
        // Flashes and block the piece
        if (!piece.isPositioned) {
            if (!_loadingGame) {
                [self addPoints:[self pointsForPiece:piece]];
            }
            
            piece.isPositioned = YES;
            piece.userInteractionEnabled = NO;
            if (!piece.group) {
                [piece removeFromSuperview];
                [self.view insertSubview:piece aboveSubview:_lattice];
            }
            [piece pulse];
            [self isPuzzleComplete];
        }
        return YES;
    }
    return NO;
}

- (void)movePiece:(PieceView*)piece toLatticePoint:(NSInteger)i animated:(BOOL)animated {
    piece.position = i;
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            piece.center = [self centerOfLatticePiece:i];
            CGAffineTransform trans = CGAffineTransformMakeScale(_lattice.scale, _lattice.scale);
            piece.transform = CGAffineTransformRotate(trans, piece.angle);
        } completion:^(BOOL finished) {
            [self checkNeighborsOfPiece:piece];
            if (piece.hasNeighbors) {
                [self createNewGroupForPiece:piece];
            }
            
            if (!piece.isPositioned) {
                [self isPositioned:piece];
            }
            [self updatePercentage];
            [self updatePieceDB:piece];
        }];
    } else {
        piece.center = [self centerOfLatticePiece:i];
        CGAffineTransform trans = CGAffineTransformMakeScale(_lattice.scale, _lattice.scale);
        piece.transform = CGAffineTransformRotate(trans, piece.angle);
    }
    piece.oldPosition = [piece realCenter];
}

- (BOOL)piece:(PieceView*)piece isInFrame:(CGRect)frame {
    
    return frame.origin.x<[piece realCenter].x && frame.origin.y<[piece realCenter].y;
}

- (BOOL)point:(CGPoint)point isInFrame:(CGRect)frame {
    return (frame.origin.x < point.x &&
            frame.origin.y < point.y &&
            frame.origin.x + frame.size.width > point.x &&
            frame.origin.y + frame.size.height > point.y);
}

- (void)updatePieceDB:(PieceView*)piece {
    Piece *pieceDB = [self pieceOfCurrentPuzzleDB:piece.number];
    pieceDB.position = @(piece.position);
    pieceDB.angle = @(piece.angle);
    pieceDB.moves = @(piece.rotations);
    pieceDB.rotations = @(piece.moves);
    [pieceDB setisFreeScalar:piece.isFree];
    
    pieceDB.edge0 = piece.edges[0];
    pieceDB.edge1 = piece.edges[1];
    pieceDB.edge2 = piece.edges[2];
    pieceDB.edge3 = piece.edges[3];
    
    [self saveGame];
}

- (CGPoint)coordinatesOfPiece:(PieceView*)piece relativeToPiece:(PieceView *)boss {
    return CGPointMake((piece.number % _pieceNumber - boss.number % _pieceNumber) % _pieceNumber,
                       piece.number / _pieceNumber - boss.number / _pieceNumber);
}

- (Piece *)pieceOfCurrentPuzzleDB:(NSInteger)n {
    for (Piece *p in _puzzleDB.pieces) {
        if (p.number.intValue == n) {
            return p;
        }
    }
    
    _missedPieces++;
    return nil;
}

- (void)resetSizeOfAllThePieces {
    CGRect rect;
    for (PieceView *p in _pieces) {
        rect = p.frame;
        rect.size.width = _piceSize;
        rect.size.height = _piceSize;
        p.frame = rect;
    }
}

- (void)setPieceNumber:(NSInteger)pieceNumber {
    _pieceNumber = pieceNumber;
    _NumberSquare = _pieceNumber * _pieceNumber;
    
}

- (PieceView *)pieceWithNumber:(NSInteger)j {
    for (PieceView *p in _pieces) {
        if (p.number == j) {
            return p;
        }
    }
    return nil;
}

- (PieceView *)pieceWithPosition:(NSInteger)j {
    for (PieceView *p in _pieces) {
        if (p.position == j && p.userInteractionEnabled) {
            return p;
        }
    }
    return nil;
}

- (BOOL)pieceIsOut:(PieceView *)piece {
    CGRect frame1 = [self frameOfLatticePiece:0];
    CGRect frame2 = [self frameOfLatticePiece:9 * _NumberSquare - 1];
    
    if ([piece realCenter].x > frame2.origin.x + frame2.size.width ||
        [piece realCenter].y > frame2.origin.y + frame2.size.width ||
        [piece realCenter].x < frame1.origin.x ||
        [piece realCenter].y < frame1.origin.y) {
        return YES;
    }
    
    for (PieceView *p in [piece allTheNeighborsBut:nil]) {
        if ([p realCenter].x > frame2.origin.x + frame2.size.width ||
            [p realCenter].y > frame2.origin.y + frame2.size.width ||
            [p realCenter].x < frame1.origin.x ||
            [p realCenter].y < frame1.origin.y) {
            return YES;
        }
    }
    
    return NO;
}

- (UIView *)upperPositionedThing {
    NSInteger N = self.view.subviews.count;
    for (NSInteger i = 0; i < N; i++) {
        UIView *v = self.view.subviews[N - i - 1];
        if ([v isKindOfClass:GroupView.self]) {
            return v;
        }
        if ([v isKindOfClass:PieceView.self]) {
            if (!v.userInteractionEnabled) {
                return v;
            }
        }
    }
    
    return _lattice;
}

#pragma mark - Lattice
- (void)createLattice {
    
    [_lattice removeFromSuperview];
    
    float w = (_piceSize - 2 * self.padding) * _pieceNumber;
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    
    // Center the lattice
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        rect = CGRectMake((rect.size.height - w) / 2 + drawerSize / 2, (rect.size.width - w) / 2, w, w);
    } else {
        rect = CGRectMake((rect.size.width - w) / 2, (rect.size.height - w) / 2 + drawerSize / 2, w, w);
    }
    
    _lattice = [[Lattice alloc] init];
    [_lattice initWithFrame:rect withNumber:_pieceNumber withDelegate:self];
    _lattice.frame = [self frameForLatticeWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
    
    _lattice.scale = 1;
    
    [self.view addSubview:_lattice];
    
    [self.view bringSubviewToFront:_menuButtonView];
    [self.view bringSubviewToFront:_drawerView];
    [self.view bringSubviewToFront:_menu.obscuringView];
    [self.view bringSubviewToFront:_menu.view];
    
    // Add the image to lattice
    _imageViewLattice.image = _image;
    _imageViewLattice.contentMode = UIViewContentModeScaleAspectFill;
    _imageViewLattice.frame = CGRectMake(0 ,0, _pieceNumber * _lattice.scale * (_piceSize - 2 * self.padding), _pieceNumber * _lattice.scale * (_piceSize - 2 * self.padding));
    _imageViewLattice.alpha = 0;
    [_lattice addSubview:_imageViewLattice];
}

- (void)resetLatticePositionAndSizeWithDuration:(float)duration {
    float f = UIScreen.screenWidth / (_pieceNumber + 1) / (_piceSize - 2 * _padding);
    [UIView animateWithDuration:duration animations:^{
        [self resizeLatticeToScale:f];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration animations:^{
            CGPoint center = [self.view convertPoint:[[_lattice objectAtIndex:firstPiecePlace] center] fromView:_lattice];
            int topBar = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) * 20;
            
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                
                _lattice.transform = CGAffineTransformTranslate(_lattice.transform,
                -center.x/_lattice.scale+(_piceSize-2*_padding)+(drawerSize)/_lattice.scale,
                -center.y/_lattice.scale + _piceSize-2 * _padding + 10);
            } else {
                
                _lattice.transform = CGAffineTransformTranslate(_lattice.transform,
                -center.x / _lattice.scale + _piceSize - 2 * _padding,
                -center.y / _lattice.scale + _piceSize - 2 * _padding + HUDView.height / _lattice.scale - topBar);
            }
            [self refreshPositions];
        }];
    }];
    
}

- (void)moveLatticeToLeftWithDuration:(float)duration {
    CGPoint center = [self.view convertPoint:[[_lattice objectAtIndex:firstPiecePlace] center] fromView:_lattice];
    int topBar = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) * 20;
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _lattice.transform = CGAffineTransformTranslate(_lattice.transform,
                                                       -center.x/_lattice.scale+(_piceSize-2*_padding)/2+30,
                                                       -center.y/_lattice.scale+(_piceSize-2*_padding)-topBar);
    } else {
        _lattice.transform = CGAffineTransformTranslate(_lattice.transform,
                    -center.x / _lattice.scale + (_piceSize - 2 * _padding),
                    -center.y / _lattice.scale + (_piceSize - 2 * _padding) / 2 + _puzzleComplete.bounds.size.height / _lattice.scale+topBar);
    }
    
    [self refreshPositions];
    
    [UIView animateWithDuration:duration animations:^{
        
        for (GroupView *g in _groups) {
            g.alpha = 1;
        }
        
        for (PieceView *p in _pieces) {
            if (!p.group) {
                p.alpha = 1;
            }
        }
    }];    
}

- (CGRect)frameOfLatticePiece:(NSInteger)i {
    
    UIView *v = [_lattice objectAtIndex:i];
    return CGRectMake(_lattice.left + _lattice.scale * (v.left - self.padding) - 2.0 * _lattice.scale,
                      _lattice.top + _lattice.scale * (v.top - self.padding) - 2.0 * _lattice.scale,
                      _lattice.scale * _piceSize,
                      _lattice.scale * _piceSize
                      );
    
}

- (CGPoint)centerOfLatticePiece:(NSInteger)i {
    CGRect rect = [self frameOfLatticePiece:i];
    return CGPointMake(rect.origin.x+_lattice.scale*_piceSize/2.0, rect.origin.y+_lattice.scale*_piceSize/2.0);
}



#pragma mark -
#pragma mark Drawer

- (void)organizeDrawerWithOrientation:(UIInterfaceOrientation)orientation {
    
    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:_pieces];
    
    if (temp.count == 0) {
        return;
    }
    
    // Removes removed pieces
    for (int i = 0; i < _pieces.count; i++) {
        
        PieceView *p = [_pieces objectAtIndex:i];
        if (p.isFree || p.isLifted) {
            [temp removeObject:p];
        }
    }
    
    if (drawerFirstPoint.x == 0 && drawerFirstPoint.y == 0) {
        PieceView *p = temp.firstObject;
        drawerFirstPoint.x = p.left + p.height / 2;
        drawerFirstPoint.y = p.top + p.height / 2;
    }
    
    for (int i = 0; i < temp.count; i++) {
        
        PieceView *p = temp[i];
        
        CGPoint point = p.center;
        PieceView *p2;
        
        if (i > 0) {
            p2 = [temp objectAtIndex:i-1];
            CGPoint point2 = p2.center;
            
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                point.y = point2.y + p2.width + drawerMargin;
                point.x = _drawerView.center.x;
            } else {
                point.x = point2.x + p2.width + drawerMargin;
                point.y = UIScreen.screenHeight - drawerSize + self.padding * 0.75 / 2 + p.height / 2;
            }
            
        } else {
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                point.y = drawerFirstPoint.y + p.height / 2 + drawerMargin;
                point.x = _drawerView.centerX;
            } else {
                point.x = drawerFirstPoint.x + p.width / 2 + drawerMargin;
                point.y = UIScreen.screenHeight - drawerSize + self.padding * 0.75 / 2 + p.height / 2;
            }
        }
        
        p.center = point;
    }
}

- (BOOL)drawerStoppedShouldBeStopped {
    
    if ([self numberOfPiecesInDrawerAtTheMoment]<=numberOfPiecesInDrawer) {
        
        if (!_drawerStopped) {
            _drawerStopped = YES;
            drawerFirstPoint = CGPointMake(-4, 5);
            [UIView animateWithDuration:0.5 animations:^{
                [self organizeDrawerWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
            }];
        }
        return YES;
    }
    return NO;
}

- (void)panDrawer:(UIPanGestureRecognizer *)gesture {
    
    if (_menu.view.alpha == 0) {

        if ([self drawerStoppedShouldBeStopped]) return;
        
        _drawerStopped = NO;
   
        CGPoint traslation = [gesture translationInView:_lattice.superview];
        CGFloat panningSpeed = 0.07;
        CGFloat velocityLimit = 1000.0;
        CGFloat panDrawerAccurancy = 0.01;
        
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) { //Landscape
            
            float velocity = [gesture velocityInView:self.view].y;
            
            if (velocity < 0) {
                
                if (velocity < -velocityLimit) velocity = -velocityLimit;
            
                if ([self lastPieceInDrawer].frame.origin.y<UIScreen.screenWidth-_piceSize) {

                    [self moveNegativePieces];
                }

            } else {
                
                if (velocity>velocityLimit) velocity = velocityLimit;

                if ([self firstPieceInDrawer].frame.origin.y>0) {

                    [self movePositivePieces];
                }

            }

            if (ABS(traslation.x > panDrawerAccurancy) || ABS(traslation.y) > panDrawerAccurancy) {
                
                for (PieceView *p in _pieces) {
                    if (!p.isFree) {
                        
                        CGPoint point = p.center;
                        point.y += velocity*panningSpeed;
                        p.center = point;
                    }
                }                
                drawerFirstPoint.y += velocity*panningSpeed;
                [gesture setTranslation:CGPointMake(traslation.x, 0) inView:_lattice.superview];
            }
            
            
        } else {    //Portrait
            
            float velocity = [gesture velocityInView:self.view].x;
            
            if (velocity<0) {
                
                if (velocity < -velocityLimit) velocity = -velocityLimit;
                
                if ([self lastPieceInDrawer].frame.origin.x<UIScreen.screenWidth-_piceSize) {
                    
                    [self moveNegativePieces];
                }
                
            } else {

                if (velocity>velocityLimit) velocity = velocityLimit;

                if ([self firstPieceInDrawer].frame.origin.x>0) {
                    
                    [self movePositivePieces];
                }
                
            }
            
            if (ABS(traslation.x > panDrawerAccurancy) || ABS(traslation.y) > panDrawerAccurancy) {
                
                for (PieceView *p in _pieces) {
                    if (!p.isFree) {
                        
                        CGPoint point = p.center;
                        point.x += velocity*panningSpeed;
                        p.center = point;
                    }
                }    
                drawerFirstPoint.x += velocity*panningSpeed;
                [gesture setTranslation:CGPointMake(0, traslation.y) inView:_lattice.superview];
            }
        }
        
        PieceView *first = [self firstPieceInDrawer];
        drawerFirstPoint = first.center;
        firstPointView.center = drawerFirstPoint;
    }
    
}

- (int)numberOfPiecesInDrawerAtTheMoment {
    int i = 0;
    for (PieceView *p in _pieces) {
        if (!p.isFree) {
            i++;
        }
    }
    return i;
}

- (PieceView *)firstPieceInDrawer {
    for (int i = 0; i < _pieces.count; i++) {
        PieceView *p = _pieces[i];
        if (!p.isFree) {
            return p;
        }
    }
    return nil;
}

- (PieceView *)lastPieceInDrawer {
    
    for (NSInteger i = _pieces.count - 1; i > -1; i--) {
        PieceView *p = _pieces[i];
        if (!p.isFree) {
            return p;
        }
    }
    return nil;
    
}

- (CGRect)frameUnderPiece:(PieceView*)piece {
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGRectMake(_drawerView.frame.origin.x + drawerMargin,
                          piece.frame.origin.y + _piceSize + drawerMargin,
                          piece.frame.size.width, 
                          piece.frame.size.height);
    } else {
        return CGRectMake(piece.frame.origin.x + _piceSize+drawerMargin,
                          _drawerView.frame.origin.y + drawerMargin,
                          piece.frame.size.width, 
                          piece.frame.size.height);
    }    
}

- (CGRect)frameOverPiece:(PieceView*)piece {
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        
        return CGRectMake(_drawerView.frame.origin.x+drawerMargin,
                          piece.frame.origin.y-_piceSize-drawerMargin,
                          piece.frame.size.width, 
                          piece.frame.size.height);
    } else {
        
        return CGRectMake(piece.frame.origin.x-_piceSize-drawerMargin,
                          _drawerView.frame.origin.y+drawerMargin,
                          piece.frame.size.width, 
                          piece.frame.size.height);
    }
}

- (void)moveNegativePieces {
    PieceView *swap = [self firstPieceInDrawer];
    [_pieces removeObject:swap];
    swap.frame = [self frameUnderPiece:[self lastPieceInDrawer]];
    [_pieces addObject:swap];
    
    return;
    
}

- (void)movePositivePieces {
    
    if ([self numberOfPiecesInDrawerAtTheMoment] < numberOfPiecesInDrawer) {
        return;
    }
        
    PieceView *swap = [self lastPieceInDrawer];
    [_pieces removeObject:swap];
    swap.frame = [self frameOverPiece:[self firstPieceInDrawer]];
    [_pieces insertObject:swap atIndex:0];
    
    return;
    
}

- (IBAction)scrollDrawerRight:(id)sender {
    [self swipeInDirection:UISwipeGestureRecognizerDirectionRight];
}

- (IBAction)scrollDrawerLeft:(id)sender {
    [self swipeInDirection:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeInDirection:(UISwipeGestureRecognizerDirection)direction {
    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:_pieces];
    for (PieceView *p in _pieces) {
        if (p.isFree) {
            [temp removeObject:p];
        }
    }
    
    int sgn = 1;
    if (direction==UISwipeGestureRecognizerDirectionLeft) {
        sgn *= -1;
    }
    
    float traslation = UIScreen.screenWidth-drawerMargin;
    
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        
        if (direction==UISwipeGestureRecognizerDirectionRight && drawerFirstPoint.y>=-_piceSize) {
            return;
        }
        
        PieceView *p = [temp lastObject];
        if (
            direction==UISwipeGestureRecognizerDirectionLeft && 
            p.frame.origin.y<UIScreen.screenWidth-p.frame.size.height+self.padding
            ) {
            return;
        }
        
        if (!swiping) {
            
            [UIView animateWithDuration:0.5 animations:^{
                
                swiping = YES;
                
                drawerFirstPoint.y += sgn*(traslation);
                
                [UIView animateWithDuration:0.5 animations:^{
                    [self organizeDrawerWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
                }];                //DLog(@"first point = %.1f", drawerFirstPoint.x);
                
                
            }completion:^(BOOL finished){
                
                swiping = NO;
                
            }];
            
        }
        
    } else {
        
        if (direction == UISwipeGestureRecognizerDirectionRight &&
            drawerFirstPoint.x >= -_piceSize) {
            return;
        }
        
        PieceView *p = [temp lastObject];
        if (direction == UISwipeGestureRecognizerDirectionLeft &&
            p.frame.origin.x < UIScreen.screenWidth - p.frame.size.width + self.padding) {
            return;
        }
        
        if (!swiping) {
            [UIView animateWithDuration:0.5 animations:^{
                swiping = YES;
                drawerFirstPoint.x += sgn*traslation;
                [UIView animateWithDuration:0.5 animations:^{
                    [self organizeDrawerWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
                }];
            } completion:^(BOOL finished){
                swiping = NO;
            }];
        }
    }
    
}

- (void)swipeR:(UISwipeGestureRecognizer *)swipe {
    if (_menu.view.alpha == 0) {
        [self swipeInDirection:UISwipeGestureRecognizerDirectionRight];
    }
}

- (void)swipeL:(UISwipeGestureRecognizer*)swipe {
    if (_menu.view.alpha == 0) {
        [self swipeInDirection:UISwipeGestureRecognizerDirectionLeft];
    }
}

- (CGRect)frameForLatticeWithOrientation:(UIInterfaceOrientation)orientation {
    
    float w = (_piceSize - 2 * self.padding) * _pieceNumber;
    
    CGRect latticeRect = [[UIScreen mainScreen] bounds];
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        latticeRect = CGRectMake((latticeRect.size.height - w) / 2 + drawerSize / 2, (latticeRect.size.width - w) / 2, w, w);
    } else {
        latticeRect = CGRectMake((latticeRect.size.width - w) / 2, (latticeRect.size.height - w) / 2 + drawerSize / 2, w, w);
    }
    
    latticeRect.origin.y = latticeRect.size.height / 2;
    
    return latticeRect;
}

#pragma mark - Core Data

- (BOOL)saveGame {
    if (!_puzzleDB) {
        DLog(@"PuzzleDB is nil");
    }
    
    _puzzleDB.moves = @(_moves);
    _puzzleDB.rotations = @(_rotations);
    _puzzleDB.score = @(_score);
    _puzzleDB.lastSaved = [NSDate date];
    _puzzleDB.percentage = @([self completedPercentage]);

    if ([self.managedObjectContext save:nil]) {
        DLog(@"Puzzle saved");
    }
    
    return YES;
}

- (Puzzle *)lastSavedPuzzle {
    NSFetchRequest *fetchRequest1 = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Puzzle"  inManagedObjectContext: self.managedObjectContext];
    
    [fetchRequest1 setEntity:entity];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"lastSaved" ascending:NO];
    [fetchRequest1 setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    dateSort = nil;
    
    [fetchRequest1 setFetchLimit:1];
    
    return [self.managedObjectContext executeFetchRequest:fetchRequest1 error:nil].lastObject;
}

- (void)createPuzzleInDB {
    
    self.view.userInteractionEnabled = NO;
    
    _puzzleDB = [self newPuzzleInContext:self.managedObjectContext];
    Image *imageDB = [self newImageInContext:self.managedObjectContext];
    imageDB.data = UIImageJPEGRepresentation(_image, 1);
    _puzzleDB.image = imageDB;
    _puzzleDB.pieceNumber = @(_pieceNumber);
    
    for (PieceView *piece in _pieces) {
        //Creating the piece in the database
        Piece *pieceDB = [self newPieceInContext:self.managedObjectContext];
        pieceDB.puzzle = _puzzleDB;
        pieceDB.number = @(piece.number);
        pieceDB.position = @(piece.position);
        pieceDB.angle = @(piece.angle);
        Image *imagePieceDB = [self newImageInContext:self.managedObjectContext];
        imagePieceDB.data = UIImageJPEGRepresentation(piece.image, 0.5);
        pieceDB.image = imagePieceDB;
        
        pieceDB.edge0 = piece.edges[0];
        pieceDB.edge1 = piece.edges[1];
        pieceDB.edge2 = piece.edges[2];
        pieceDB.edge3 = piece.edges[3];
    }
    
    self.view.userInteractionEnabled = YES;
}

- (Puzzle *)newPuzzleInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription
            insertNewObjectForEntityForName:@"Puzzle" 
            inManagedObjectContext:context];
}

- (Image *)newImageInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription
            insertNewObjectForEntityForName:@"Image" 
            inManagedObjectContext:context];
}

- (Piece *)newPieceInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription
            insertNewObjectForEntityForName:@"Piece" 
            inManagedObjectContext:context];
}


#pragma mark - Rotation
- (CGRect)rotatedFrame:(CGRect)frame {
    return CGRectMake(frame.origin.y, frame.origin.x, frame.size.width, frame.size.height);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
        
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (IS_iPad) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    }
    
    [_completedController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    //Rotate the drawer
    
    CGRect drawerFrame = _drawerView.frame;
    CGRect HUDFrame = HUDView.frame;
    CGRect stepperFrame = stepperDrawer.frame;
    CGRect imageFrame = _imageView.frame;
    CGRect statsFrame = _completedController.view.frame;    
    CGPoint chooseCenter = CGPointZero;
    CGPoint completedCenter = CGPointZero;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && !UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        
        
        drawerFirstPoint = CGPointMake(5, drawerFirstPoint.x);
        
        drawerFrame.size.width = drawerSize;
        drawerFrame.size.height = UIScreen.screenWidth;
        drawerFrame.origin.x = 0;
        drawerFrame.origin.y = -10;

        stepperFrame.origin.y = drawerFrame.size.height - stepperFrame.size.height-30;
        stepperFrame.origin.x = drawerFrame.size.width;
        float pad = ([[UIScreen mainScreen] bounds].size.height - imageFrame.size.width)/1;
        imageFrame.origin.x = pad;
        imageFrame.origin.y = 0;
        
        chooseCenter = CGPointMake(self.view.center.x+128, self.view.center.y-425);
        _panningSwitch.center = CGPointMake(_panningSwitch.center.x+drawerSize, _panningSwitch.center.y);
        if (IS_iPhone) {
            percentageLabel.center = CGPointMake(percentageLabel.center.x+drawerSize, percentageLabel.center.y);
        }
        
        _lattice.center = CGPointMake(_lattice.center.x+drawerSize, _lattice.center.y);
        
        completedCenter = CGPointMake(self.view.center.y, self.view.center.x);
        
        statsFrame = CGRectMake(UIScreen.screenWidth/2-160+10, UIScreen.screenHeight/2-160, statsFrame.size.width, statsFrame.size.height);

        
    } else if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) &&
               !UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        drawerFirstPoint = CGPointMake(drawerFirstPoint.y, 5);
        
        drawerFrame.size.height = drawerSize;
        drawerFrame.size.width = UIScreen.screenWidth;
        drawerFrame.origin.x = 0;
        drawerFrame.origin.y = UIScreen.screenWidth - drawerSize;
        
        stepperFrame.origin.y = drawerFrame.size.height;
        stepperFrame.origin.x = drawerFrame.size.width - stepperFrame.size.width - 10;
        imageFrame.origin.y = 0;
        imageFrame.origin.x = 0;
        
        chooseCenter = CGPointMake(self.view.center.x - 10, self.view.center.y - 290);
        _panningSwitch.center = CGPointMake(_panningSwitch.center.x - drawerSize, _panningSwitch.center.y);
        if (IS_iPhone) {
            percentageLabel.center = CGPointMake(percentageLabel.center.x - drawerSize, percentageLabel.center.y);
        }
        
        _lattice.center = CGPointMake(_lattice.center.x - drawerSize, _lattice.center.y);
        
        completedCenter = CGPointMake(self.view.center.x, self.view.center.y);
        
        statsFrame = CGRectMake((UIScreen.screenHeight - statsFrame.size.width) / 2, UIScreen.screenWidth - 240 - 20, statsFrame.size.width, statsFrame.size.height);
    }
    
    [self refreshPositions];    
    
    HUDFrame.origin.x = 0;
    HUDFrame.origin.y = 20;
    
    [UIView animateWithDuration:duration animations:^{
        _drawerView.frame = drawerFrame;
        stepperDrawer.frame = stepperFrame;
        _imageView.frame = imageFrame;
        _puzzleComplete.center = completedCenter;
        _completedController.view.frame = statsFrame;
        HUDView.frame = HUDFrame;
    }];
    
    [UIView animateWithDuration:duration animations:^{
        [self organizeDrawerWithOrientation:toInterfaceOrientation];
    }];    
}

- (void)fuckingRotateTo:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    NSLog(@"Will fucking rotate");
    
    //Rotate the drawer
    CGRect drawerFrame = _drawerView.frame;
    CGRect HUDFrame = HUDView.frame;
    CGRect stepperFrame = stepperDrawer.frame;
    CGRect imageFrame = _imageView.frame;
    CGRect statsFrame = _completedController.view.frame;    
    CGPoint chooseCenter = CGPointZero;
    CGPoint completedCenter = CGPointZero;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        drawerFirstPoint = CGPointMake(5, drawerFirstPoint.x);
        
        drawerFrame.size.width = drawerSize;
        drawerFrame.size.height = UIScreen.screenWidth;
        drawerFrame.origin.x = 0;
        drawerFrame.origin.y = -10;

        stepperFrame.origin.y = drawerFrame.size.height - stepperFrame.size.height-30;
        stepperFrame.origin.x = drawerFrame.size.width;
        float pad = ([[UIScreen mainScreen] bounds].size.height - imageFrame.size.width)/1;
        imageFrame.origin.x = pad;
        imageFrame.origin.y = 0;
        
        chooseCenter = CGPointMake(self.view.center.x+128, self.view.center.y-425);
        _panningSwitch.center = CGPointMake(_panningSwitch.center.x+drawerSize, _panningSwitch.center.y);
        if (IS_iPhone) {
            percentageLabel.center = CGPointMake(percentageLabel.center.x+drawerSize, percentageLabel.center.y);
        }
        
        _lattice.center = CGPointMake(_lattice.center.x + drawerSize, _lattice.center.y);
        
        completedCenter = CGPointMake(self.view.center.y, self.view.center.x);
        
        statsFrame = CGRectMake(UIScreen.screenWidth/2-160+10, UIScreen.screenHeight/2-160, statsFrame.size.width, statsFrame.size.height);
        
        
    } else if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        
        drawerFirstPoint = CGPointMake(drawerFirstPoint.y, 5);
        
        drawerFrame.size.height = drawerSize;
        drawerFrame.size.width = UIScreen.screenWidth;
        drawerFrame.origin.x = 0;
        drawerFrame.origin.y = UIScreen.screenWidth;
        
        stepperFrame.origin.y = drawerFrame.size.height;
        stepperFrame.origin.x = drawerFrame.size.width - stepperFrame.size.width-10;
        imageFrame.origin.y = 0;
        imageFrame.origin.x = 0;
        
        chooseCenter = CGPointMake(self.view.center.x-10, self.view.center.y-290);
        _panningSwitch.center = CGPointMake(_panningSwitch.center.x-drawerSize, _panningSwitch.center.y);
        if (IS_iPhone) {
            percentageLabel.center = CGPointMake(percentageLabel.center.x-drawerSize, percentageLabel.center.y);
        }
        
        _lattice.center = CGPointMake(_lattice.center.x-drawerSize, _lattice.center.y);
        
        completedCenter = CGPointMake(self.view.center.x, self.view.center.y);
        
        statsFrame = CGRectMake((UIScreen.screenHeight-statsFrame.size.width)/2, UIScreen.screenWidth-240-20, statsFrame.size.width, statsFrame.size.height);
    }
    
    [self refreshPositions];    
    
    HUDFrame.origin.x = 0;
    HUDFrame.origin.y = 20;
    
    [UIView animateWithDuration:duration animations:^{
        
        CGRect rect = drawerFrame;
        NSLog(@"Rect = %.1f, %.1f, %.1f, %.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        
        _drawerView.frame = drawerFrame;
        stepperDrawer.frame = stepperFrame;
        _imageView.frame = imageFrame;
        _puzzleComplete.center = completedCenter;
        _completedController.view.frame = statsFrame;
        HUDView.frame = HUDFrame;
    }];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self organizeDrawerWithOrientation:toInterfaceOrientation];
    }];    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    didRotate = YES;
}

#pragma mark -
#pragma mark Tools

- (IBAction)togglePanningMode:(UIButton *)sender {
    if (panningMode) {
        for (PieceView *p in _pieces) {
            if (p.isFree && !p.isPositioned) {
                p.userInteractionEnabled = YES;
            }
        }
    } else {
        for (PieceView *p in _pieces) {
            if (p.isFree) {
                p.userInteractionEnabled = NO;
            }
        }
    }
    
    sender.alpha = panningMode ? 0.5 : 1;
    panningMode = !panningMode;
}

- (void)refreshPositions {
    for (PieceView *p in _pieces) {
        if (p.isFree && p.position > -1 && !p.group) {
            [self movePiece:p toLatticePoint:p.position animated:NO];
        }
    }
    
    for (GroupView *g in _groups) {
        [self moveGroup:g toLatticePoint:g.boss.position animated:NO];
    }
}

- (CGPoint)applyMatrix:(CGAffineTransform)matrix toVector:(CGPoint)vector {
    return CGPointMake(matrix.a*vector.x+matrix.b*vector.y, matrix.c*vector.x+matrix.d*vector.y);
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {
    anchorPoint = CGPointMake(anchorPoint.x / _lattice.bounds.size.width, anchorPoint.y / _lattice.bounds.size.height);
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
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

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        piece = _lattice;
        
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)shuffle {
    _pieces = [self shuffleArray:_pieces];
    
    for (int i = 0; i < _NumberSquare; i++) {
        PieceView *p = [_pieces objectAtIndex:i];
        CGRect rect = p.frame;
        rect.origin.x = _piceSize * i + drawerMargin;
        rect.origin.y = UIScreen.screenHeight - drawerSize + 5;
        p.frame = rect;
        
        int r = arc4random_uniform(4);
        p.transform = CGAffineTransformMakeRotation(r * M_PI_2);
        p.angle = r * M_PI_2;
    }
}

- (NSMutableArray*)shuffleArray:(NSMutableArray*)array {
    
    for (NSUInteger i = array.count; i > 1; i--) {
        NSUInteger j = arc4random_uniform((u_int32_t)i);
        [array exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }
    
    for (int i = 0; i < array.count; i++) {
        [array[i] setPositionInDrawer:i];
    }
    
    return array;
}

- (void)shuffleAngles {
    for (int i = 0; i < _NumberSquare; i++) {
        PieceView *p = _pieces[i];
        if (!p.isFree) {
            int r = arc4random_uniform(4);
            p.transform = CGAffineTransformMakeRotation(r * M_PI / 2);
            p.angle = r * M_PI / 2;
        }
    }
}

- (void)computePieceSize {
    //TODO: 大小重新计算
    _piceSize = IS_iPad ? PIECE_SIZE_IPAD : PIECE_SIZE_IPHONE;
    self.padding = _piceSize * 0.23;
    
    if (IS_iPad) {
        drawerSize = _piceSize + 1.8 * self.padding - 15;
    } else {
        drawerSize = _piceSize + 1.8 * self.padding - 10;
    }
    
    numberOfPiecesInDrawer = UIScreen.screenWidth / (_piceSize + 1);
    float unUsedSpace = UIScreen.screenWidth - numberOfPiecesInDrawer * _piceSize;
    drawerMargin = unUsedSpace / (numberOfPiecesInDrawer + 1);
    
    firstPiecePlace = 3 * _NumberSquare + _pieceNumber;
}

- (void)bringDrawerToTop {
    for (PieceView *p in _pieces) {
        if (p.isFree && !p.isPositioned) {
            [self.view bringSubviewToFront:p];
        }
    }
    
    [self.view bringSubviewToFront:_drawerView];
    [self.view bringSubviewToFront:HUDView];
        
    for (PieceView *p in _pieces) {
        if (!p.isFree) {
            [self.view bringSubviewToFront:p];
        }
    }
}

- (void)updatePercentage {
    _puzzleDB.percentage = @([self completedPercentage]);
    percentageLabel.text = [NSNumberFormatter localizedStringFromNumber:_puzzleDB.percentage numberStyle:NSNumberFormatterPercentStyle];
}

- (void)removeOldPieces {
    for (PieceView *p in _pieces) {
        [p removeFromSuperview];
    }
    
    for (UIView *v in _groups) {
        [v removeFromSuperview];
    }
}

- (NSOperationQueue *)operationQueue {
    if (operationQueue == nil) {
        operationQueue = [[NSOperationQueue alloc] init];
    }
    return operationQueue;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    receivedFirstTouch = YES;
    if (_imageView.alpha == 1) {
        [self toggleImageWithDuration:0.5];
    }
}

- (float)completedPercentage {
    float positioned = 0.0;
    
    for (PieceView *p in _pieces) {
        if (p.isFree && p.isPositioned) {
            positioned += 1.0;
        }
    }
    return (positioned / _NumberSquare);
}

+ (float)computeFloat:(float)f modulo:(float)m {
    float result = f - floor(f / m) * m;
    if (result > m - 0.2) {
        result = 0;
    }
    if (result < 0) {
        result = 0;
    }
    return result;
}

#pragma mark - Timer

- (void)oneSecondElapsed {
    _elapsedTime += 0.1;
    _puzzleDB.elapsedTime = @(_elapsedTime);
    
    int seconds = (int)_elapsedTime % 60;
    int minutes = (int)_elapsedTime / 60;
    
    if (_elapsedTime - (int)_elapsedTime < 0.1) {
        _elapsedTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds]; 
    }
}

- (void)startTimer {
    if (!loadingFailed && ![self isPuzzleComplete]) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(oneSecondElapsed) userInfo:nil repeats:YES];
    }
}

- (void)stopTimer {
    [timer invalidate];
}

- (void)startNewGame {
    _puzzleCompete = NO;
    [self removeOldPieces];

    _groups = [[NSMutableArray alloc] initWithCapacity:_NumberSquare];
    _pieces = [[NSMutableArray alloc] initWithCapacity:_NumberSquare];
    
    [self createPuzzleFromImage:_image];    
    receivedFirstTouch = NO;    
    
    [UIView animateWithDuration:0.2 animations:^{
        _lattice.frame = [self frameForLatticeWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }];
}

@end
