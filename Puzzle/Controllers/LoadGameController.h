//
//  LoadGameController.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

@import UIKit;
@import QuartzCore;

@class MenuController;

@interface LoadGameController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    
    NSMutableArray *contents;
    NSDateFormatter *df;
    BOOL loading;    
}

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext; 
@property (nonatomic, assign) MenuController *delegate; 
@property (nonatomic, retain) NSMutableArray *contents;
@property (nonatomic, retain) NSMutableArray *images;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (void)reloadData;

@end
