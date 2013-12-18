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

@interface LabyrinthEditorViewController () {
    UIView *containerView;
    NSMutableArray *matrix;
    CGPoint scrollViewOffset;
    CGSize gridSize;
    
    bool paint;
    CGPoint lastPaintCoord;
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
    imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView.contentSize.width + 200, self.toolBarView.contentSize.height);
    
    [self.toolBarView addSubview:imgView];
    [self.view addSubview:self.toolBarView];
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
    
    if (![obj isEqual:[NSNull null]]){
        if(gesture.state == UIGestureRecognizerStateBegan){
            //NSLog(@"Gesture started");
            if ([obj isKindOfClass:[UIImageView class]]){
                paint = YES;
            }else if ([obj isKindOfClass:[MazeNode class]]){
                paint = NO;
            }
        }
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
            }else {
                if ([obj isKindOfClass:[MazeNode class]]) {
                    
                    UIImageView *imgView = (UIImageView*)((MazeNode*)obj).uiElement;
                    [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
                    matrix[(int)matrixCoords.x][(int)matrixCoords.y] = imgView;

                }
            }
            //NSLog(@"(%.2f,%.2f)", newCoord.x,newCoord.y);
        }
    }
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
        
        if ([obj isKindOfClass:[UIImageView class]]){
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            node.uiElement = obj;
            node.center = node.uiElement.center;
            node.MatrixCoords = CGPointMake((int)matrixCoords.x, (int)matrixCoords.y);
            
            [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_gray.png"]];
            
            matrix[(int)matrixCoords.x][(int)matrixCoords.y] = node;
            
        }else if ([obj isKindOfClass:[MazeNode class]]){
            
            UIImageView *imgView = (UIImageView*)((MazeNode*)obj).uiElement;
            [imgView setImage:[UIImage imageNamed:@"hex_empty.png"]];
            matrix[(int)matrixCoords.x][(int)matrixCoords.y] = imgView;
            
        }
        //NSLog(@"Touch Node Center: (x:%.2f,y:%.2f)", node.center.x, node.center.y);
        
        
        
            /*
             MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
             MazeNode *nn = [wall generateAndAddNodeRelative:CGPointMake(0,0)];
             [self addDragEventsToNode:nn];
             node.object = wall;
             [containerView addSubview:wall.containerView];
             */
        
    }
        
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
    
    scrollViewOffset.x = contentsFrame.origin.x;
    scrollViewOffset.y = contentsFrame.origin.y;
    
    containerView.frame = contentsFrame;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
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

@end
