//
//  Lattice.h
//  Puzzle
//
//  Created by Andrea Barbon on 22/04/12.
//  Copyright (c) 2012 Università degli studi di Padova. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LatticeDelegate

@end

@interface Lattice : UIView {
    NSInteger n;
}

@property (nonatomic, assign) UIViewController *delegate;
@property (nonatomic, retain) NSArray *pieces;
@property (nonatomic) float scale;

- (void)initWithFrame:(CGRect)frame withNumber:(NSInteger)n withDelegate:(id)delegate;
- (id)objectAtIndex:(NSInteger)i;

@end
