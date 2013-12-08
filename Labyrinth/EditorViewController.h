//
//  EditorViewController.h
//  Labyrinth
//
//  Created by Corina Schemainda on 07.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditorViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIScrollView *toolBarView;
@property (nonatomic,strong) UIView *toolBarView2;

@end

