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
    
    [[self.startGameButton layer] setBorderWidth:2.0f];
    [[self.startGameButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    [[self.editorButton layer] setBorderWidth:2.0f];
    [[self.editorButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startGameButtonPressed:(UIButton *)sender {
    LabyrinthViewController *vc = [[LabyrinthViewController alloc]initWithNibName:nil bundle:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)editorButtonPressed:(UIButton *)sender {
    LabyrinthEditorViewController *vc = [[LabyrinthEditorViewController alloc]initWithNibName:nil bundle:nil];
    [self presentViewController:vc animated:YES completion:nil];
}
@end
