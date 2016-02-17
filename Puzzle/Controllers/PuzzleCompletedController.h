//
//  PuzzleCompletedController.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PuzzleController;

@interface PuzzleCompletedController : UIViewController {
    IBOutlet UIView *one;
    IBOutlet UIView *two;
    IBOutlet UILabel *pieces;
    IBOutlet UILabel *time;    
    IBOutlet UILabel *score;
    IBOutlet UILabel *moves;
    IBOutlet UILabel *rotations;    
}

@property (nonatomic, assign) PuzzleController *delegate;

- (void)updateValues;

@end
