//
//  TestMenuViewController.h
//  Labyrinth
//
//  Created by Corina Schemainda on 07.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestMenuViewController : UIViewController {

IBOutlet UILabel *label;
IBOutlet UILabel *label2;

IBOutlet UIButton *play;
IBOutlet UIButton *editor;
    

}

-(IBAction)pressPlay;
-(IBAction)pressEditor;


@end
