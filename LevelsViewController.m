//
//  LevelsViewController.m
//  Labyrinth
//
//  Created by Corina Schemainda on 04.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import "LevelsViewController.h"

#import "LevelManager.h"
#import "LevelInfo.h"
#import "LabyrinthEditorViewController.h"

@interface LevelsViewController ()


@end

@implementation LevelsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    LevelManager *manager =[LevelManager sharedManager];
    self.levels = manager.levels;
    
}

- (void)viewDidAppear:(BOOL)animated  {
        
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    }


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.levels.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    if (indexPath.row==0){
        cell.textLabel.text = @"add new";
    }
    else{
    
        cell.textLabel.text = [NSString stringWithFormat:@"%i. %@", indexPath.row, [[self.levels objectAtIndex:indexPath.row - 1] objectForKey:@"name"]];
        //NSLog(@"name beim laden:%@",[[self.levels objectAtIndex:indexPath.row - 1] objectForKey:@"name"]);
        
        
    }
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) return YES;
    return NO;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LabyrinthEditorViewController *vc= [[LabyrinthEditorViewController alloc]init];
    [vc setHomeBlock:^{
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
    if (indexPath.row>0){
        [vc loadAtIndex:indexPath.row];
    }
    
    else {
        vc.levelID=-1;
    }
    
    [self presentViewController:vc animated: YES completion:nil];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row>0){
            
        [[LevelManager sharedManager] saveLevel:nil forID:indexPath.row-1];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
            
        }   }
   // else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   // }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */



@end
