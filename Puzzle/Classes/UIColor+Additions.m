//
//  UIColor+Additions.m
//  Puzzle
//
//  Created by Vanessa on 15/12/10.
//  Copyright © 2015年 BitAuto. All rights reserved.
//

#import "UIColor+Additions.h"

@implementation UIColor (Additions)

+ (UIColor *)rrYellowColor {
    return [UIColor colorWithRed:1.0 green:200.0/255.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)puzzleBackgroundColor {
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"jeans"]];
}

@end
