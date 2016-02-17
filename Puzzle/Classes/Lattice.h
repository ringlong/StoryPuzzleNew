//
//  Lattice.h
//  Puzzle
//
//  Created by Ryan on 16/2/3.
//  Copyright © 2016年 BitAuto. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PieceView;
@protocol LatticeDelegate

@end

@interface Lattice : UIView {
    NSInteger n;
}

@property (nonatomic, assign) UIViewController *delegate;
@property (nonatomic, retain) NSArray<PieceView *> *pieces;
@property (nonatomic) float scale;

- (void)initWithFrame:(CGRect)frame withNumber:(NSInteger)n withDelegate:(id)delegate;
- (id)objectAtIndex:(NSInteger)i;

@end
