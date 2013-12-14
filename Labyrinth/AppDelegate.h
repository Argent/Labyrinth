//
//  AppDelegate.h
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LabyrinthViewController.h"
#import "LabyrinthEditorViewController.h"
//#import "EditorViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) LabyrinthViewController *rootViewController;
//@property (nonatomic, strong) LabyrinthEditorViewController *rootViewController;


@end
