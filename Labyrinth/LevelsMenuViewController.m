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
#import "SettingsStore.h"
#import "GeometryHelper.h"

@interface LevelsMenuViewController () {
    CGPoint centerPoint;
    UICollectionViewCell* highlightedCell;
    UILabel *levelNameLabel;
    UILabel *highscoreLabel;
    NSMutableArray *levelImages;
}
@end

@implementation LevelsMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.view.backgroundColor = [UIColor darkGrayColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
  //  [self setupDataForCollectionView];
    [self loadImages];
    
   // NSLog(@"view height: %.0f", (self.view.frame.size.height / 2.4));
    float itemHeight = self.view.frame.size.height / 2.4;
    float collViewHeight = self.view.frame.size.height / 2.0;
    
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(itemHeight, itemHeight)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height/2 - collViewHeight/2, self.view.frame.size.width, collViewHeight) collectionViewLayout:flowLayout];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    [self.collectionView registerClass:[LevelsCell class] forCellWithReuseIdentifier:@"LevelsCell"];
    [self.collectionView setContentOffset:CGPointMake(itemHeight, 0)];
    //self.collectionView.pagingEnabled=YES;
    [self.collectionView setShowsHorizontalScrollIndicator:NO];
    self.collectionView.scrollEnabled=YES;
    
    self.collectionView.backgroundColor=[UIColor darkGrayColor];
    
    self.collectionView.delegate=self;
    self.collectionView.dataSource=self;
    [self.view addSubview:self.collectionView];
    
    centerPoint = CGPointMake(self.collectionView.frame.size.width / 2.0, self.collectionView.frame.origin.y + (self.collectionView.frame.size.height / 2.0));

    levelNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.collectionView.frame.origin.y  + collViewHeight , self.collectionView.frame.size.width, 50)];
    [levelNameLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [levelNameLabel setTextColor:[UIColor whiteColor]];
    [levelNameLabel setTextAlignment:NSTextAlignmentCenter];
    [levelNameLabel setText:@"no levels available"];
    [self.view addSubview:levelNameLabel];
 
    highscoreLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.collectionView.frame.origin.y  + collViewHeight + 30 , self.collectionView.frame.size.width, 50)];
    [highscoreLabel setFont:[UIFont systemFontOfSize:18.0]];
    [highscoreLabel setTextColor:[UIColor whiteColor]];
    [highscoreLabel setTextAlignment:NSTextAlignmentCenter];
    [highscoreLabel setText:@""];
    [self.view addSubview:highscoreLabel];
    
    //self.collectionView.h
    
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(15, 15, itemHeight / 5, itemHeight / 5)];
    backButton.backgroundColor = [UIColor colorWithWhite:0.244 alpha:1.000];
    [backButton setImage:[UIImage imageNamed:@"home_button_white.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    backButton.layer.borderWidth = 1.0;
    backButton.layer.borderColor = [[UIColor whiteColor]CGColor];
    [self.view addSubview:backButton];
   
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.startEditor)
         return [self.levels count] + 1;
        else
    return [self.levels count];
}

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
    
    if (cell.info){
        if (self.startEditor)
            cell.imgView.image = levelImages[indexPath.row -1];
        else
            cell.imgView.image = levelImages[indexPath.row];
    }else {
        cell.imgView.image = nil;
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

-(void)viewWillAppear:(BOOL)animated{
    [self loadImages];
    [super viewWillAppear:animated];
}

-(void)loadImages{
    self.levels = [LevelManager sharedManager].levels;
    if (!levelImages)
        levelImages = [NSMutableArray array];
    [levelImages removeAllObjects];
    for (NSDictionary *levelsDic in self.levels) {
        LevelInfo *info = [[LevelInfo alloc]initWithDictionary:levelsDic];
        
        NSArray *array = [self createGridWithSize: CGSizeMake(info.board.count +2 , ((NSArray*)info.board[0]).count +2)];
        [self buildLevel:info withMatrix:array[1]];
        UIImage *img = [self imageWithView:array[0]];
        
        [levelImages addObject:img];
    }
    
    [self.collectionView reloadData];
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *vc = nil;
    
    if (self.startEditor){
        vc = [[LabyrinthEditorViewController alloc]init];
        [(LabyrinthEditorViewController*)vc setHomeBlock:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
        
        if (indexPath.row>0){
            [(LabyrinthEditorViewController*)vc loadAtIndex:(int)indexPath.row];
        } else {
            ((LabyrinthEditorViewController*)vc).levelID=-1;
        }
    }else {
        LevelInfo *levelinfo = [[LevelInfo alloc]initWithDictionary:self.levels[indexPath.row]];
        levelinfo.ID = indexPath.row + 1;
        vc = [[LabyrinthViewController alloc]initWithNibName:nil bundle:nil andLevelInfo:levelinfo];
        [(LabyrinthViewController*)vc setHomeBlock:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
        
    }
   [self presentViewController:vc animated: YES completion:nil];

}



- (UIEdgeInsets)collectionView:
(UICollectionView *)cv layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    float itemHeight = self.view.frame.size.height / 2.4;
    
       return UIEdgeInsetsMake(0,itemHeight / 2, 0, itemHeight / 2);
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

-(NSArray*)createGridWithSize:(CGSize)size{
    float hex_height = [SettingsStore sharedStore].hexSize * 2;
    float hex_width = sqrt(3) / 2.0 * hex_height;
    
    float itemHeight = self.view.frame.size.height / 2.4;
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(1, 1, itemHeight, itemHeight)];
    
    // Custom initialization
    view.backgroundColor = [UIColor whiteColor];
    UIScrollView *scrollView = [[UIScrollView alloc]initWithFrame:view.frame];
    scrollView.backgroundColor = [UIColor blackColor];
    
    scrollView.contentSize = CGSizeMake((hex_width * size.width) - (hex_width/2), hex_height * size.height);
    scrollView.delegate = self;
    scrollView.minimumZoomScale=0.1;
    scrollView.maximumZoomScale=1;
    scrollView.userInteractionEnabled = NO;
    //scrollView.zoomScale = 0.25;
    //[scrollView zoomToRect:CGRectMake(0, 0, 200, 200) animated:NO];
    
    [view addSubview:scrollView];
    
    UIView *containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height)];
    [scrollView addSubview:containerView];
    
    NSArray *matrix = [GeometryHelper generateMatrixWithWidth:size.width Height:size.height withImageName:@"empty.png" inContainerView:containerView];
    
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]) {
                matrix[x][y] = node.uiElement;
            }
        }
    }
    
   // NSLog(@"view: %@", [NSValue valueWithCGRect:view.frame]);
   // NSLog(@"contentsize: %@", [NSValue valueWithCGSize:scrollView.contentSize]);
    
    float zoomScale = view.frame.size.height / scrollView.contentSize.height;
    
    [scrollView setZoomScale:zoomScale animated:NO];
   // [scrollView zoomToRect:CGRectMake(0, 0, 200, 200) animated:NO];
    
    return [NSArray arrayWithObjects:view,matrix, nil];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return scrollView.subviews[0];
}

-(void)buildLevel:(LevelInfo*)info withMatrix:(NSArray*)matrix{
    
    NSMutableArray *board= info.board;
    
    int yOffset = info.minY.intValue % 2 == 0 ? 2 : 1;
    
    //NSLog(@"minY: %i, minY: %i, yOffset: %i",info.minY.intValue, info.minX.intValue, yOffset);
    
    for (int x = 0; x < board.count; x++) {
        for (int y = 0; y <((NSArray*)board[x]).count; y++){
            
            NSNumber *nodeType = board[x][y];
            id obj = matrix[x + 1][y + yOffset];
            
            if ([obj isEqual:[NSNull null]])
                continue;
            
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            node.uiElement = obj;
            
            node.MatrixCoords = CGPointMake(x + 1,y + yOffset);
            node.center = node.uiElement.center;
            
            if(nodeType.intValue == 1){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
            } else if (nodeType.intValue == 4){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_petrol.png"]];
                node.object = [MazeObject objectWithType:END andCenter:CGPointMake(node.center.x, node.center.y)];
            } else if (nodeType.intValue == 3){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_turquoise.png"]];
                node.object = [MazeObject objectWithType:START andCenter:CGPointMake(node.center.x, node.center.y)];
            } else if (nodeType.intValue == 2){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_darkbrown.png"]];
                node.object = [MazeObject objectWithType:FIXEDWALL andCenter:CGPointMake(node.center.x, node.center.y)];
            }else if (nodeType.intValue == 5){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_coin.png"]];
                node.object = [MazeObject objectWithType:COIN andCenter:CGPointMake(node.center.x, node.center.y)];
            }
            
            //NSLog(@"(x:%i,y:%i) = %@", x,y,board[x][y]);
            
            if (nodeType.intValue == 0)
                matrix[x + 1][y + yOffset] = node.uiElement;
            else
                matrix[x + 1][y + yOffset] = node;
        }
    }
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents:scrollView];
}

- (void)centerScrollViewContents:(UIScrollView*)scrollView {
    CGSize boundsSize = scrollView.bounds.size;
    CGRect contentsFrame = ((UIView *)scrollView.subviews[0]).frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    contentsFrame.origin.y += 10;
    contentsFrame.origin.x += 6;
    
    //scrollViewOffset.x = contentsFrame.origin.x;
    //scrollViewOffset.y = contentsFrame.origin.y;
    
    ((UIView *)scrollView.subviews[0]).frame = contentsFrame;
}

- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}



@end
