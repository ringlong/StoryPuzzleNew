//
//  PuzzleCompletedController.m
//  Puzzle
//
//  Created by Andrea Barbon on 13/05/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
//

#import "PuzzleCompletedController.h"
#import "PuzzleController.h"
#import <QuartzCore/QuartzCore.h>

@interface PuzzleCompletedController ()

@end

@implementation PuzzleCompletedController

@synthesize delegate;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    int size = IS_iPad ? 60 : 40;
    score.font = [UIFont fontWithName:@"Bello-Pro" size:size];
    
    self.view.layer.cornerRadius = 20;
    self.view.layer.masksToBounds = YES;
}

- (void)updateValues {
    pieces.text = [@(delegate.NumberSquare).stringValue stringByAppendingString:@"squares"];
    time.text = delegate.elapsedTimeLabel.text;

    score.text = @(delegate.score).stringValue;
    moves.text = @(delegate.moves).stringValue;
    rotations.text = @(delegate.rotations).stringValue;

}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        two.center = CGPointMake(one.center.x + 320, 80);
    } else {
        two.center = CGPointMake(160, 240);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
