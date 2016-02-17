//
//  Piece.m
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import "Piece.h"
#import "Image.h"
#import "Puzzle.h"


@implementation Piece

@dynamic angle;
@dynamic edge0;
@dynamic edge1;
@dynamic edge2;
@dynamic edge3;
@dynamic isFree;
@dynamic number;
@dynamic position;
@dynamic image;
@dynamic puzzle;
@dynamic moves;
@dynamic rotations;


- (BOOL) isFreeScalar {
    return self.isFree.boolValue;
}

- (void) setisFreeScalar:(BOOL)isFree_ {
    self.isFree = [NSNumber numberWithBool:isFree_];
}

@end
