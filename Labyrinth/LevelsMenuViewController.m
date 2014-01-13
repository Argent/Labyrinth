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
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *levels;
@property (nonatomic, strong) NSMutableArray* dataArray;




@end

@implementation LevelsMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
       
        
        LevelManager *manager =[LevelManager sharedManager];
        self.levels = manager.levels;
       //[self setupDataForCollectionView];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
  //  [self setupDataForCollectionView];
    
  
     
    LevelManager *manager =[LevelManager sharedManager];
    self.levels = manager.levels;
    
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(100, 100)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, 200) collectionViewLayout:flowLayout];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    [self.collectionView registerClass:[LevelsCell class] forCellWithReuseIdentifier:@"LevelsCell"];
    [self.collectionView setContentOffset:CGPointMake(100, 0)];
    self.collectionView.pagingEnabled=YES;
    [self.collectionView setShowsHorizontalScrollIndicator:NO];
    self.collectionView.scrollEnabled=YES;
    
    self.collectionView.backgroundColor=[UIColor darkGrayColor];
    
    self.collectionView.delegate=self;
    self.collectionView.dataSource=self;
    [self.view addSubview:self.collectionView];
    

 
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
   
    
    if (self.startEditor){
        if (indexPath.row==0 /*|| indexPath.section==self.dataArray.count-1*/){
            cell.label.text = @"add new";
        } else {
            cell.label.text = [NSString stringWithFormat:@"%@",[[self.levels objectAtIndex:indexPath.row - 1] objectForKey:@"name"]];
        }
    }else {
        cell.label.text = [NSString stringWithFormat:@"%@", [[self.levels objectAtIndex:indexPath.row] objectForKey:@"name"]];
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



/*- (UIEdgeInsets)collectionView:
(UICollectionView *)cv layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
       return UIEdgeInsetsMake(0,50, 0, 20);
}*/
/*-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    CGPoint point = self.collectionView.contentOffset;
    
    float newPoint = point.x/self.collectionView.frame.size.width;
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:newPoint inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    
    
    
    
    
}*/

@end
