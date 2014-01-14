//
//  LevelsMenuViewController.m
//  Labyrinth
//
//  Created by Corina Schemainda on 11.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import "LevelsMenuViewController.h"
#import "LevelManager.h"
#import "LevelInfo.h"
#import "LevelsCell.h"
#import "LabyrinthViewController.h"
#import "LabyrinthEditorViewController.h"

@interface LevelsMenuViewController ()
{
LevelsCell* highlightedCell;
UILabel* currentGameLabel;
UILabel* currentHighscoreLabel;
}

@end

@implementation LevelsMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
       // LevelManager *manager =[LevelManager sharedManager];
       // self.levels = manager.levels;
     
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
  
     
    LevelManager *manager =[LevelManager sharedManager];
    self.levels = manager.levels;
    
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(100, 100)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height/2-100, self.view.frame.size.width, 200) collectionViewLayout:flowLayout];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    [self.collectionView registerClass:[LevelsCell class] forCellWithReuseIdentifier:@"LevelsCell"];
    [self.collectionView setContentOffset:CGPointMake(0,100)];
    self.collectionView.pagingEnabled=NO;
    [self.collectionView setShowsHorizontalScrollIndicator:NO];
    self.collectionView.scrollEnabled=YES;
    
    self.collectionView.backgroundColor=[UIColor darkGrayColor];
    self.view.backgroundColor = [UIColor darkGrayColor];
    
    self.collectionView.delegate=self;
    self.collectionView.dataSource=self;
    [self.view addSubview:self.collectionView];
    
    currentGameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height/2+60, self.view.frame.size.width,30)];
    
    currentGameLabel.textColor=[UIColor whiteColor];
    currentGameLabel.textAlignment=NSTextAlignmentCenter;
    
    currentHighscoreLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height/2+90, self.view.frame.size.width,30)];
    currentHighscoreLabel.textColor=[UIColor whiteColor];
    currentHighscoreLabel.textAlignment=NSTextAlignmentCenter;
    currentHighscoreLabel.text=@"Highscore Platzhalter";

    
    [self.view addSubview: currentGameLabel];
    [self.view addSubview: currentHighscoreLabel];
    
    

 
    //self.collectionView.h
    
   
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.levels count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

      static NSString *cellIdentifier = @"LevelsCell";
        
    LevelsCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
   
    
    if (self.startEditor){
        if (indexPath.row==0){
            cell.label.text = @"add new";
        } else {
            cell.label.text = [NSString stringWithFormat:@"%@",[[self.levels objectAtIndex:indexPath.row - 1] objectForKey:@"name"]];
        }
    }else {
        cell.label.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row] objectForKey:@"name"]];
    }
    
    if (indexPath == [collectionView indexPathForItemAtPoint:[collectionView convertPoint:CGPointMake(self.view.frame.size.width/2,self.view.frame.size.height/2) fromView:nil]]) {
        highlightedCell.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        cell.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
        
        if (!self.startEditor){
        currentGameLabel.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row] objectForKey:@"name"]];
        }
        else {
        currentGameLabel.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row-1] objectForKey:@"name"]];
            
        }
       highlightedCell = cell;
    }
    
    return cell;
    
    }



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *vc = nil;
    
    if (self.startEditor){
        vc = [[LabyrinthEditorViewController alloc]init];
        [(LabyrinthEditorViewController*)vc setHomeBlock:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
        
        if (indexPath.row>0){
            [(LabyrinthEditorViewController*)vc loadAtIndex:indexPath.row];
        } else {
            ((LabyrinthEditorViewController*)vc).levelID=-1;
        }
    }else {
        vc = [[LabyrinthViewController alloc]initWithNibName:nil bundle:nil andLevelInfo:[[LevelInfo alloc]initWithDictionary:self.levels[indexPath.row]] ];
        [(LabyrinthViewController*)vc setHomeBlock:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
        
    }
   [self presentViewController:vc animated: YES completion:nil];

}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint relativeCenterPoint = [self.collectionView convertPoint:CGPointMake(self.view.frame.size.width/2,self.view.frame.size.height/2) fromView:nil]; // Using nil converts from the window coordinates.
    
    NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:relativeCenterPoint];
    LevelsCell* cell = (LevelsCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if(cell){
        if (!self.startEditor){
            currentGameLabel.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row] objectForKey:@"name"]];
        }
        else {
            currentGameLabel.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row-1] objectForKey:@"name"]];
        }
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations: ^{
                             highlightedCell.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                             cell.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                             highlightedCell = cell;
                         }
                         completion:^(BOOL finished) {
                         }];
    }
}

@end
