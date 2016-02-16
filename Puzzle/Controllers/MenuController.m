//
//  MenuController.m
//  Puzzle
//
//  Created by Andrea Barbon on 27/04/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
//

#import "MenuController.h"
#import "PuzzleController.h"
#import "NewGameController.h"
#import "LoadGameController.h"

@interface MenuController ()

@end

@implementation MenuController

@synthesize delegate, duringGame, game, obscuringView, mainView, menuSound, chooseLabel, loadGameController;


- (void)toggleMenuWithDuration:(float)duration {
    resumeButton.hidden = !duringGame;
    showThePictureButton.hidden = (!duringGame || delegate.puzzleCompete);
    float obscuring = 1;

    if (self.view.alpha == 0) {
        [delegate.view removeGestureRecognizer:delegate.pan];

        [UIView animateWithDuration:duration animations:^{
            obscuringView.alpha = obscuring;
            self.view.alpha = 1;
            delegate.completedController.view.alpha = 0;
        }];
        [delegate stopTimer];
    } else {
        [delegate.view addGestureRecognizer:delegate.pan];
        
        [UIView animateWithDuration:duration animations:^{
            obscuringView.alpha = 0;
            self.view.alpha = 0;
            if (delegate.puzzleCompete) delegate.completedController.view.alpha = 1;
        } completion:^(BOOL finished) {
            game.view.frame = CGRectMake(self.view.frame.size.width, game.view.frame.origin.y,
                                         game.view.frame.size.width, game.view.frame.size.height);
            mainView.frame = CGRectMake(0, mainView.frame.origin.y,
                                        mainView.frame.size.width, mainView.frame.size.height);
            [delegate startTimer];
        }];
    }
}

- (void)createNewGame {
        
    [delegate startNewGame];            
}

- (IBAction)startNewGame:(id)sender {
    if (sender) {
        [UIView animateWithDuration:0.3 animations:^{
            [self showNewGameView];
        }];
    } else {
        [self showNewGameView];
    }
}

- (void)showNewGameView {
    chooseLabel.center = CGPointMake(self.view.center.x - 5, self.view.center.y - 280);
    game.tapToSelectLabel.hidden = NO;
    game.startButton.enabled = game.image.image;
    game.view.frame = CGRectMake(0, game.view.frame.origin.y, game.view.frame.size.width, game.view.frame.size.height);
    mainView.frame = CGRectMake(-mainView.frame.size.width, mainView.frame.origin.y, mainView.frame.size.width, mainView.frame.size.height);
}

- (IBAction)loadGame:(id)sender {

    [loadGameController reloadData];

    float f = 0;//delegate.adBannerView.bannerLoaded*delegate.adBannerView.frame.size.height;

    [UIView animateWithDuration:0.3 animations:^{
        loadGameController.view.frame = CGRectMake(0, f/2, game.view.frame.size.width, game.view.frame.size.height-f);
        mainView.frame = CGRectMake(-mainView.frame.size.width, mainView.frame.origin.y, mainView.frame.size.width, mainView.frame.size.height);
    }];
}

- (IBAction)resumeGame:(id)sender {
    
    DLog(@"Resume game");
    
    delegate.puzzleCompleteImage.alpha = 0;
    [self toggleMenuWithDuration:0.5];
}

- (IBAction)showThePicture:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Hint" message:@"A shortcut to show the image: hold one finger on the screen for 1 second.\nEnjoy!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [delegate toggleImageWithDuration:0.5];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (IS_iPad) {
        self.view.layer.masksToBounds = YES;
        self.view.layer.cornerRadius = 20;        
    }

    obscuringView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    obscuringView.backgroundColor = [UIColor puzzleBackgroundColor];
    
    chooseLabel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ChooseLabel"]];
    chooseLabel.alpha = 0;
    
    if (IS_iPad) {
        [obscuringView addSubview:chooseLabel];
    }
    
    [delegate.view addSubview:obscuringView];
    [delegate.view bringSubviewToFront:self.view];
    
    resumeButton.hidden = YES;
    showThePictureButton.hidden = YES; 
    
    mainView.frame = CGRectMake(0, 0, mainView.frame.size.width, mainView.frame.size.height);

    game = [[NewGameController alloc] init];    
    game.view.frame = CGRectMake(self.view.frame.size.width, 0, game.view.frame.size.width, game.view.frame.size.height);
    game.delegate = self;

    [self.view addSubview:game.view];
    
    loadGameController = [[LoadGameController alloc] init];   
    loadGameController.view.frame = CGRectMake(mainView.frame.size.width, 0, loadGameController.view.frame.size.width, loadGameController.view.frame.size.height);
    loadGameController.delegate = self;
    
    [self.view addSubview:loadGameController.view];
}

@end
