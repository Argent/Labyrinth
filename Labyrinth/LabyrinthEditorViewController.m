//
//  LabyrinthEditorViewController.m
//  Labyrinth
//
//  Created by Benjamin Otto on 10.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "LabyrinthEditorViewController.h"
#import "TwoFingerScrollView.h"
#import "MazeNode.h"
#import "SettingsStore.h"
#import "MazeObject.h"
#import "GeometryHelper.h"
#import "LevelManager.h"
#import "LevelInfo.h"

@interface LabyrinthEditorViewController () {
    UIView *containerView;
    NSMutableArray *matrix;
    CGPoint scrollViewOffset;
    CGSize gridSize;
    
    bool paint;
    CGPoint lastPaintCoord;
    
    LevelInfo * levelInfo;
    
    
}
@end

@implementation LabyrinthEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        paint = YES;
        scrollViewOffset = CGPointMake(0.0, 0.0);
        [self initGrid];
        [self initToolbar];
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
        [self.scrollView addGestureRecognizer:singleTap];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureCaptures:)];
        [self.scrollView addGestureRecognizer:panGesture];
        
    }
    return self;
}


-(void)initToolbar{
    int toolbarHeight = 100;
    self.toolBarView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight)];
    self.toolBarView.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
    self.toolBarView.backgroundColor = [UIColor clearColor];
    UIImage *backgroundImg = [UIImage imageNamed:@"toolbar.png"];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:backgroundImg];
    imgView.alpha=0.5;
    imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView.contentSize.width + 200, self.toolBarView.contentSize.height);
    
    [self.toolBarView addSubview:imgView];
    [self.view addSubview:self.toolBarView];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    saveButton.frame=CGRectMake(22, 33, 50,50);
    saveButton.backgroundColor=[UIColor greenColor];
    [saveButton setTitle:@"save" forState:UIControlStateNormal];
    [self.toolBarView addSubview:saveButton];
    
    [saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    loadButton.frame=CGRectMake(340, 33, 50,50);
    loadButton.backgroundColor=[UIColor yellowColor];
    /*loadButton.titleLabel.frame=CGRectMake(0, 0, loadButton.frame.size.height,loadButton.frame.size.width);
    loadButton.titleLabel.font=[UIFont systemFontOfSize:20];
    loadButton.titleLabel.textColor=[UIColor whiteColor];
    loadButton.titleLabel.text = @"speichern";*/
    [loadButton setTitle:@"load" forState:UIControlStateNormal];
    [self.toolBarView addSubview:loadButton];
    
    [loadButton addTarget:self action:@selector(load) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editBoard = [UIButton buttonWithType:UIButtonTypeCustom];
    [editBoard setFrame:CGRectMake(90,33,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editBoard setBackgroundImage:[UIImage imageNamed:@"hex_gray.png"] forState:UIControlStateNormal];
    editBoard.tag=0;
    [self.toolBarView addSubview:editBoard];
    
    [editBoard addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editStart = [UIButton buttonWithType:UIButtonTypeCustom];
    [editStart setFrame:CGRectMake(150,33,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editStart setBackgroundImage:[UIImage imageNamed:@"hex_turquoise.png"] forState:UIControlStateNormal];
     editStart.tag=1;
    [self.toolBarView addSubview:editStart];
    
    [editStart addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editEnd = [UIButton buttonWithType:UIButtonTypeCustom];
    [editEnd setFrame:CGRectMake(210,33,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editEnd setBackgroundImage:[UIImage imageNamed:@"hex_petrol.png"] forState:UIControlStateNormal];
    editEnd.tag=2;
    [self.toolBarView addSubview:editEnd];
    
    [editEnd addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editWalls = [UIButton buttonWithType:UIButtonTypeCustom];
    [editWalls setFrame:CGRectMake(270,33,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editWalls setBackgroundImage:[UIImage imageNamed:@"hex_brown.png"] forState:UIControlStateNormal];
    editWalls.tag=3;
    [self.toolBarView addSubview:editWalls];
    
    [editWalls addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)initGrid{
    float hex_height = [SettingsStore sharedStore].hexSize * 2;
    float hex_width = sqrt(3) / 2.0 * hex_height;
    
    
    gridSize = CGSizeMake(100, 100);
    
    // Custom initialization
    self.view.backgroundColor = [UIColor whiteColor];
    self.scrollView = [[TwoFingerScrollView alloc]initWithFrame:self.view.frame];
    self.scrollView.backgroundColor = [UIColor blackColor];
    
    self.scrollView.contentSize = CGSizeMake((hex_width * gridSize.width) - (hex_width/2), hex_height * gridSize.height);
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale=0.25;
    self.scrollView.maximumZoomScale=1.0;
    
    [self.view addSubview:self.scrollView];
    
    containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    [self.scrollView addSubview:containerView];
    
    matrix = [GeometryHelper generateMatrixWithWidth:gridSize.width Height:gridSize.height withImageName:@"hex_empty.png" inContainerView:containerView];

    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]) {
                matrix[x][y] = node.uiElement;
            }
        }
    }
}

-(void)panGestureCaptures:(UIPanGestureRecognizer *)gesture{
    
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint.x -= scrollViewOffset.x;
    touchPoint.y -= scrollViewOffset.y;
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    CGPoint matrixCoords = [GeometryHelper pixelToHex:touchPoint gridSize:gridSize];
    
    id obj = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    
    if(self.buttonNodeType==0){
    if (![obj isEqual:[NSNull null]]){
        if(gesture.state == UIGestureRecognizerStateBegan){
            //NSLog(@"Gesture started")
            if ([obj isKindOfClass:[UIImageView class]]){
                paint = YES;
            }else if ([obj isKindOfClass:[MazeNode class]]){
                paint = NO;
            }
        }
        if (!(lastPaintCoord.x == matrixCoords.x && lastPaintCoord.y == matrixCoords.y)) {
            if (paint){
                
                MazeNode *node = [MazeNode node];
                node.Size = [SettingsStore sharedStore].hexSize;
                
                if ([obj isKindOfClass:[UIImageView class]]){
                    
                    MazeNode *node = [MazeNode node];
                    node.Size = [SettingsStore sharedStore].hexSize;
                    node.uiElement = obj;
                    node.center = node.uiElement.center;
                    node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
                
                    
                    [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                    
                    matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
                
                  }else if ([obj isKindOfClass:[MazeNode class]]) {
                
                    node=obj;
                      
                    //if (!node.isStart && !node.isWall && !node.isEnd){
                    node.object=nil;
                    
                    UIImageView *imgView = (UIImageView*)((MazeNode*)obj).uiElement;
                    [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
                    matrix[(int)matrixCoords.x][(int)matrixCoords.y] = imgView;
                     // }
                    }
            
                }
        }}}
           if (self.buttonNodeType==3){
               
               if (![obj isEqual:[NSNull null]]){
                   if(gesture.state == UIGestureRecognizerStateBegan){
                       //NSLog(@"Gesture started")
                       if ([obj isKindOfClass:[UIImageView class]]){
                           paint = NO;
                       }else if ([obj isKindOfClass:[MazeNode class]]){
                           paint = YES;
                       }
                   }
                   if (!(lastPaintCoord.x == matrixCoords.x && lastPaintCoord.y == matrixCoords.y)) {
                       if (paint){
                           
                           MazeNode *node = [MazeNode node];
                           node.Size = [SettingsStore sharedStore].hexSize;
                           
                           if ([obj isKindOfClass:[MazeNode class]]) {
                            
                               MazeNode* node = obj;
                               
                               if (!node.isStart && !node.isEnd && !node.isWall){
                               
                               MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
                               node.object = wall;
                               
                               [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_brown.png"]];
                               
                               matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
                               }
                               
                               else if(node.isWall){
                               
                               node.object=nil;
                               
                               UIImageView *imgView = (UIImageView*)((MazeNode*)node).uiElement;
                               [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                                matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;}
                               
                              
                           }
                           
                       }
                   }}}

                 /*   if ([obj isKindOfClass:[MazeNode class]]){
                        
                        node.uiElement = obj;
                        node.center = node.uiElement.center;
                        node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
                    
                    [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_brown.png"]];
                    
                    MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
                    node.object = wall;
                    matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
                    }
                    
                }*/
                
    
            //NSLog(@"(%.2f,%.2f)", newCoord.x,newCoord.y);

    
    lastPaintCoord = matrixCoords;
}


- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint.x -= scrollViewOffset.x;
    touchPoint.y -= scrollViewOffset.y;
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    
    //NSLog(@"Touch Point: (x:%.2f,y:%.2f)", touchPoint.x, touchPoint.y);
    
    CGPoint matrixCoords = [GeometryHelper pixelToHex:touchPoint gridSize:gridSize];
    //NSLog(@"Touch Matrix: (x:%.2f,y:%.2f)", matrixCoords.x, matrixCoords.y);
    
    //CGPoint pixelCoords = [GeometryHelper hexToPixel:matrixCoords];
    // NSLog(@"Touch Point calculated: (x:%.2f,y:%.2f)", pixelCoords.x, pixelCoords.y);
    
    id obj = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
   if (![obj isEqual:[NSNull null]]) {
    
    if (self.buttonNodeType==0) {
        
        if ([obj isKindOfClass:[UIImageView class]]){
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            node.uiElement = obj;
            node.center = node.uiElement.center;
            node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
            
            [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
            
            matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
        }

            else if ([obj isKindOfClass:[MazeNode class]]){
          
            
            UIImageView *imgView = (UIImageView*)((MazeNode*)obj).uiElement;
            [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
            matrix[(int)matrixCoords.x][(int)matrixCoords.y] = imgView;
            
        }
   }
       
       
      if (self.buttonNodeType==1) {
          if ([obj isKindOfClass:[MazeNode class]]){
              MazeNode *touched = (MazeNode *)obj;
        
              
              if (touched.isStart){
                  touched.object=Nil;
                  
                  UIImageView *imgView = (UIImageView*)((MazeNode*)touched).uiElement;
                  [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                  matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                  
              }
              
              
              else {
              
              [((UIImageView*)touched.uiElement) setImage:[UIImage imageNamed:@"hex_turquoise.png"]];
              
              MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(touched.center.x, touched.center.y)];
              touched.object = start;
              matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
              }
          
          }}
       if (self.buttonNodeType==2) {
           if ([obj isKindOfClass:[MazeNode class]]){
               MazeNode *touched = (MazeNode *)obj;
               
               
               if (touched.isEnd){
                   touched.object=Nil;
                   
                   UIImageView *imgView = (UIImageView*)((MazeNode*)touched).uiElement;
                   [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                   matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                   
               }
               
               else {
                   
                   [((UIImageView*)touched.uiElement) setImage:[UIImage imageNamed:@"hex_petrol.png"]];
                   
                   MazeObject *end = [MazeObject objectWithType:END andCenter:CGPointMake(touched.center.x, touched.center.y)];
                   touched.object = end;
                   matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                   
               }
               
           }}

       if (self.buttonNodeType==3) {
           if ([obj isKindOfClass:[MazeNode class]]){
               MazeNode *touched = (MazeNode *)obj;
               
               
               if (touched.isWall){
                   touched.object=Nil;
                   
                   UIImageView *imgView = (UIImageView*)((MazeNode*)touched).uiElement;
                   [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                   matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                   
               }
               
               else {
                   
                   [((UIImageView*)touched.uiElement) setImage:[UIImage imageNamed:@"hex_brown.png"]];
                   
                   MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(touched.center.x, touched.center.y)];
                   touched.object = wall;
                   matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                   
               }
               
           }}
      }}
                                    
                                   
        
        //NSLog(@"Touch Node Center: (x:%.2f,y:%.2f)", node.center.x, node.center.y);
        
        
        
            /*
             MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
             MazeNode *nn = [wall generateAndAddNodeRelative:CGPointMake(0,0)];
             [self addDragEventsToNode:nn];
             node.object = wall;
             [containerView addSubview:wall.containerView];
             */
        
   
    
        //NSLog(@"Touch GenNode Center: (x:%.2f,y:%.2f)", nn.uiElement.center.x, nn.uiElement.center.y);
        //NSLog(@"Touch Container Center: (x:%.2f,y:%.2f)", start.containerView.center.x, start.containerView.center.y);
        //NSLog(@"Touch Container Frame: (x:%.2f,y:%.2f,width:%.2f,height:%.2f)", start.containerView.frame.origin.x, start.containerView.frame.origin.y, start.containerView.frame.size.width, start.containerView.frame.size.height);
        
        /*
         NSArray *neighbours =  [GeometryHelper getNeighboursFrom:matrixCoords GridSize:gridSize];
         for (NSValue *neighbour in neighbours) {
         CGPoint coords = [neighbour CGPointValue];
         MazeNode *node = matrix[(int)coords.x][(int)coords.y];
         if (![node isEqual:[NSNull null]]) {
         [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_red.png"]];
         };
         }*/
    


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return containerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents];
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = containerView.frame;
    
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
    
    scrollViewOffset.x = contentsFrame.origin.x;
    scrollViewOffset.y = contentsFrame.origin.y;
    
    containerView.frame = contentsFrame;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)save{
    LevelInfo *info=[[LevelInfo alloc]initWithStart:CGPointZero end:CGPointZero matrix:matrix walls:nil];
    
    NSLog(@"info: %i", info.board.count );
    
    [[LevelManager sharedManager] saveLevel:info forID:0];
    
}

-(void)load{
    LevelManager *manager =[LevelManager sharedManager];
    NSMutableArray *allLevels = manager.levels;
    
    if (allLevels.count>0){
    LevelInfo *info2=[[LevelInfo alloc]initWithDictionary:allLevels[0]];
    NSLog(@"info2: %i", info2.board.count);
    
    levelInfo = info2;
        
    [self cleanScreen];
    [self buildBoard:info2];
        
    }
    else  NSLog(@"Fehler");
    
    
}


-(void)nodeTypeChoosen:(UIButton*) nodeType {
    
    self.buttonNodeType=nodeType.tag;
   
    
}

-(void)cleanScreen{
  
//bildschirm leeren
    
    for (int x = 0; x < gridSize.height; x++) {
        for (int y = 0; y < gridSize.width; y++){
           
            id node = matrix[x][y];
            
            if ([node isKindOfClass:[MazeNode class]]){
                
                MazeNode *node2 = (MazeNode*)node;
                node2.object=nil;
                UIImageView *imgView = (UIImageView*)((MazeNode*)node2).uiElement;
                [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
                matrix[x][y] = imgView;

            }
        }
    }

}

-(void)buildBoard:(LevelInfo*) info{
    
    
    NSInteger ab=[info.minX integerValue];
    NSLog(@"ab:%ld",(long)ab);
    
   
    NSMutableArray *board= info.board;

    
    for (int x = 0; x < board.count; x++) {
        NSInteger bc=[info.minY integerValue];
        for (int y = 0; y <((NSArray*)board[x]).count; y++){
            
            NSNumber *nodeType=board[x][y];
            id obj = matrix[ab][bc];
            
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            node.uiElement = obj;
            
            
            if(nodeType == [NSNumber numberWithInteger:1]){
                
                node.MatrixCoords = CGPointMake(x,y);
                node.center = node.uiElement.center;
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                
               
            }
        
            else if (nodeType==[NSNumber numberWithInteger:4]){
                
                node.center = node.uiElement.center;
                node.MatrixCoords = CGPointMake(x,y);
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_petrol.png"]];
                
                MazeObject *end = [MazeObject objectWithType:END andCenter:CGPointMake(node.center.x, node.center.y)];
                node.object = end;
                }
            
            else if (nodeType==[NSNumber numberWithInteger:3]){
                
                node.center = node.uiElement.center;
                node.MatrixCoords = CGPointMake(x,y);
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_turquoise.png"]];
                
                MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(node.center.x, node.center.y)];
                node.object = start;
            }
            
            else if (nodeType==[NSNumber numberWithInteger:2]){
                
                node.center = node.uiElement.center;
                node.MatrixCoords = CGPointMake(x,y);
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_brown.png"]];
                
                MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
                node.object = wall;
            }
            
            matrix[ab][bc] = node;
            bc++;
            
        }
      ab++;
        
        
    }
}

@end
