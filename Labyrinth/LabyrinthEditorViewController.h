//
//  LabyrinthEditorViewController.h
//  Labyrinth
//
//  Created by Benjamin Otto on 10.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabyrinthEditorViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIScrollView *toolBarView;
@property (nonatomic,strong) UIScrollView *toolBarView2;
@property (nonatomic,strong) UIScrollView *scrollView2;
@property (nonatomic) int buttonNodeType;
@property (nonatomic,strong) NSMutableArray* wallList;
@property (nonatomic) int levelID;
//@property (nonatomic, strong) LevelInfo *levelInfo;

-(void)loadAtIndex:(int)index;
-(IBAction)showActionSheet:(id)sender;
@property (nonatomic, strong) void(^homeBlock)(void);


@end
