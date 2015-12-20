//
//  PuzzleLibraryController.m
//  Puzzle
//
//  Created by Andrea Barbon on 10/05/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
//

#import "PuzzleLibraryController.h"
#import "NewGameController.h"
#import "MenuController.h"
#import "UIColor+Additions.h"
#import <QuartzCore/QuartzCore.h>

#define IMAGE_SIZE 240

@implementation PhotoCell

@end



@implementation PuzzleLibraryController

@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];

    thumbs = [NSArray arrayWithArray:[self imagesForPuzzle]];
    paths = [NSArray arrayWithArray:[self pathsForImages]];
    contents = [NSArray arrayWithArray:[self joinData]];
    
    if (contents.count == 0) {
        delegate.puzzleLibraryButton.enabled = NO;
    }
    
    self.clearsSelectionOnViewWillAppear = YES;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSMutableArray *)shuffleArray:(NSMutableArray*)array {
    
    for (NSUInteger i = array.count; i > 1; i--) {
        u_int32_t j = arc4random_uniform((u_int32_t)i);
        [array exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }
    
    return array;
}

#pragma mark - Table view data source

- (NSArray *)joinData {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:paths.count];
    for (int i = 0; i < paths.count; i++) {
        
        NSArray *objects = @[paths[i], thumbs[i]];
        NSArray *keys = @[@"Path", @"Thumb"];
        NSDictionary *dict = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
        [tempArray addObject:dict];
    }
    
    return [NSArray arrayWithArray:[self shuffleArray:tempArray]];
    
}

- (NSArray *)imagesForPuzzle {
    
    NSArray *dirContents = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:nil];
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:dirContents.count];
    for (NSString *string in dirContents) {
        if ([string hasSuffix:@"-puzzle.jpeg"]) {
            [tempArray addObject:[UIImage imageWithContentsOfFile:string]];
        }
    }
    DLog(@"Found %d thumbs", tempArray.count);
    return [NSArray arrayWithArray:tempArray];
    
}

- (NSArray *)pathsForImages {
    
    NSArray *dirContents = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:nil];
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:dirContents.count];
    for (NSString *string in dirContents)  {
        if ([string hasSuffix:@"-puzzle.jpeg"]) {
            [tempArray addObject:string];
        }
    }
    DLog(@"Found %d images", tempArray.count);
    return [NSArray arrayWithArray:tempArray];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return 64;
    } else {
        return IMAGE_SIZE + 30;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return contents.count;
            break;            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        static NSString *CellIdentifier = @"Back";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = @"Back";
        cell.textLabel.textColor = [UIColor blueColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        return cell;
        
    } else {
        
        static NSString *CellIdentifier = @"Cell";
        PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (!cell) {
            
            CGFloat width = self.view.bounds.size.width;
            cell = [[PhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.photo = [[UIImageView alloc] initWithFrame:CGRectMake((width - IMAGE_SIZE) / 2, 15, IMAGE_SIZE, IMAGE_SIZE)];
            cell.photo.contentMode = UIViewContentModeScaleAspectFill;
            cell.photo.layer.cornerRadius = 20;
            cell.photo.layer.masksToBounds = YES;
            [cell addSubview:cell.photo];
        }
        
        cell.photo.image = contents[indexPath.row][@"Thumb"];
        return cell;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        [delegate imagePickedFromPuzzleLibrary:delegate.image.image];
    } else {
        [delegate.delegate playMenuSound];
        NSString *path = contents[indexPath.row][@"Path"];
        [delegate imagePickedFromPuzzleLibrary:[UIImage imageWithContentsOfFile:path]];
        
    }
}

@end
