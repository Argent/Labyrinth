//
//  UILabyrinthMenu.h
//  Labyrinth
//
//  Created by Benjamin Otto on 16.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabyrinthMenu : UIView

@property (strong, nonatomic) UIButton* startButton;
@property (strong, nonatomic) UIButton* stopButton;
@property (nonatomic) int steps;
@property (nonatomic) int coins;

@property (nonatomic, strong) void(^startPauseBlock)(bool);
@property (nonatomic, strong) void(^stopBlock)(void);

@end
