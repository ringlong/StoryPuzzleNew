//
//  CreatePuzzleOperation.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CreatePuzzleOperation, PuzzleController;

// Protocol for the importer to communicate with its delegate.
@protocol CreatePuzzleDelegate <NSObject>

@optional
// Notification posted by NSManagedObjectContext when saved.
- (void)puzzleDidSave:(NSNotification *)saveNotification;
// Called by the importer when parsing is finished.
- (void)puzzleDidFinishParsingData:(CreatePuzzleOperation *)importer;
// Called by the importer in the case of an error.
- (void)puzzle:(CreatePuzzleOperation *)importer didFailWithError:(NSError *)error;

@end


@interface CreatePuzzleOperation : NSOperation {
    
    UIImage *image;
}

@property (strong, nonatomic) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign) PuzzleController *delegate;

@property (nonatomic) BOOL loadingGame;


@end
