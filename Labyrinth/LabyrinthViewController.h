//
//  LabyrinthViewController.h
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabyrinthViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIScrollView *toolBarView;

@end
