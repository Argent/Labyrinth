//
//  LevelsCell.h
//  Labyrinth
//
//  Created by Corina Schemainda on 11.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LevelInfo.h"

@interface LevelsCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView* imgView;
@property (nonatomic, strong) UILabel* label;
@property (nonatomic,strong) LevelInfo *info;

@end
