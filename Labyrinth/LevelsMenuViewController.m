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

@interface LevelsMenuViewController () {
    CGPoint centerPoint;
    UICollectionViewCell* highlightedCell;
    UILabel *levelNameLabel;
    UILabel *highscoreLabel;
}
@end

@implementation LevelsMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.levels = [LevelManager sharedManager].levels;
        self.view.backgroundColor = [UIColor darkGrayColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
  //  [self setupDataForCollectionView];
    
  
    
    self.levels = [LevelManager sharedManager].levels;
    
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(200, 200)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height/2 - 120, self.view.frame.size.width, 240) collectionViewLayout:flowLayout];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    [self.collectionView registerClass:[LevelsCell class] forCellWithReuseIdentifier:@"LevelsCell"];
    [self.collectionView setContentOffset:CGPointMake(200, 0)];
    //self.collectionView.pagingEnabled=YES;
    [self.collectionView setShowsHorizontalScrollIndicator:NO];
    self.collectionView.scrollEnabled=YES;
    
    self.collectionView.backgroundColor=[UIColor darkGrayColor];
    
    self.collectionView.delegate=self;
    self.collectionView.dataSource=self;
    [self.view addSubview:self.collectionView];
    
    centerPoint = CGPointMake(self.collectionView.frame.size.width / 2.0, self.collectionView.frame.origin.y + (self.collectionView.frame.size.height / 2.0));

    levelNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.collectionView.frame.origin.y  + 250 , self.collectionView.frame.size.width, 50)];
    [levelNameLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [levelNameLabel setTextColor:[UIColor whiteColor]];
    [levelNameLabel setTextAlignment:NSTextAlignmentCenter];
    [levelNameLabel setText:@"no levels available"];
    [self.view addSubview:levelNameLabel];
 
    highscoreLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.collectionView.frame.origin.y  + 280 , self.collectionView.frame.size.width, 50)];
    [highscoreLabel setFont:[UIFont systemFontOfSize:18.0]];
    [highscoreLabel setTextColor:[UIColor whiteColor]];
    [highscoreLabel setTextAlignment:NSTextAlignmentCenter];
    [highscoreLabel setText:@""];
    [self.view addSubview:highscoreLabel];
    
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
    return [self.levels count]; }

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"LevelsCell";
    
    LevelsCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.info = nil;
    if (self.startEditor){
        if (indexPath.row==0 /*|| indexPath.section==self.dataArray.count-1*/){
            cell.label.text = @"add new";
        } else {
             cell.info = [[LevelInfo alloc]initWithDictionary:self.levels[indexPath.row - 1]];
            cell.label.text = [NSString stringWithFormat:@"%@",[[self.levels objectAtIndex:indexPath.row - 1] objectForKey:@"name"]];
        }
    }else {
        cell.info = [[LevelInfo alloc]initWithDictionary:self.levels[indexPath.row]];
        cell.label.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row] objectForKey:@"name"]];
    }
    
    if (indexPath == [self.collectionView indexPathForItemAtPoint:[self.collectionView convertPoint:centerPoint fromView:nil]]) {
        highlightedCell.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        cell.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        if (cell.info){
            highscoreLabel.text = [NSString stringWithFormat:@"Highscore: %i", cell.info.highScore];
            levelNameLabel.text = cell.info.name;
        }else {
            levelNameLabel.text = @"";
            highscoreLabel.text = @"";
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
        LevelInfo *levelinfo = [[LevelInfo alloc]initWithDictionary:self.levels[indexPath.row]];
        levelinfo.ID = indexPath.row;
        vc = [[LabyrinthViewController alloc]initWithNibName:nil bundle:nil andLevelInfo:levelinfo];
        [(LabyrinthViewController*)vc setHomeBlock:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
        
    }
   [self presentViewController:vc animated: YES completion:nil];

}



- (UIEdgeInsets)collectionView:
(UICollectionView *)cv layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
       return UIEdgeInsetsMake(0,50, 0, 50);
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint relativeCenterPoint = [self.collectionView convertPoint:centerPoint fromView:nil]; // Using nil converts from the window coordinates.
    NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:relativeCenterPoint];
    LevelsCell* cell = (LevelsCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if(cell){
        if (cell.info) {
            levelNameLabel.text = cell.info.name;
            highscoreLabel.text = [NSString stringWithFormat:@"Highscore: %i", cell.info.highScore];
        }else {
            levelNameLabel.text = @"";
            highscoreLabel.text = @"";
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

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [UIView animateWithDuration:0.3 animations:^{
        levelNameLabel.alpha = 0.4;
        highscoreLabel.alpha = 0.4;
    }];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [UIView animateWithDuration:0.3 animations:^{
            levelNameLabel.alpha = 1.0;
            highscoreLabel.alpha = 1.0;
        }];
    }
    
    CGPoint relativeCenterPoint = [self.collectionView convertPoint:centerPoint fromView:nil]; // Using nil converts from the window coordinates.
    NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:relativeCenterPoint];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [UIView animateWithDuration:0.5 animations:^{
        levelNameLabel.alpha = 1.0;
        highscoreLabel.alpha = 1.0;
    }];
}


-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    CGPoint relativeCenterPoint = [self.collectionView convertPoint:centerPoint fromView:nil]; // Using nil converts from the window coordinates.
    NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:relativeCenterPoint];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
}

@end
