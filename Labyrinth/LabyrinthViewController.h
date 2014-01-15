//
//  LabyrinthViewController.h
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LevelInfo;

@interface LabyrinthViewController : UIViewController <UIScrollViewDelegate>

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andLevelInfo:(LevelInfo*)levelinfo;

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIView *toolBarView;

@property (nonatomic, strong) void(^homeBlock)(void);

@end
