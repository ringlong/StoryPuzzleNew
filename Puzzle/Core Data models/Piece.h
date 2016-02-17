//
//  Piece.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image, Puzzle;

@interface Piece : NSManagedObject

@property (nonatomic, retain) NSNumber * angle;
@property (nonatomic, retain) NSNumber * edge0;
@property (nonatomic, retain) NSNumber * edge1;
@property (nonatomic, retain) NSNumber * edge2;
@property (nonatomic, retain) NSNumber * edge3;
@property (nonatomic, retain) NSNumber * isFree;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSNumber * moves;
@property (nonatomic, retain) NSNumber * rotations;
@property (nonatomic, retain) Image *image;
@property (nonatomic, retain) Puzzle *puzzle;


- (BOOL) isFreeScalar;
- (void) setisFreeScalar:(BOOL)isFree_;

@end
