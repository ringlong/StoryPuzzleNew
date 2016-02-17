//
//  PuzzleController.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

@import UIKit;
@import QuartzCore;
@import AVFoundation;
@import MediaPlayer;

#import "UIImage+CWAdditions.h"
#import "PieceView.h"
#import "MenuController.h"
#import "PuzzleCompletedController.h"
#import "Lattice.h"
#import "Piece.h"
#import "Puzzle.h"
#import "Image.h"
#import "CreatePuzzleOperation.h"

#define QUALITY 1.5

#define PIECE_SIZE_IPAD 180
#define PIECE_SIZE_IPHONE 88

UIKIT_EXTERN NSString * const kPieceNumberChangedNotification;

@interface PuzzleController : UIViewController<UIGestureRecognizerDelegate, PieceViewProtocol, MenuProtocol, CreatePuzzleDelegate, UIAlertViewDelegate> {
    BOOL swiping;
    BOOL didRotate;
    BOOL receivedFirstTouch;
    BOOL panningMode;
    BOOL panningDrawerUP;
    BOOL loadingFailed;
        
    CGPoint drawerFirstPoint;
    IBOutlet UIStepper *stepper;
    IBOutlet UIView *stepperDrawer;
    IBOutlet UIButton *restartButton;
    IBOutlet UILabel *percentageLabel;
    IBOutlet UILabel *scoreLabel;
    IBOutlet UIView *HUDView;
    IBOutlet UIView *firstPointView;

    NSArray *directions_positions;
    NSArray *directions_numbers;
    
    NSInteger numberOfPiecesInDrawer;
    NSInteger DrawerPosition;
    NSInteger firstPiecePlace;
    
    float drawerSize;
    float drawerMargin;
    float biggerPieceSize;

    NSTimer *timer;
    PieceView *movingPiece;
}

@property (nonatomic) float piceSize;
@property (nonatomic) float elapsedTime;
@property (nonatomic) float padding;
@property (nonatomic) NSInteger NumberSquare;
@property (nonatomic) NSInteger pieceNumber;
@property (nonatomic) NSInteger loadedPieces;
@property (nonatomic) NSInteger missedPieces;
@property (nonatomic) NSInteger imageSize;
@property (nonatomic) NSInteger moves;
@property (nonatomic) NSInteger rotations;
@property (nonatomic) NSInteger score;

@property (nonatomic) BOOL loadingGame;
@property (nonatomic) BOOL creatingGame;
@property (nonatomic) BOOL puzzleCompete;
@property (nonatomic) BOOL drawerStopped;
@property (nonatomic) BOOL duringGame;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, retain) CreatePuzzleOperation *puzzleOperation;
@property (nonatomic, retain) Puzzle *puzzleDB;
@property (nonatomic, retain) IBOutlet UIView *drawerView;
@property (nonatomic, retain) IBOutlet UIView *menuButtonView;
@property (nonatomic, retain) IBOutlet UILabel *elapsedTimeLabel;;
@property (nonatomic, retain) IBOutlet UIButton *panningSwitch;
@property (nonatomic, strong) UIImageView *puzzleCompleteImage;
@property (nonatomic, strong) UILabel *puzzleComplete;

@property (nonatomic, retain) NSMutableArray *pieces;
@property (nonatomic, retain) NSMutableArray *groups;
@property (nonatomic, retain) Lattice *lattice;
@property (nonatomic, retain) UIPanGestureRecognizer *pan;
@property (nonatomic, retain) UIPanGestureRecognizer *panDrawer;
@property (nonatomic, retain) UIPinchGestureRecognizer *pinch;

@property (nonatomic, retain) MenuController *menu;
@property (nonatomic, retain) PuzzleCompletedController *completedController;
@property (nonatomic, retain) UIViewController *adViewController;

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIImageView *imageViewLattice;

+ (float)computeFloat:(float)f modulo:(float)m;
- (NSMutableArray*)shuffleArray:(NSMutableArray*)array;

- (void)fuckingRotateTo:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (BOOL)pieceIsOut:(PieceView *)piece;
- (PieceView*)pieceWithNumber:(NSInteger)j;
- (PieceView*)pieceWithPosition:(NSInteger)j;
- (NSInteger)positionOfPiece:(PieceView*)piece;

- (void)toggleImageWithDuration:(float)duration;

- (IBAction)restartPuzzle:(id)sender;
- (IBAction)togglePanningMode:(id)sender;
- (IBAction)puzzleCompleted;
- (IBAction)toggleMenu:(id)sender;

- (void)loadPuzzle:(Puzzle *)puzzleDB;
- (BOOL)drawerStoppedShouldBeStopped;
- (Puzzle *)lastSavedPuzzle;
- (void)prepareForNewPuzzle;
- (void)prepareForLoading;

- (CGRect)frameOfLatticePiece:(NSInteger)i;

- (UIView *)upperPositionedThing;

- (void)panDrawer:(UIPanGestureRecognizer*)gesture;
- (void)pan:(UIPanGestureRecognizer*)gesture;

- (void)movePiece:(PieceView *)piece toLatticePoint:(NSInteger)i animated:(BOOL)animated;
- (void)groupMoved:(GroupView *)group;

- (void)startNewGame;
- (void)removeOldPieces;

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view;

- (void)allPiecesLoaded;
- (Piece *)pieceOfCurrentPuzzleDB:(NSInteger)n;

- (void)startTimer;
- (void)stopTimer;

- (void)loadingFailed;

- (void)puzzleSaved:(NSNotification *)saveNotification;
- (void)addPiecesToView;
- (void)resetSizeOfAllThePieces;
- (BOOL)saveGame;
- (BOOL)isPositioned:(PieceView*)piece;

- (UIView *)upperGroupBut:(GroupView *)group;
- (void)moveBar;
- (void)addAnothePieceToView;

@end
