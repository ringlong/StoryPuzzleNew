//
//  AppDelegate.h
//  Puzzle
//
//  Created by Andrea Barbon on 19/04/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
//

@import UIKit;

@class PuzzleController, CreatePuzzleOperation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, assign) BOOL wasOpened;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) PuzzleController *puzzle;
@property (nonatomic, strong) CreatePuzzleOperation *puzzleOperation;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSOperationQueue *operationQueue;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;



@end
