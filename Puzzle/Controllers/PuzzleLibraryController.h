//
//  PuzzleLibraryController.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NewGameController;

@interface PuzzleLibraryController : UITableViewController {
    NSArray *contents;
    NSArray *thumbs;
    NSArray *paths;
}

@property (nonatomic, assign) NewGameController *delegate;

@end


@interface PhotoCell : UITableViewCell

@property (nonatomic, strong) UIImageView *photo;

@end