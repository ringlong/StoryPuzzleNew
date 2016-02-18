//
//  NewGameController.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

@import UIKit;
@class MenuController, PuzzleLibraryController;

@protocol NewGameDelegate

- (void)createNewGame;

@end

@interface NewGameController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate> {
    
    IBOutlet UILabel *pieceNumberLabel;
    IBOutlet UIButton *piecesLabel;
    IBOutlet UISlider *slider;
    IBOutlet UIButton *backButton;
    IBOutlet UIButton *imageButton;
    IBOutlet UIButton *cameraButton;
    IBOutlet UIButton *yourPhotosButton;
    IBOutlet UIActivityIndicatorView *indicator;
    IBOutlet UIView *loadingView;
    IBOutlet UIView *tapToSelectView;
    IBOutlet UIView *containerView;
    IBOutlet UIView *typeOfImageView;
    NSTimer *timer;
    
    int times;
}

@property (nonatomic, retain) IBOutlet UIProgressView *progressView;

@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, assign) MenuController *delegate;
@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIImageView *image;
@property (nonatomic, retain) IBOutlet UIView *tapToSelectLabel;
@property (nonatomic, retain) IBOutlet UIButton *puzzleLibraryButton;
@property (nonatomic, retain) IBOutlet UISlider *slider;

- (IBAction)startNewGame:(id)sender;
- (IBAction)numberSelected:(UISlider*)sender;
- (IBAction)selectImage:(id)sender;
- (void)gameStarted;
- (void)moveBar;
- (void)startLoading;
- (void)loadingFailed;
- (void)imagePickedFromPuzzleLibrary:(UIImage*)pickedImage;

@end
