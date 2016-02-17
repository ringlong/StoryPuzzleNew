//
//  Lattice.m
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import "Lattice.h"
#import "PuzzleController.h"
#import <QuartzCore/QuartzCore.h>

@implementation Lattice

@synthesize delegate, scale, pieces;

- (void)initWithFrame:(CGRect)frame withNumber:(NSInteger)n_ withDelegate:(id)delegate_ {
    
    n = n_;
    
    self.delegate = delegate_;
    
    scale = 1;
    float w = frame.size.width / n;
    
    NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:n^2];
            
    for (int i = 0; i < 3 * n; i++) {
        for (int j = 0; j < 3 * n; j++) {
            
            float panning = 2.0;
            
            CGRect rect = CGRectMake(i * w - panning, j * w - panning, w - 2 * panning, w - 2 * panning);
            UIView *v = [[UIView alloc] initWithFrame:rect];
            
            v.backgroundColor = [UIColor blackColor];

            if ( i >= n && i < 2 * n && j >= n && j < 2 * n ) {
                v.alpha = .3;
                
            } else {
                v.alpha = .1;
            }
            
            [a addObject:v];
            [self addSubview:v];
        }
    }

    pieces = [NSArray arrayWithArray:a];
        
}




- (id)objectAtIndex:(NSInteger)i {
    
    if (i < 0 || i > n * n * 9 - 1) {
        DLog(@"%d is out of bounds", i);
        return nil;
    }
    
    return [pieces objectAtIndex:i];
}

@end
