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
    NSString *name;
    CGPoint scrollViewOffset;
    CGSize gridSize;
    
    bool paint;
    CGPoint lastPaintCoord;
    
    bool hasStart;
    bool hasEnd;
    
    LevelInfo * levelInfo;
    
    NSMutableArray *toolbarItemsLabel;
    NSMutableArray *objCounts;
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
        [self initToolbarBottom];
        [self initToolbarTop];
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
        [self.scrollView addGestureRecognizer:singleTap];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureCaptures:)];
        [self.scrollView addGestureRecognizer:panGesture];
        
    }
    return self;
}
-(void)initToolbars:(bool)top{
    int yPosition = 0;
    int toolbarHeight = 100;
    if(!top){
        yPosition = self.view.frame.size.height - toolbarHeight;
        self.toolBarView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, yPosition, self.view.frame.size.width, toolbarHeight)];
        self.toolBarView.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
        self.toolBarView.backgroundColor = [UIColor clearColor];
    }else{
        self.toolBarView2 = [[UIScrollView alloc]initWithFrame:CGRectMake(0, yPosition, self.view.frame.size.width, toolbarHeight)];
        self.toolBarView2.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
        self.toolBarView2.backgroundColor = [UIColor clearColor];
    }
    UIImage *backgroundImg = [UIImage imageNamed:@"toolbar.png"];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:backgroundImg];
    imgView.alpha=0.5;
    imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView.contentSize.width + 200, self.toolBarView.contentSize.height);
    if(top){
        imgView.transform = CGAffineTransformMakeRotation(M_PI);
        [self.toolBarView2 addSubview:imgView];
        [self.view addSubview:self.toolBarView2];
    }else{
        [self.toolBarView addSubview:imgView];
        [self.view addSubview:self.toolBarView];
    }
}
-(void)initToolbarTop{
    [self initToolbars:YES];
    NSMutableArray *wallNodes = [NSMutableArray array];
    NSMutableArray *objNodes = [NSMutableArray array];
    MazeObject *obj1 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(-1,1)]];
    [wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(0,1)]];
    //[wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(-1,2)]];
    [objNodes addObject:obj1];
    MazeObject *obj2 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj2 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj2 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj2 generateAndAddNodeRelative:CGPointMake(0,2)]];
    [objNodes addObject:obj2];
    MazeObject *obj3 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(1,0)]];
    [objNodes addObject:obj3];
    MazeObject *obj4 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj4 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj4 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj4 generateAndAddNodeRelative:CGPointMake(-1,2)]];
    [objNodes addObject:obj4];
    for (MazeObject* objects in objNodes) {
        [GeometryHelper scaleToToolbar:objects withLength:@"height"];
        [GeometryHelper scaleToToolbar:objects withLength:@"width"];
    }
    NSMutableArray *toolbarItems = [NSMutableArray array];
    toolbarItemsLabel = [NSMutableArray array];
    objCounts = [NSMutableArray array];
    int itemSize = [SettingsStore sharedStore].toolbarHeight-30;
    for(int i = 0; i < 4; i++){
        objCounts[i] = [NSNumber numberWithInt:0];
        
        toolbarItems[i] = [[UIView alloc] initWithFrame:CGRectMake(10+i*(itemSize+10), self.toolBarView2.frame.size.height/2-itemSize/2-10, itemSize, itemSize)];
        [((UIView*)toolbarItems[i]).layer setBorderWidth:1.0];
        [((UIView*)toolbarItems[i]).layer setBorderColor:[UIColor blackColor].CGColor];
        [self.toolBarView2 addSubview:toolbarItems[i]];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        UIButton *plus = [[UIButton alloc]initWithFrame:CGRectMake(0, ((UIView*)toolbarItems[i]).frame.size.height-15, 15, 15)];
        UIButton *minus = [[UIButton alloc]initWithFrame:CGRectMake(((UIView*)toolbarItems[i]).frame.size.width-15,((UIView*)toolbarItems[i]).frame.size.height-15, 15, 15)];
        plus.tag = i+4;
        minus.tag = i+4;
        [label setBackgroundColor:[UIColor blackColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setFont:[UIFont boldSystemFontOfSize:12]];
        label.textAlignment = NSTextAlignmentCenter;
        ((MazeObject*) objNodes[i]).containerView.center = CGPointMake(((UIView*)toolbarItems[i]).frame.size.width/2+10+i*(itemSize+10), ((UIView*)toolbarItems[i]).frame.size.height/2+self.toolBarView.frame.size.height/2-itemSize/2-10);
        [label setText:[NSString stringWithFormat:@"1"]];
        [toolbarItemsLabel addObject:label];
        [((UIView*)toolbarItems[i]) addSubview:label];
        [plus setBackgroundColor:[UIColor blackColor]];
        [plus setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [plus setTitle:@"+" forState:UIControlStateNormal];
        [plus addTarget:self action:@selector(plusObjects:) forControlEvents:UIControlEventTouchUpInside];
        [((UIView*)toolbarItems[i]) addSubview:plus];
        [minus setBackgroundColor:[UIColor blackColor]];
        [minus setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [minus setTitle:@"-" forState:UIControlStateNormal];
        [((UIView*)toolbarItems[i]) addSubview:minus];
        [minus addTarget:self action:@selector(minusObjects:) forControlEvents:UIControlEventTouchUpInside];    }

    [self.toolBarView2 addSubview:obj1.containerView];
    [self.toolBarView2 addSubview:obj2.containerView];
    [self.toolBarView2 addSubview:obj3.containerView];
    [self.toolBarView2 addSubview:obj4.containerView];
}
-(void)plusObjects:(UIButton*) plusMinusType {
    [self plusMinusObjects:YES andType:plusMinusType];
}
-(void)minusObjects:(UIButton*) plusMinusType {
    [self plusMinusObjects:NO andType:plusMinusType];
}
-(void)plusMinusObjects:(bool)plus andType:(UIButton*) buttonType {
    for(int i = 4; i < 9; i++){
        if(buttonType.tag == i){
            int tmpCount = [((UILabel*)toolbarItemsLabel[i-4]).text intValue];
            if(!plus && tmpCount > 0){
                [(UILabel*)toolbarItemsLabel[i-4] setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:tmpCount-1]]];
            }else if (plus){
                [(UILabel*)toolbarItemsLabel[i-4] setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:tmpCount+1]]];
            }
        }
    }
}
-(void)initToolbarBottom{
    [self initToolbars:NO];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    saveButton.frame=CGRectMake(22, 25, 50,24);
    saveButton.backgroundColor=[UIColor greenColor];
    [saveButton setTitle:@"save" forState:UIControlStateNormal];
    [self.toolBarView addSubview:saveButton];
    
    [saveButton addTarget:self action:@selector(alertOverwrite) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cleanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cleanButton.frame=CGRectMake(22, 50, 50,24);
    cleanButton.backgroundColor=[UIColor greenColor];
    [cleanButton setTitle:@"clean" forState:UIControlStateNormal];
    [self.toolBarView addSubview:cleanButton];
    
    [cleanButton addTarget:self action:@selector(cleanScreen) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    loadButton.frame=CGRectMake(90, 25, 50,50);
    loadButton.backgroundColor=[UIColor yellowColor];
    /*loadButton.titleLabel.frame=CGRectMake(0, 0, loadButton.frame.size.height,loadButton.frame.size.width);
     loadButton.titleLabel.font=[UIFont systemFontOfSize:20];
     loadButton.titleLabel.textColor=[UIColor whiteColor];
     loadButton.titleLabel.text = @"speichern";*/
    [loadButton setTitle:@"load" forState:UIControlStateNormal];
    [self.toolBarView addSubview:loadButton];
    
    [loadButton addTarget:self action:@selector(levelsView) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editBoard = [UIButton buttonWithType:UIButtonTypeCustom];
    [editBoard setFrame:CGRectMake(150,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editBoard setBackgroundImage:[UIImage imageNamed:@"hex_gray.png"] forState:UIControlStateNormal];
    editBoard.tag=0;
    [self.toolBarView addSubview:editBoard];
    
    [editBoard addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editStart = [UIButton buttonWithType:UIButtonTypeCustom];
    [editStart setFrame:CGRectMake(210,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editStart setBackgroundImage:[UIImage imageNamed:@"hex_turquoise.png"] forState:UIControlStateNormal];
    editStart.tag=1;
    [self.toolBarView addSubview:editStart];
    
    [editStart addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editEnd = [UIButton buttonWithType:UIButtonTypeCustom];
    [editEnd setFrame:CGRectMake(270,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editEnd setBackgroundImage:[UIImage imageNamed:@"hex_petrol.png"] forState:UIControlStateNormal];
    editEnd.tag=2;
    [self.toolBarView addSubview:editEnd];
    
    [editEnd addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editWalls = [UIButton buttonWithType:UIButtonTypeCustom];
    [editWalls setFrame:CGRectMake(330,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editWalls setBackgroundImage:[UIImage imageNamed:@"hex_brown.png"] forState:UIControlStateNormal];
    editWalls.tag=3;
    [self.toolBarView addSubview:editWalls];
    
    [editWalls addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    //toolBar unten
    
    /*  self.toolBarView2 = [[UIScrollView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight)];
     self.toolBarView2.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
     self.toolBarView2.backgroundColor = [UIColor clearColor];
     UIImage *backgroundImg2 = [UIImage imageNamed:@"toolbar.png"];
     UIImageView *imgView2 = [[UIImageView alloc]initWithImage:backgroundImg2];
     imgView2.alpha=0.5;
     imgView2.frame = CGRectMake(0 - 100, 0, self.toolBarView2.contentSize.width + 200, self.toolBarView2.contentSize.height);
     [self.toolBarView2 addSubview:imgView2];
     [self.view addSubview:self.toolBarView2];
     
     UIButton *wall1 = [UIButton buttonWithType:UIButtonTypeCustom];
     [wall1 setFrame:CGRectMake(0,20,50,39)];
     [[wall1 layer] setBorderWidth:1.0f];
     [[wall1 layer] setBorderColor:[UIColor grayColor].CGColor];
     wall1.tag=5;
     
     UIButton *wall2 = [UIButton buttonWithType:UIButtonTypeCustom];
     [wall2 setFrame:CGRectMake(0,62,50,39)];
     [[wall2 layer] setBorderWidth:1.0f];
     [[wall2 layer] setBorderColor:[UIColor grayColor].CGColor];
     wall2.tag=6;
     
     [self.toolBarView2 addSubview:wall1];
     [self.toolBarView2 addSubview:wall2];
     
     [wall1 addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
     [wall1 addTarget:self action:@selector(chooseWalls:) forControlEvents:UIControlEventTouchUpInside];
     [wall2 addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
     [wall2 addTarget:self action:@selector(chooseWalls:) forControlEvents:UIControlEventTouchUpInside];*/
    
    
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
            
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            
            if (!(lastPaintCoord.x == matrixCoords.x && lastPaintCoord.y == matrixCoords.y)) {
                if (paint){
                    
                    if ([obj isKindOfClass:[UIImageView class]]){
                        
                        MazeNode *node = [MazeNode node];
                        node.Size = [SettingsStore sharedStore].hexSize;
                        node.uiElement = obj;
                        node.center = node.uiElement.center;
                        node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
                        
                        
                        [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                        
                        matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
                    }
                    
                }
                
                else {
                    
                    if([obj isKindOfClass:[MazeNode class]]) {
                        
                        node=obj;
                        
                        if(node.isEnd){
                            hasEnd=NO;
                        }
                        if(node.isStart){
                            hasStart=NO;
                        }
                        
                        node.object=nil;
                        UIImageView *imgView = (UIImageView*)((MazeNode*)obj).uiElement;
                        [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
                        matrix[(int)matrixCoords.x][(int)matrixCoords.y] = imgView;
                        
                    }
                    
                }
            }}}
    if (self.buttonNodeType==3){
        
        if (![obj isEqual:[NSNull null]]){
            if(gesture.state == UIGestureRecognizerStateBegan){
                MazeNode *node = [MazeNode node];
                node.Size = [SettingsStore sharedStore].hexSize;
                
            }
            if (!(lastPaintCoord.x == matrixCoords.x && lastPaintCoord.y == matrixCoords.y)) {
                
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
                    
                    else if( node.isWall){
                        
                        node.object=nil;
                        
                        UIImageView *imgView = (UIImageView*)((MazeNode*)node).uiElement;
                        [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                        matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;}
                    
                    
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
            
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            
            if ([obj isKindOfClass:[UIImageView class]]){
                
                
                node.uiElement = obj;
                node.center = node.uiElement.center;
                node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                
                matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
            }
            
            else if ([obj isKindOfClass:[MazeNode class]]){
                
                node=obj;
                
                if(node.isStart){
                    hasStart=NO;
                }
                if(node.isEnd){
                    hasEnd=NO;
                }
                
                node.object=Nil;
                
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
                    hasStart=NO;
                    
                    UIImageView *imgView = (UIImageView*)((MazeNode*)touched).uiElement;
                    [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                    matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                    
                }
                
                
                else {
                    
                    if(hasStart==NO && !touched.isWall && !touched.isEnd) {
                        
                        [((UIImageView*)touched.uiElement) setImage:[UIImage imageNamed:@"hex_turquoise.png"]];
                        
                        MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(touched.center.x, touched.center.y)];
                        touched.object = start;
                        matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                        hasStart=YES;
                    }
                }
                
            }}
        if (self.buttonNodeType==2) {
            
            
            if ([obj isKindOfClass:[MazeNode class]]){
                MazeNode *touched = (MazeNode *)obj;
                
                
                if (touched.isEnd){
                    touched.object=Nil;
                    hasEnd =NO;
                    
                    UIImageView *imgView = (UIImageView*)((MazeNode*)touched).uiElement;
                    [imgView setImage:[UIImage imageNamed:@"hex_gray.png"]];
                    matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                    
                }
                
                else {
                    if(hasEnd==NO && !touched.isStart && !touched.isWall){
                        
                        [((UIImageView*)touched.uiElement) setImage:[UIImage imageNamed:@"hex_petrol.png"]];
                        
                        MazeObject *end = [MazeObject objectWithType:END andCenter:CGPointMake(touched.center.x, touched.center.y)];
                        touched.object = end;
                        matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                        hasEnd=YES;
                    }
                    
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
                    
                    if (!touched.isStart && !touched.isEnd){
                        
                        [((UIImageView*)touched.uiElement) setImage:[UIImage imageNamed:@"hex_brown.png"]];
                        
                        MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(touched.center.x, touched.center.y)];
                        touched.object = wall;
                        matrix[(int)matrixCoords.x][(int)matrixCoords.y] = touched;
                    }
                    
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
    self.wallList= [[NSMutableArray alloc]init];
    
    
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    self.scrollView.zoomScale = 0.48;
    return [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)alertOverwrite {
    
    NSLog(@"levelId vor alert:%i",self.levelID);
    
    if (self.levelID!=-1){
        
        UIAlertView* alertSave = [[UIAlertView  alloc]initWithTitle:@"" message:@"Overwrite Level?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"overwrite", @"add new level", nil];
        alertSave.tag=0;
        [alertSave show];}
    
    else{
        
        [self alertLevelName];
    }
    
}

-(void)alertLevelName {
    
    UIAlertView *alertName= [[UIAlertView alloc] initWithTitle:@"Levelname" message:@"Enter Levelname:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save",nil];
    alertName.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertName.tag=1;
    [alertName show];
    
}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag ==0){
        
        if(buttonIndex==1){
            
            name=levelInfo.name;
            [self save];
        }
        
        else if (buttonIndex == 2){
            [self alertLevelName];
            
            
        }}
    
    if (alertView.tag == 1){
        
        if(buttonIndex == 1){
            
            UITextField *nameTextField = [alertView textFieldAtIndex:0];
            name=nameTextField.text;
            self.levelID=-1;
            [self save];
            
            
        }
    }
}



-(void)save{
    
    LevelInfo *info=[[LevelInfo alloc]initWithStart:CGPointZero end:CGPointZero matrix:matrix walls:self.wallList name:name];
    
    [[LevelManager sharedManager] saveLevel:info forID:self.levelID];
    self.levelID=[LevelManager sharedManager].levels.count-1;
    NSLog(@"levelID: %i", self.levelID );
    
}



-(void)levelsView {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self cleanScreen];
}


-(void)loadAtIndex:(int)index{
    
    self.levelID=index;
    
    LevelManager *manager =[LevelManager sharedManager];
    NSMutableArray *allLevels = manager.levels;
    
    if (allLevels.count>0){
        LevelInfo *info2=[[LevelInfo alloc]initWithDictionary:allLevels[index-1]];
        
        levelInfo = info2;
        NSLog(@"levelID nach load: %i", self.levelID);
        
        [self buildBoard:info2];
        
        
    }
    else  NSLog(@"Fehler");
}


-(void)nodeTypeChoosen:(UIButton*) nodeType {
    
    self.buttonNodeType=nodeType.tag;
    
    
}

-(void)cleanScreen{
    
    //board und alle weiteren Levelinfovariablen leeren
    
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
    [self.wallList removeAllObjects];
    hasEnd=NO;
    hasStart=NO;
    self.levelID=-1;
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
                hasEnd=YES;
            }
            
            else if (nodeType==[NSNumber numberWithInteger:3]){
                
                node.center = node.uiElement.center;
                node.MatrixCoords = CGPointMake(x,y);
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_turquoise.png"]];
                
                MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(node.center.x, node.center.y)];
                node.object = start;
                hasStart=YES;
            }
            
            else if (nodeType==[NSNumber numberWithInteger:2]){
                
                node.center = node.uiElement.center;
                node.MatrixCoords = CGPointMake(x,y);
                
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_brown.png"]];
                
                MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
                node.object = wall;
                hasStart=YES;
            }
            
            matrix[ab][bc] = node;
            bc++;
            
        }
        ab++;
        
        
    }
}


/*

-(void)chooseWalls:(NSMutableArray*)choosenWall{
    
    NSMutableArray* wallArray=[NSMutableArray array];
    
    if(self.buttonNodeType == 5){
        MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0, 0)];
        [wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
        [wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
        
        
    }
    
    if(self.buttonNodeType == 6){
        MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0, 0)];
        [wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
        [wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
        [wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
        
    }
    
    [self.wallList addObject:wallArray];
    
    NSLog(@"wallList:%i", self.wallList.count);
    
}
*/


@end
