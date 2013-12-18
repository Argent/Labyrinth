//
//  StartMenuViewController.h
//  Labyrinth
//
//  Created by Benjamin Otto on 18.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartMenuViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *startGameButton;
@property (weak, nonatomic) IBOutlet UIButton *editorButton;
- (IBAction)startGameButtonPressed:(UIButton *)sender;
- (IBAction)editorButtonPressed:(UIButton *)sender;

@end
