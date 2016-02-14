//
//  NewGameController.m
//  Puzzle
//
//  Created by Andrea Barbon on 28/04/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
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

@synthesize popover, delegate, imagePath, startButton, image, tapToSelectLabel, puzzleLibraryButton, progressView, slider;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPieceNumberChangedNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(piecesNotificationResponse:) name:kPieceNumberChangedNotification object:nil];
    
    backButton.titleLabel.font = [UIFont fontWithName:@"Bello-Pro" size:40];
    startButton.titleLabel.font = [UIFont fontWithName:@"Bello-Pro" size:40];

    slider.maximumValue = 8;
    pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", (int)slider.value * (int)slider.value];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        cameraButton.enabled = NO;
    }
    
    if (!image.image) {
        startButton.enabled = NO;
    }
    
    loadingView.layer.cornerRadius = 10;
    loadingView.layer.masksToBounds = YES;

    image.layer.cornerRadius = 20;
    image.layer.masksToBounds = YES;
    
    tapToSelectView.layer.cornerRadius = 20;
    tapToSelectView.layer.masksToBounds = YES;
    
    containerView.layer.cornerRadius = 20;
    containerView.layer.masksToBounds = YES;
    
    typeOfImageView.layer.cornerRadius = 20;
    typeOfImageView.layer.masksToBounds = YES;

    imagePath = [[NSString alloc] initWithFormat:@""];

    typeOfImageView.backgroundColor = [UIColor puzzleBackgroundColor];
    
}

- (void)adjustForAd {
    [delegate.delegate.view bringSubviewToFront:delegate.delegate.adBannerView];
    delegate.delegate.adBannerView.hidden = NO;

    if (IS_iPad) {
        return;
    }    

    float origin = -delegate.delegate.adPresent * delegate.delegate.adBannerView.frame.size.height / 2;
    
    NSLog(@"Origin = %.1f", origin);
    
    CGRect frame = self.view.frame;
    frame.origin.y = origin;
    self.view.frame = frame;
}

- (void)piecesNotificationResponse:(NSNotification *)notification {
    NSInteger pieceNumber = delegate.delegate.pieceNumber;
    pieceNumberLabel.text = [NSString stringWithFormat:@"%@ ", @(pieceNumber * pieceNumber)];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
        
    typeOfImageView.hidden = YES;
    [UIView animateWithDuration:0.3 animations:^{
        delegate.chooseLabel.alpha = 0;
    }];

    [delegate.delegate.view bringSubviewToFront:delegate.delegate.menuButtonView];

    DLog(@"After picking");
    
    NSData *dataJPG = UIImageJPEGRepresentation([info objectForKey:UIImagePickerControllerEditedImage], IMAGE_QUALITY);
    
    DLog(@"Image size JPG = %.2f", (float)2*((float)dataJPG.length/10000000.0));
    
    [self dismissPicker];
        
    UIImage *temp = [UIImage imageWithData:dataJPG];    
    CGRect rect = [[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    imagePath = [[info objectForKey:UIImagePickerControllerReferenceURL] absoluteString];
    
    rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.width);
    DLog(@"Original Rect = %.1f, %.1f, %.1f, %.1f",rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    tapToSelectLabel.hidden = YES;
    startButton.enabled = YES;    

    image.image = temp;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [UIView animateWithDuration:0.3 animations:^{
        delegate.chooseLabel.alpha = 0;
    }];
    
    [self dismissPicker];
}

- (void)dismissPicker {
        
    if (IS_iPad) {
        [popover dismissPopoverAnimated:NO];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickedFromPuzzleLibrary:(UIImage*)pickedImage {
    
    typeOfImageView.hidden = YES;

    [UIView animateWithDuration:0.3 animations:^{
        delegate.chooseLabel.alpha = 0;
    }];

    
    [delegate.delegate.view bringSubviewToFront:delegate.delegate.menuButtonView];
    
    DLog(@"After picking");
    
    NSData *dataJPG = UIImageJPEGRepresentation(pickedImage, IMAGE_QUALITY);
    
    DLog(@"Image size JPG = %.2f", (float)2*((float)dataJPG.length/10000000.0));
    
    [self dismissPicker];
    
    image.image = [UIImage imageWithData:dataJPG];
    
    tapToSelectLabel.hidden = YES;
    startButton.enabled = YES;    
}

- (IBAction)selectImageFromPuzzleLibrary:(id)sender {
    
    [delegate playMenuSound];
    delegate.chooseLabel.alpha = 1;
    
    PuzzleLibraryController *c = [[PuzzleLibraryController alloc] init];
    c.delegate = self;
    [self presentViewController:c animated:YES completion:nil];
}

- (IBAction)selectImageFromPhotoLibrary:(UIButton*)sender {
    
    delegate.delegate.adBannerView.hidden = YES;

    [delegate playMenuSound];
    delegate.chooseLabel.alpha = 1;

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
    
    [delegate playMenuSound];

    typeOfImageView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        delegate.chooseLabel.alpha = 0;
    }];
}

- (IBAction)startNewGame:(id)sender {
    [delegate playMenuSound];
    
    DLog(@"Started");
    
    tapToSelectView.hidden = YES;
    
    delegate.delegate.loadingGame = NO;

    delegate.delegate.image = image.image;
    
    delegate.delegate.imageView.image = delegate.delegate.image;
    delegate.delegate.imageViewLattice.image = delegate.delegate.image;
    if (!self.slider.hidden) {
        delegate.delegate.pieceNumber = (int)slider.value;
    }
    
    [self startLoading];

    [delegate.delegate removeOldPieces];
    
    [delegate createNewGame];
}

- (IBAction)back:(id)sender {
    
    [delegate playMenuSound];

    if (typeOfImageView.hidden) {
        
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(self.view.frame.size.width, self.view.frame.origin.y,
                                         self.view.frame.size.width, self.view.frame.size.height);
            
            delegate.mainView.frame = CGRectMake(0, delegate.mainView.frame.origin.y, 
                                                 self.view.frame.size.width, self.view.frame.size.height);
        }completion:^(BOOL finished) {
            typeOfImageView.hidden = YES;
        }];
    } else {
        typeOfImageView.hidden = YES;
    }
    
}

- (void)startLoading {
    startButton.hidden = YES;
    backButton.hidden = YES;
    
    if (delegate.delegate.loadingGame) {
        
        int n = [delegate.delegate.puzzleDB.pieceNumber intValue];
        pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", n*n];
        slider.value = (float)n;
        tapToSelectView.hidden = YES;
        image.image = delegate.delegate.image;

    } else {

        image.image = delegate.delegate.image;
    }

    slider.enabled = NO;    
    
    if (image.image==nil) {
        image.image = [UIImage imageNamed:@"Wood.jpg"];
    }
    
    progressView.hidden = NO;
    loadingView.hidden = NO;
    progressView.progress = 0.0;
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(moveBar) userInfo:nil repeats:YES];
}


- (void)gameStarted {
    
    DLog(@"Game is started");
    
    [timer invalidate];

    [delegate toggleMenuWithDuration:0];
    
    progressView.progress = 0.0;
    delegate.delegate.loadedPieces = 0;
    progressView.hidden = YES;  
    loadingView.hidden = YES;
    startButton.hidden = NO;
    backButton.hidden = NO;
    pieceNumberLabel.hidden = NO;    
    slider.enabled = YES;    
    piecesLabel.hidden = NO;
    tapToSelectView.hidden = NO;
    tapToSelectLabel.hidden = NO;

    pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", (int)slider.value*(int)slider.value];
}

- (void)loadingFailed {
    
    DLog(@"Game failed");
    
    [timer invalidate];
    
    [delegate toggleMenuWithDuration:0];
        
    progressView.progress = 0.0;
    delegate.delegate.loadedPieces = 0;
    progressView.hidden = YES;  
    loadingView.hidden = YES;
    
    startButton.hidden = NO;
    backButton.hidden = NO;
    
    pieceNumberLabel.hidden = NO;    
    slider.enabled = YES;    
    piecesLabel.hidden = NO;
    tapToSelectView.hidden = NO;
    tapToSelectLabel.hidden = NO ;
    
    pieceNumberLabel.text = [NSString stringWithFormat:@"%d ", (int)slider.value*(int)slider.value];    
    
    self.view.frame = CGRectMake(self.view.frame.size.width, self.view.frame.origin.y, 
                                 self.view.frame.size.width, self.view.frame.size.height);

}


- (void)moveBar {
    float a = (float)delegate.delegate.loadedPieces;
    float b = (float)(slider.value * slider.value);
    
    if (delegate.delegate.loadingGame) {
        b = delegate.delegate.NumberSquare;
    }
    progressView.progress = a / b;
}


- (IBAction)numberSelected:(UISlider *)sender {
    pieceNumberLabel.text = [NSString stringWithFormat:@"%@ ", @(slider.value * slider.value)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
