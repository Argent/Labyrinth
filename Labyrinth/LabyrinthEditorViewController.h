//
//  LabyrinthEditorViewController.h
//  Labyrinth
//
//  Created by Benjamin Otto on 10.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabyrinthEditorViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIScrollView *toolBarView;
@property (nonatomic) int buttonNodeType;


@end
