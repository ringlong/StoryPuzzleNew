//
//  LoadGameController.m
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import "LoadGameController.h"
#import "PuzzleController.h"
#import "MenuController.h"
#import "Puzzle.h"
#import "Image.h"

@interface LoadGameController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation LoadGameController

@synthesize managedObjectContext, delegate, contents, images;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = UIView.new;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"d MMM YYYY - hh:mm"];
    
    contents = [[NSMutableArray alloc] initWithCapacity:100];
    images = [[NSMutableArray alloc] initWithCapacity:100];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, UIScreen.screenWidth, 64)];
    [self.view addSubview:navBar];

    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Load Games"];
    item.rightBarButtonItem = self.editButtonItem;
    item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    navBar.items = @[item];
    _indicator.centerX = self.view.width / 2;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
}

- (void)reloadData {
    if (loading) {
        return;
    }
    loading = YES;
    [_tableView reloadData];
    _indicator.hidden = NO;
    [_indicator startAnimating];
    [NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

- (void)fetchData {
    
    NSFetchRequest *fetchRequest1 = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Puzzle"  inManagedObjectContext:delegate.delegate.managedObjectContext];
    
    [fetchRequest1 setEntity:entity];
    fetchRequest1.predicate = [NSPredicate predicateWithFormat:@"name != %@", delegate.delegate.puzzleDB.name];
    
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"lastSaved" ascending:NO];
    [fetchRequest1 setSortDescriptors:[NSArray arrayWithObject:dateSort]];
    dateSort = nil;
    [fetchRequest1 setFetchLimit:100];
    
    contents = [NSMutableArray arrayWithArray:[delegate.delegate.managedObjectContext executeFetchRequest:fetchRequest1 error:nil]];
    
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:100];
    
    for (Puzzle *puzzle in contents) {
        [array addObject:[[UIImage imageWithData:puzzle.image.data] imageByResizingToFitSize:CGSizeMake(400, 400) scaleUpIfNeeded:YES]];
    }
    
    images = array;
    array = nil;
    _indicator.hidden = YES;
    [_indicator stopAnimating];
    loading = NO;
    [_tableView reloadData];
}

- (IBAction)back:(id)sender {
    [delegate.delegate.managedObjectContext save:nil];
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.view.frame = CGRectMake(delegate.mainView.frame.size.width, self.view.frame.origin.y, 
                                     self.view.frame.size.width, self.view.frame.size.height);
        delegate.mainView.frame = CGRectMake(0, delegate.mainView.frame.origin.y,
                                             delegate.mainView.frame.size.width, delegate.mainView.frame.size.height);
    }];

}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return !loading;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        UIView *selectedBackgroundView = [[UIView alloc] init];
        selectedBackgroundView.backgroundColor = [UIColor colorWithRGBHex:0xe98f74];;
        cell.selectedBackgroundView = selectedBackgroundView;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.detailTextLabel.textColor = [UIColor colorWithRGBHex:0xfbf3b1];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.textAlignment = NSTextAlignmentRight;
        cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
    }
        
    Puzzle *puzzle = contents[indexPath.row];
    UIImage *image = images[indexPath.row];
    cell.imageView.image = [image imageByScalingProportionallyToSize:CGSizeMake(80, 80)];
    cell.textLabel.text = [df stringFromDate:[puzzle lastSaved]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ pieces, %@%% completed", @(puzzle.pieceNumber.integerValue * puzzle.pieceNumber.integerValue), @(puzzle.percentage.integerValue)];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Puzzle *puzzleToDelete = [contents objectAtIndex:indexPath.row];

        [delegate.delegate.managedObjectContext deleteObject:puzzleToDelete];

        [delegate.delegate.managedObjectContext deleteObject:puzzleToDelete];
        [contents removeObjectAtIndex:indexPath.row];
        [images removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }    
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    delegate.delegate.puzzleCompete = NO;
    
    [delegate.delegate.managedObjectContext save:nil];
    [delegate.delegate prepareForNewPuzzle];
    [delegate.delegate loadPuzzle:[contents objectAtIndex:indexPath.row]];
    delegate.game.view.frame = CGRectMake(-delegate.mainView.frame.size.width, 
                                          delegate.game.view.frame.origin.y, 
                                          self.view.frame.size.width, 
                                          self.view.frame.size.height);        
    
    [UIView animateWithDuration:0.3 animations:^{
        
        delegate.game.view.frame = CGRectMake(0, delegate.game.view.frame.origin.y,
                                              self.view.frame.size.width, self.view.frame.size.height);        
        self.view.frame = CGRectMake(delegate.mainView.frame.size.width, self.view.frame.origin.y, 
                                     self.view.frame.size.width, self.view.frame.size.height);        
    }];
}

@end
