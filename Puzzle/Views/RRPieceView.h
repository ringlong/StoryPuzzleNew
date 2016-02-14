//
//  RRPieceView.h
//  Puzzle
//
//  Created by Ryan on 16/2/6.
//  Copyright © 2016年 Università degli studi di Padova. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RRPieceView : UIView

@property (nonatomic, strong, nullable) NSArray<NSNumber *> *edges;
@property (nonatomic, strong, nullable) NSArray<RRPieceView *> *neighbors;


@end
