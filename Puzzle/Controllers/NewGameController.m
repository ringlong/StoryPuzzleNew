//
//  NewGameController.m
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import "NewGameController.h"
#import "MenuController.h"
#import "PuzzleController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+CWAdditions.h"
#import "PuzzleLibraryController.h"

#define IMAGE_QUALITY 0.5


@interface NewGameController ()

@end

@implementation NewGameController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPieceNumberChangedNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(piecesNotificationResponse:) name:kPieceNumberChangedNotification object:nil];
    
    _slider.maximumValue = 8;
    pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", (int)_slider.value * (int)_slider.value];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        cameraButton.enabled = NO;
    }
    
    if (!_image.image) {
        _startButton.enabled = NO;
    }
    
    loadingView.cornerRadius = 10;
    _image.cornerRadius = 20;
    tapToSelectView.cornerRadius = 20;
    containerView.cornerRadius = 20;
    typeOfImageView.cornerRadius = 20;
    _imagePath = [[NSString alloc] initWithFormat:@""];
    typeOfImageView.backgroundColor = [UIColor puzzleBackgroundColor];
}

- (void)piecesNotificationResponse:(NSNotification *)notification {
    NSInteger pieceNumber = _delegate.delegate.pieceNumber;
    pieceNumberLabel.text = [NSString stringWithFormat:@"%@ ", @(pieceNumber * pieceNumber)];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
        
    typeOfImageView.hidden = YES;

    [_delegate.delegate.view bringSubviewToFront:_delegate.delegate.menuButtonView];
    
    NSData *dataJPG = UIImageJPEGRepresentation([info objectForKey:UIImagePickerControllerEditedImage], IMAGE_QUALITY);
    
    [self dismissPicker];
        
    UIImage *temp = [UIImage imageWithData:dataJPG];    
    CGRect rect = [[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    _imagePath = [[info objectForKey:UIImagePickerControllerReferenceURL] absoluteString];
    
    rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.width);
    
    _tapToSelectLabel.hidden = YES;
    _startButton.enabled = YES;    

    _image.image = temp;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissPicker];
}

- (void)dismissPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickedFromPuzzleLibrary:(UIImage*)pickedImage {
    typeOfImageView.hidden = YES;
    [_delegate.delegate.view bringSubviewToFront:_delegate.delegate.menuButtonView];
    
    NSData *dataJPG = UIImageJPEGRepresentation(pickedImage, IMAGE_QUALITY);
    
    [self dismissPicker];
    
    _image.image = [UIImage imageWithData:dataJPG];
    
    _tapToSelectLabel.hidden = YES;
    _startButton.enabled = YES;    
}

- (IBAction)selectImageFromPuzzleLibrary:(id)sender {
    PuzzleLibraryController *c = [[PuzzleLibraryController alloc] init];
    c.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:c];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)selectImageFromPhotoLibrary:(UIButton *)sender {
    int direction;

    UIImagePickerController *c = [[UIImagePickerController alloc] init];
   
    if ([sender.titleLabel.text isEqualToString:@"Camera"]) {
        c.sourceType = UIImagePickerControllerSourceTypeCamera;
        direction = UIPopoverArrowDirectionUp;
    } else {
        c.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        direction = UIPopoverArrowDirectionUp;
    }
    
    c.allowsEditing = YES;
    c.delegate = self;
    
    [self presentViewController:c animated:YES completion:nil];
}

- (IBAction)selectImage:(id)sender {
    typeOfImageView.hidden = NO;
}

- (IBAction)startNewGame:(id)sender {
    DLog(@"Started");
    
    tapToSelectView.hidden = YES;
    
    _delegate.delegate.loadingGame = NO;

    _delegate.delegate.image = _image.image;
    
    _delegate.delegate.imageView.image = _delegate.delegate.image;
    _delegate.delegate.imageViewLattice.image = _delegate.delegate.image;
    if (!self.slider.hidden) {
        _delegate.delegate.pieceNumber = (int)_slider.value;
    }
    
    [self startLoading];

    [_delegate.delegate removeOldPieces];
    
    [_delegate createNewGame];
}

- (IBAction)back:(id)sender {
    if (typeOfImageView.hidden) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(self.view.width, self.view.top,
                                         self.view.width, self.view.height);
            _delegate.mainView.frame = CGRectMake(0, _delegate.mainView.frame.origin.y,
                                                 self.view.width, self.view.height);
        } completion:^(BOOL finished) {
            typeOfImageView.hidden = YES;
        }];
    } else {
        typeOfImageView.hidden = YES;
    }
}

- (void)startLoading {
    _startButton.hidden = YES;
    backButton.hidden = YES;
    
    if (_delegate.delegate.loadingGame) {
         int n = [_delegate.delegate.puzzleDB.pieceNumber intValue];
        pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", n*n];
        _slider.value = (float)n;
        tapToSelectView.hidden = YES;
        _image.image = _delegate.delegate.image;

    } else {
         _image.image = _delegate.delegate.image;
    }

    _slider.enabled = NO;    
    
    if (!_image.image) {
        _image.image = [UIImage imageNamed:@"Wood.jpg"];
    }
    
    _progressView.hidden = NO;
    loadingView.hidden = NO;
    _progressView.progress = 0.0;    
}


- (void)gameStarted {
    [timer invalidate];

    [_delegate toggleMenuWithDuration:0];
    
    _progressView.progress = 0.0;
    _delegate.delegate.loadedPieces = 0;
    _progressView.hidden = YES;  
    loadingView.hidden = YES;
    _startButton.hidden = NO;
    backButton.hidden = NO;
    pieceNumberLabel.hidden = NO;    
    _slider.enabled = YES;    
    piecesLabel.hidden = NO;
    tapToSelectView.hidden = NO;
    _tapToSelectLabel.hidden = NO;

    pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", (int)_slider.value * (int)_slider.value];
}

- (void)loadingFailed {
    
    DLog(@"Game failed");
    [timer invalidate];
    [_delegate toggleMenuWithDuration:0];
        
    _progressView.progress = 0.0;
    _delegate.delegate.loadedPieces = 0;
    _progressView.hidden = YES;  
    loadingView.hidden = YES;
    
    _startButton.hidden = NO;
    backButton.hidden = NO;
    
    pieceNumberLabel.hidden = NO;    
    _slider.enabled = YES;    
    piecesLabel.hidden = NO;
    tapToSelectView.hidden = NO;
    _tapToSelectLabel.hidden = NO ;
    
    pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", (int)_slider.value*(int)_slider.value];    
    
    self.view.frame = CGRectMake(self.view.width, self.view.top,
                                 self.view.width, self.view.height);
}

- (void)moveBar {
    float a = (float)_delegate.delegate.loadedPieces;
    float b = (float)(_slider.value * _slider.value);
    
    if (_delegate.delegate.loadingGame) {
        b = _delegate.delegate.NumberSquare;
    }
    _progressView.progress = a / b;
}

- (IBAction)numberSelected:(UISlider *)sender {
    pieceNumberLabel.text = [NSString stringWithFormat:@"%@ ", @(_slider.value * _slider.value)];
}

@end
