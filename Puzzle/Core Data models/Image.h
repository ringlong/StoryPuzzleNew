//
//  Image.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

@import Foundation;
@import CoreData;

@class Piece, Puzzle;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) Piece *piece;
@property (nonatomic, retain) Puzzle *puzzle;

@end
