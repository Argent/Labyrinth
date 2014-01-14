//
//  StartMenuViewController.m
//  Labyrinth
//
//  Created by Benjamin Otto on 18.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "StartMenuViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LabyrinthEditorViewController.h"
#import "LabyrinthViewController.h"
#import "LevelsViewController.h"
#import "LevelsMenuViewController.h"

@interface StartMenuViewController ()

@end

@implementation StartMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    } else {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
    
    [[self.startGameButton layer] setBorderWidth:2.0f];
    [[self.startGameButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    [[self.editorButton layer] setBorderWidth:2.0f];
    [[self.editorButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startGameButtonPressed:(UIButton *)sender {
    //LevelsViewController *vc = [[LevelsViewController alloc]initWithNibName:nil bundle:nil];
   LevelsMenuViewController *vc = [[LevelsMenuViewController alloc]initWithNibName:nil bundle:nil];
    vc.startEditor = NO;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)editorButtonPressed:(UIButton *)sender {
   //LevelsViewController *vc = [[LevelsViewController alloc]initWithNibName:nil bundle:nil];
     LevelsMenuViewController *vc = [[LevelsMenuViewController alloc]initWithNibName:nil bundle:nil];
    vc.startEditor = YES;
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}
@end
