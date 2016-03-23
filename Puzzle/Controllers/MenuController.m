//
//  MenuController.m
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import "MenuController.h"
#import "PuzzleController.h"
#import "NewGameController.h"
#import "LoadGameController.h"
#import "FLEXManager.h"

@interface MenuController ()

@property (nonatomic, weak) IBOutlet UIButton *resumeButton;
@property (nonatomic, weak) IBOutlet UIButton *showThePictureButton;
@property (nonatomic, weak) IBOutlet UIButton *loadGameButton;
@property (weak, nonatomic) IBOutlet UIButton *startNewGame;

@end

@implementation MenuController

- (void)toggleMenuWithDuration:(float)duration {
    _resumeButton.hidden = !_duringGame;
    _showThePictureButton.hidden = (!_duringGame || _delegate.puzzleCompete);
    float obscuring = 1;

    if (self.view.alpha == 0) {
        [_delegate.view removeGestureRecognizer:_delegate.pan];

        [UIView animateWithDuration:duration animations:^{
            _obscuringView.alpha = obscuring;
            self.view.alpha = 1;
            _delegate.completedController.view.alpha = 0;
        }];
        [_delegate stopTimer];
    } else {
        [_delegate.view addGestureRecognizer:_delegate.pan];
        
        [UIView animateWithDuration:duration animations:^{
            _obscuringView.alpha = 0;
            self.view.alpha = 0;
            if (_delegate.puzzleCompete) _delegate.completedController.view.alpha = 1;
        } completion:^(BOOL finished) {
            _game.view.frame = CGRectMake(self.view.frame.size.width, _game.view.frame.origin.y,
                                         _game.view.frame.size.width, _game.view.frame.size.height);
            _mainView.frame = CGRectMake(0, _mainView.frame.origin.y,
                                        _mainView.frame.size.width, _mainView.frame.size.height);
            [_delegate startTimer];
        }];
    }
}

- (void)createNewGame {
    [_delegate startNewGame];
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
    _game.tapToSelectLabel.hidden = NO;
    _game.startButton.enabled = (_game.image.image != nil);
    _game.view.frame = CGRectMake(0, _game.view.frame.origin.y, _game.view.frame.size.width, _game.view.frame.size.height);
    _mainView.frame = CGRectMake(-_mainView.frame.size.width, _mainView.frame.origin.y, _mainView.frame.size.width, _mainView.frame.size.height);
}

- (IBAction)loadGame:(UIButton *)sender {
    [_loadGameController reloadData];

    float f = 0;
    [UIView animateWithDuration:0.3 animations:^{
        _loadGameController.view.frame = CGRectMake(0, f/2, _game.view.frame.size.width, _game.view.frame.size.height-f);
        _mainView.frame = CGRectMake(-_mainView.frame.size.width, _mainView.frame.origin.y, _mainView.frame.size.width, _mainView.frame.size.height);
    }];
}

- (IBAction)resumeGame:(UIButton *)sender {
    _delegate.puzzleCompleteImage.alpha = 0;
    [self toggleMenuWithDuration:0.5];
}

- (IBAction)showThePicture:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Hint" message:@"A shortcut to show the image: hold one finger on the screen for 1 second.\nEnjoy!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [_delegate toggleImageWithDuration:0.5];
}

- (IBAction)showFLEX:(UIButton *)sender {
    [[FLEXManager sharedManager] showExplorer];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor puzzleBackgroundColor];
    _obscuringView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _obscuringView.backgroundColor = [UIColor puzzleBackgroundColor];
    
    [_delegate.view addSubview:_obscuringView];
    [_delegate.view bringSubviewToFront:self.view];
    
    _resumeButton.hidden = YES;
    _showThePictureButton.hidden = YES;
    
    _mainView.frame = CGRectMake(0, 0, _mainView.frame.size.width, _mainView.frame.size.height);

    _game = [[NewGameController alloc] init];    
    _game.view.frame = CGRectMake(self.view.frame.size.width, 0, _game.view.frame.size.width, _game.view.frame.size.height);
    _game.delegate = self;

    [self.view addSubview:_game.view];
    
    _loadGameController = [[LoadGameController alloc] init];   
    _loadGameController.view.frame = CGRectMake(_mainView.frame.size.width, 0, _loadGameController.view.frame.size.width, _loadGameController.view.frame.size.height);
    _loadGameController.delegate = self;
    
    [self.view addSubview:_loadGameController.view];
}

@end
