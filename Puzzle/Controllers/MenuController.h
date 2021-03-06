//
//  MenuController.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import "NewGameController.h"

@import UIKit;
@import QuartzCore;
@import AVFoundation;
@import MediaPlayer;
@class PuzzleController;
@class NewGameController;
@class LoadGameController;

@protocol MenuProtocol

- (void)startNewGame;

@end

@interface MenuController : UIViewController <NewGameDelegate>

@property (nonatomic, assign) PuzzleController *delegate;
@property (nonatomic) BOOL duringGame;
@property (nonatomic, retain) NewGameController *game;
@property (nonatomic, retain) LoadGameController *loadGameController;

@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (nonatomic, retain) UIView *obscuringView;

- (IBAction)startNewGame:(id)sender;
- (IBAction)resumeGame:(id)sender;
- (IBAction)loadGame:(id)sender;
- (IBAction)showThePicture:(id)sender;

- (void)toggleMenuWithDuration:(float)duration;

- (void)createNewGame;

@end
