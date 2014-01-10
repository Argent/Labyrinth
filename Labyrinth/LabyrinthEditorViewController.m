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
    
    LevelInfo * levelInfo;
    
    NSMutableArray *toolbarItemsLabel;
    NSMutableArray *objCounts;
    MazeNode *startElement;
    MazeNode *endElement;
 
    CALayer *lastBorderLayer;
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
        self.toolBarView.contentSize = CGSizeMake(self.view.frame.size.width, toolbarHeight);
        self.toolBarView.backgroundColor = [UIColor clearColor];
    }else{
        self.toolBarView2 = [[UIScrollView alloc]initWithFrame:CGRectMake(0, yPosition, self.view.frame.size.width, toolbarHeight)];
        self.toolBarView2.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
        self.toolBarView2.backgroundColor = [UIColor clearColor];
    }
    UIImage *backgroundImg = [UIImage imageNamed:@"toolbar.png"];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:backgroundImg];
    imgView.alpha=0.5;
    
    if(top){
        imgView.transform = CGAffineTransformMakeRotation(M_PI);
        imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView2.contentSize.width + 200, self.toolBarView.contentSize.height);
        [self.toolBarView2 addSubview:imgView];
        [self.view addSubview:self.toolBarView2];
    }else{
        imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView.contentSize.width + 200, self.toolBarView.contentSize.height);
        [self.toolBarView addSubview:imgView];
        [self.view addSubview:self.toolBarView];
    }
}
-(void)initToolbarTop{
    [self initToolbars:YES];
    
    // Menu Button
    
    UIButton *cleanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cleanButton.frame=CGRectMake(10, 10, 35, 35);
    [cleanButton setBackgroundImage:[UIImage imageNamed:@"menu_white.png"] forState:UIControlStateNormal];
    [self.toolBarView2 addSubview:cleanButton];
    
    [cleanButton addTarget:self action:@selector(showActionSheet:) forControlEvents:UIControlEventTouchUpInside];
    
    // Object contrainers
    NSMutableArray *wallNodes = [NSMutableArray array];
    NSMutableArray *objNodes = [NSMutableArray array];
    MazeObject *obj1 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(-1,1)]];
    [wallNodes addObject:[obj1 generateAndAddNodeRelative:CGPointMake(0,1)]];
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
    MazeObject *obj5 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj5 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj5 generateAndAddNodeRelative:CGPointMake(1,1)]];
    [objNodes addObject:obj5];
    MazeObject *obj6 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(-2,2)]];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(-1,1)]];
    [objNodes addObject:obj6];
    MazeObject *obj7 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj7 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj7 generateAndAddNodeRelative:CGPointMake(-1,0)]];
    [wallNodes addObject:[obj7 generateAndAddNodeRelative:CGPointMake(-1,1)]];
    [wallNodes addObject:[obj7 generateAndAddNodeRelative:CGPointMake(-1,2)]];
    [objNodes addObject:obj7];
    MazeObject *obj8 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj8 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj8 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj8 generateAndAddNodeRelative:CGPointMake(0,2)]];
    [wallNodes addObject:[obj8 generateAndAddNodeRelative:CGPointMake(1,3)]];
    [wallNodes addObject:[obj8 generateAndAddNodeRelative:CGPointMake(2,3)]];
    [wallNodes addObject:[obj8 generateAndAddNodeRelative:CGPointMake(2,4)]];
    [objNodes addObject:obj8];
    for (MazeObject* objects in objNodes) {
        [GeometryHelper scaleToToolbar:objects withLength:@"height"];
        [GeometryHelper scaleToToolbar:objects withLength:@"width"];
    }
    NSMutableArray *toolbarItems = [NSMutableArray array];
    toolbarItemsLabel = [NSMutableArray array];
    objCounts = [NSMutableArray array];
    int itemSize = [SettingsStore sharedStore].toolbarHeight-30;
    for(int i = 0; i < 8; i++){
        objCounts[i] = [NSNumber numberWithInt:0];
        
        toolbarItems[i] = [[UIView alloc] initWithFrame:CGRectMake(50+10+i*(itemSize+10), self.toolBarView2.frame.size.height/2-itemSize/2-10, itemSize, itemSize)];
        [((UIView*)toolbarItems[i]).layer setBorderWidth:1.0];
        [((UIView*)toolbarItems[i]).layer setBorderColor:[UIColor blackColor].CGColor];
        [self.toolBarView2 addSubview:toolbarItems[i]];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        UIButton *plus = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, ((UIView*)toolbarItems[i]).frame.size.width/2, ((UIView*)toolbarItems[i]).frame.size.height)];
        UIButton *minus = [[UIButton alloc]initWithFrame:CGRectMake(((UIView*)toolbarItems[i]).frame.size.width/2, 0, ((UIView*)toolbarItems[i]).frame.size.height/2, ((UIView*)toolbarItems[i]).frame.size.height)];
        UILabel *plusText = [[UILabel alloc]initWithFrame:CGRectMake(0, plus.frame.size.height-15, 15, 15)];
        UILabel *minusText = [[UILabel alloc]initWithFrame:CGRectMake(minus.frame.size.width-15, minus.frame.size.height-15, 15, 15)];
        plus.tag = i+4;
        minus.tag = i+4;
        [label setBackgroundColor:[UIColor blackColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setFont:[UIFont boldSystemFontOfSize:12]];
        label.textAlignment = NSTextAlignmentCenter;
        ((MazeObject*) objNodes[i]).containerView.center = CGPointMake(50+((UIView*)toolbarItems[i]).frame.size.width/2+10+i*(itemSize+10), ((UIView*)toolbarItems[i]).frame.size.height/2+self.toolBarView.frame.size.height/2-itemSize/2-10);
        [label setText:[NSString stringWithFormat:@"1"]];
        [toolbarItemsLabel addObject:label];
        [((UIView*)toolbarItems[i]) addSubview:label];
        [plus setBackgroundColor:[UIColor clearColor]];
        [plus addTarget:self action:@selector(plusObjects:) forControlEvents:UIControlEventTouchUpInside];
        [plusText setBackgroundColor:[UIColor blackColor]];
        [plusText setTextColor:[UIColor greenColor]];
        [plusText setFont:[UIFont boldSystemFontOfSize:12]];
        [plusText setText:@"+"];
        plusText.textAlignment = NSTextAlignmentCenter;
        [minusText setBackgroundColor:[UIColor blackColor]];
        [minusText setTextColor:[UIColor redColor]];
        [minusText setFont:[UIFont boldSystemFontOfSize:12]];
        [minusText setText:@"-"];
        minusText.textAlignment = NSTextAlignmentCenter;
        [plus addSubview:plusText];
        [((UIView*)toolbarItems[i]) addSubview:plus];
        [minus setBackgroundColor:[UIColor clearColor]];
        [minus addSubview:minusText];
        [((UIView*)toolbarItems[i]) addSubview:minus];
        [minus addTarget:self action:@selector(minusObjects:) forControlEvents:UIControlEventTouchUpInside];
    }

    for (MazeObject* objects in objNodes) {
        [self.toolBarView2 addSubview:objects.containerView];
        objects.containerView.userInteractionEnabled = NO;
    }
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
                tmpCount--;
            }else if (plus){
                tmpCount++;
            }
            [(UILabel*)toolbarItemsLabel[i-4] setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:tmpCount]]];
        }
    }
}
-(IBAction)backButtonPressed:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)initToolbarBottom{
    [self initToolbars:NO];
    
    UIButton *editBoard = [UIButton buttonWithType:UIButtonTypeCustom];
    [editBoard setFrame:CGRectMake(10,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editBoard setBackgroundImage:[UIImage imageNamed:@"hex_gray.png"] forState:UIControlStateNormal];
    editBoard.tag=0;
    [self.toolBarView addSubview:editBoard];
    [self setButtonBorder:editBoard withColor:[UIColor whiteColor]];

    
    [editBoard addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editStart = [UIButton buttonWithType:UIButtonTypeCustom];
    [editStart setFrame:CGRectMake(70,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editStart setBackgroundImage:[UIImage imageNamed:@"hex_turquoise.png"] forState:UIControlStateNormal];
    editStart.tag=1;
    [self.toolBarView addSubview:editStart];
    
    [editStart addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editEnd = [UIButton buttonWithType:UIButtonTypeCustom];
    [editEnd setFrame:CGRectMake(130,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editEnd setBackgroundImage:[UIImage imageNamed:@"hex_petrol.png"] forState:UIControlStateNormal];
    editEnd.tag=2;
    [self.toolBarView addSubview:editEnd];
    
    [editEnd addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editWalls = [UIButton buttonWithType:UIButtonTypeCustom];
    [editWalls setFrame:CGRectMake(190,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editWalls setBackgroundImage:[UIImage imageNamed:@"hex_darkbrown.png"] forState:UIControlStateNormal];
    editWalls.tag=3;
    [self.toolBarView addSubview:editWalls];
    
    [editWalls addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *editCoins = [UIButton buttonWithType:UIButtonTypeCustom];
    [editCoins setFrame:CGRectMake(250,25,[[SettingsStore sharedStore]width],[[SettingsStore sharedStore]height])];
    [editCoins setBackgroundImage:[UIImage imageNamed:@"hex_coin.png"] forState:UIControlStateNormal];
    editCoins.tag=4;
    [self.toolBarView addSubview:editCoins];
    
    [editCoins addTarget:self action:@selector(nodeTypeChoosen:) forControlEvents:UIControlEventTouchUpInside];
    
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

-(void)panGestureCaptures:(UIPanGestureRecognizer *)gesture {
    [self createMazeNodeWithGesture:gesture andType:self.buttonNodeType];
}


- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture {
    [self createMazeNodeWithGesture:gesture andType:self.buttonNodeType];
}


-(void)createMazeNodeWithGesture:(UIGestureRecognizer*)gesture andType:(int)type{
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint.x -= scrollViewOffset.x;
    touchPoint.y -= scrollViewOffset.y;
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    CGPoint matrixCoords = [GeometryHelper pixelToHex:touchPoint gridSize:gridSize];
    
    id obj = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    bool singleTap = [gesture isKindOfClass:[UITapGestureRecognizer class]];
    if(gesture.state == UIGestureRecognizerStateBegan){
        if ([obj isKindOfClass:[UIImageView class]]){
            paint = YES;
        }else if ([obj isKindOfClass:[MazeNode class]] && type == 0){
            paint = NO;
        }
    }
    
    if (![obj isEqual:[NSNull null]]) {
        MazeNode *node = [MazeNode node];
        node.Size = [SettingsStore sharedStore].hexSize;
        
        if (singleTap || (!singleTap && paint)){
            if ([obj isKindOfClass:[UIImageView class]])
                node.uiElement = obj;
            else if ([obj isKindOfClass:[MazeNode class]])
                node.uiElement = ((MazeNode*)obj).uiElement;
            node.center = node.uiElement.center;
            node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
            MazeObject *mazeObj = nil;
            
            if (node.isStart){
                startElement = nil;
            }else if (node.isEnd){
                endElement = nil;
            }
            
            if (type == 0) {
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                node.object = nil;
            } else if (type == 1) {
                mazeObj = [MazeObject objectWithType:START andCenter:CGPointMake(node.center.x, node.center.y)];
                if (startElement){
                    startElement.object = nil;
                    [(UIImageView*)(startElement.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                    startElement = nil;
                }
                startElement = node;
            } else if (type == 2){
                mazeObj = [MazeObject objectWithType:END andCenter:CGPointMake(node.center.x, node.center.y)];
                if (endElement){
                    endElement.object = nil;
                    [(UIImageView*)(endElement.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
                    endElement = nil;
                }
                endElement = node;
            } else if (type == 3){
                mazeObj = [MazeObject objectWithType:FIXEDWALL andCenter:CGPointMake(node.center.x, node.center.y)];
            }  else if (type == 4){
                mazeObj = [MazeObject objectWithType:COIN andCenter:CGPointMake(node.center.x, node.center.y)];
            }
            
            if (type > 0){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:mazeObj.imageName]];
                node.object = mazeObj;
            }
            
            matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
            
            if (paint)
                lastPaintCoord = matrixCoords;
        } else if (!singleTap && !paint){
            if([obj isKindOfClass:[MazeNode class]]) {
                
                node = obj;
                
                if(node.isEnd){
                    endElement = nil;
                }
                if(node.isStart){
                    startElement = nil;
                }
                
                node.object=nil;
                UIImageView *imgView = (UIImageView*)((MazeNode*)obj).uiElement;
                [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
                matrix[(int)matrixCoords.x][(int)matrixCoords.y] = imgView;
                
            }

        }
    }

}


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
    
    contentsFrame.origin.y += 60;
    
    scrollViewOffset.x = contentsFrame.origin.x;
    scrollViewOffset.y = contentsFrame.origin.y;
    
    containerView.frame = contentsFrame;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.wallList= [[NSMutableDictionary alloc]init];
    
    
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
    
    if (!startElement || !endElement){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No start/end button"
                                                        message:@"Please set a start and an end button"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [GeometryHelper connectMatrix:matrix];
    [GeometryHelper solveMazeFrom:startElement To:endElement Matrix:matrix];
    NSArray *shortestPath = [GeometryHelper getShortestPathFrom:startElement To:endElement];
    
    if (shortestPath.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No path from start to end"
                                                        message:@"There is no possible path from start point to end point"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //NSLog(@"levelId vor alert:%i",self.levelID);
    
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
    int i = 0;
    for (UILabel *wallElementLabel in toolbarItemsLabel) {
        [self.wallList setObject:[NSNumber numberWithInt:[wallElementLabel.text intValue]] forKey:[NSNumber numberWithInt:i]];
        i++;
    }
    
    LevelInfo *info=[[LevelInfo alloc]initWithMatrix:matrix walls:self.wallList name:name];

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
        
        for (NSNumber *key in info2.walls) {
            ((UILabel*)toolbarItemsLabel[key.intValue]).text = [NSString stringWithFormat:@"%i",[[info2.walls objectForKey:key] intValue]];
        }
        
        
    }
    else  NSLog(@"Fehler");
}


-(void)nodeTypeChoosen:(UIButton*) nodeType {
    self.buttonNodeType = nodeType.tag;
    [self setButtonBorder:nodeType withColor:[UIColor whiteColor]]; 
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
    startElement = nil;
    endElement = nil;
    self.levelID=-1;
}


-(void)buildBoard:(LevelInfo*) info{
    NSMutableArray *board= info.board;
    
    for (int x = 0; x < board.count; x++) {
        for (int y = 0; y <((NSArray*)board[x]).count; y++){
            
            NSNumber *nodeType = board[x][y];
            id obj = matrix[x + info.minX.intValue][y + info.minY.intValue];
            
            if ([obj isEqual:[NSNull null]])
                continue;
            
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            node.uiElement = obj;
            
            node.MatrixCoords = CGPointMake(x,y);
            node.center = node.uiElement.center;
            
            if(nodeType.intValue == 1){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
            } else if (nodeType.intValue == 4){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_petrol.png"]];
                node.object = [MazeObject objectWithType:END andCenter:CGPointMake(node.center.x, node.center.y)];
                endElement = node;
            } else if (nodeType.intValue == 3){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_turquoise.png"]];
                node.object = [MazeObject objectWithType:START andCenter:CGPointMake(node.center.x, node.center.y)];
                startElement = node;
            } else if (nodeType.intValue == 2){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_darkbrown.png"]];
                node.object = [MazeObject objectWithType:FIXEDWALL andCenter:CGPointMake(node.center.x, node.center.y)];
            }else if (nodeType.intValue == 5){
                [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_coin.png"]];
                node.object = [MazeObject objectWithType:COIN andCenter:CGPointMake(node.center.x, node.center.y)];
            }
            
            //NSLog(@"(x:%i,y:%i) = %@", x,y,board[x][y]);
            
            if (nodeType.intValue == 0)
                matrix[x + info.minX.intValue][y + info.minY.intValue] = node.uiElement;
            else
                matrix[x + info.minX.intValue][y + info.minY.intValue] = node;
        }
    }
}

-(void)setButtonBorder:(UIButton*)button withColor:(UIColor*)color{
    [lastBorderLayer removeFromSuperlayer];
    
    CALayer *borderLayer = [CALayer layer];
    CGRect borderFrame = CGRectMake(-3, 0, (button.frame.size.width + 6), (button.frame.size.height));
    [borderLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
    [borderLayer setFrame:borderFrame];
    [borderLayer setCornerRadius:8];
    [borderLayer setBorderWidth:2];
    [borderLayer setBorderColor:[color CGColor]];
    [button.layer addSublayer:borderLayer];
    lastBorderLayer = borderLayer;
}

-(IBAction)showActionSheet:(id)sender {
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save Level", @"Clear Level", @"Load Level", @"Home", nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [popupQuery showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self alertOverwrite];
            break;
        case 1:
            [self cleanScreen];
            break;
        case 2:
            [self levelsView];
            break;
        case 4:
            break;
        case 3:
            [self dismissViewControllerAnimated:YES completion:^{
                if(self.homeBlock){
                    self.homeBlock();
                }
            }];
            
            break;

            
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
