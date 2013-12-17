//
//  UIMazeControl.h
//  Labyrinth
//
//  Created by Benjamin Otto on 29.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MazeObject.h"

@interface UIMazeControl : UIControl <NSCopying>

@property (nonatomic,strong) MazeObject* mazeObject;
@property (nonatomic,strong) UIView *view;


@end
