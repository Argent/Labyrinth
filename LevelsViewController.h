//
//  LevelsViewController.h
//  Labyrinth
//
//  Created by Corina Schemainda on 04.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LevelsViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray* levels;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
