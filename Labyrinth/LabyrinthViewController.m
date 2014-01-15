//
//  LabyrinthViewController.m
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "LabyrinthViewController.h"
#import "NSMutableArray+QueueAdditions.h"
#import "MazeNode.h"
#import "MazeObject.h"
#import "UIMazeControl.h"
#import "UIBezierView.h"
#import "SettingsStore.h"
#import "GeometryHelper.h"
#import "UILabyrinthMenu.h"
#import "LevelInfo.h"
#import "LevelManager.h"


@interface LabyrinthViewController () {
    UIView *containerView;
    UIBezierView *pathView;
    UILabyrinthMenu *menubar;
    NSMutableArray *matrix;
    NSMutableArray *objNodes;
    NSMutableArray *objCounts;
    NSMutableArray* toolbarItems;
    NSMutableArray *toolbarItemsLabel;
    
    UIView *gameOverView;
    
    CGSize gridSize;

    CGPoint lastDragPoint;
    bool touchedDown;
    bool overGameField;
    
    bool hasStart;
    bool hasEnd;
    float lastX;
    float lastY;
    
    CGPoint scrollViewOffset;
    
    UIImageView *movingView;
    bool animationComplete;
    bool animationStarted;
    
    NSMutableArray *movingPath;
    NSMutableArray *previousPath;
    CGPoint lastWayPoint;
    
    bool interrupted;
    bool paused;
    
    NSMutableArray *overlayRects;
    int differentObjectsCounter;
    
    LevelInfo *levelInfo;
}
@end

@implementation LabyrinthViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    [NSException raise:@"should not call this" format:@"forbidden"];
    return nil;
}


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andLevelInfo:(LevelInfo*)levelinfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        scrollViewOffset = CGPointMake(0.0, 0.0);
        levelInfo = levelinfo;
        [self initGridWithSize:CGSizeMake(levelInfo.board.count +2 , ((NSArray*)levelInfo.board[0]).count +2)];
        [self initToolbar];
        menubar = [[UILabyrinthMenu alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
        [menubar setBackBlock:^{
            [self dismissViewControllerAnimated:NO completion:^{
                
                    if(self.homeBlock){
                        self.homeBlock();
                    }
            }];
        }];
        [menubar setStartPauseBlock:^(bool start) {
            
            [self initToolbarItems];
            [self initToolbarObjects];
            if (pathView) {
                pathView.curvePath = nil;
                [pathView removeFromSuperview];
                pathView = nil;
                animationComplete = YES;
            }
            if (start){
                if (!paused) {
                MazeNode *startNode = nil;
                MazeNode *endNode = nil;
                for (int x = 0; x < matrix.count; x++) {
                    for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
                        MazeNode *tmpNode = matrix[x][y];
                        if (![tmpNode isEqual:[NSNull null]] && [tmpNode isKindOfClass:[MazeNode class]]) {
                            if (tmpNode.object != nil && tmpNode.object.type == END)
                                endNode = tmpNode;
                            if (tmpNode.object != nil && tmpNode.object.type == START)
                                startNode = tmpNode;
                        }
                    }
                }
                
                [self animatePathFromStart:startNode toEnd:endNode withStepDuration:levelInfo.stepDuration];
                }else {
                    movingView.layer.speed = levelInfo.stepDuration;
                    movingView.layer.timeOffset = 0.0;
                    movingView.layer.beginTime = 0.0;
                }
            }else {
                CFTimeInterval mediaTime = CACurrentMediaTime();
                CFTimeInterval pausedTime = [movingView.layer convertTime: mediaTime fromLayer: nil];
                movingView.layer.speed = 0.0;
                movingView.layer.timeOffset = pausedTime;
                paused = YES;
            }
        }];
        [menubar setStopBlock:^{
            paused = NO;
            interrupted = YES;
            if (pathView) {
                pathView.curvePath = nil;
                [pathView removeFromSuperview];
                pathView = nil;
                animationComplete = YES;
            }
 
        }];
        [self.view addSubview:menubar];
        
        //UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
        //[self.scrollView addGestureRecognizer:singleTap];
        

        [self buildLevel:levelInfo];
        [GeometryHelper connectMatrix:matrix];
        overlayRects = [NSMutableArray array];
        
        lastX = 0.0;
        lastY = 0.0;
        
    }
    return self;
}

// Called when a drag on a maze object started
- (IBAction) itemDragBegan:(id) sender withEvent:(UIEvent *) event {
    NSLog(@"Drag began");
    
    if(!animationStarted){
        UIAlertView *noAnimation = [[UIAlertView alloc] initWithTitle: @"Start game first" message: @"To move the walls to the field, start the game." delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
        [noAnimation show];
    }
    lastDragPoint = [[[event allTouches] anyObject] locationInView:self.view];
    touchedDown = YES;
    if (lastDragPoint.y > self.view.frame.size.height - 100){
        overGameField = NO;
    }else{
        overGameField = YES;
    }
}

// Called on every x,y pixel change during a drag action
- (IBAction) itemMoved:(id) sender withEvent:(UIEvent *) event {
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    UIControl *control = sender;
    
    if (touchedDown){
        if (lastDragPoint.y < self.view.frame.size.height - 100){
            UIControl *control = sender;
            if ([control isKindOfClass:[UIMazeControl class]]){
                UIMazeControl *mazeControl = (UIMazeControl*)control;
                UIView *imgView = mazeControl.mazeObject.containerView;
                float scaleFactor = self.scrollView.zoomScale;
                if ([imgView isKindOfClass:[UIView class]]){
                    ((UIView*)imgView).transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                }
                
                for (MazeNode *node in mazeControl.mazeObject.gridNodes) {
                    NSValue *value = [NSValue valueWithCGPoint:node.MatrixCoords];
                    node.object = nil;
                }
                [mazeControl.mazeObject.gridNodes removeAllObjects];
                
                if (!animationComplete && animationStarted){
                    CGPoint playerCoords;
                    for (int i = 0; i < movingPath.count; i++) {
                        NSMutableArray *array = movingPath[i];
                        if ([array[1] boolValue] == NO){
                            if (i > 0)
                                playerCoords = [movingPath[i-1][0] CGPointValue];
                            else
                                playerCoords = [array[0] CGPointValue];
                            break;
                        }
                    }
                    if (![matrix[(int)playerCoords.x][(int)playerCoords.y] isKindOfClass:[MazeNode class]]){
                        return;
                    }
                    MazeNode *endNode = [self getEndNode];
                    [self recalculateAnimationFromStart:matrix[(int)playerCoords.x][(int)playerCoords.y] toEnd:endNode withStepDuration:levelInfo.stepDuration];
                    
                }
            }
        }
        touchedDown = NO;
    }
    
    if ([control isKindOfClass:[UIMazeControl class]]){
        UIMazeControl *mazeControl = (UIMazeControl*)control;
        
        [self.view addSubview:mazeControl.mazeObject.containerView];
        mazeControl.mazeObject.containerView.center = point;
        
        
        CGPoint tmpPoint = [[[event allTouches] anyObject] locationInView:self.scrollView];
        tmpPoint.x -= scrollViewOffset.x;
        tmpPoint.y -= scrollViewOffset.y;
        tmpPoint = CGPointMake(tmpPoint.x* 1/self.scrollView.zoomScale , tmpPoint.y* 1/self.scrollView.zoomScale );
        
        CGRect containerRect = mazeControl.mazeObject.containerView.frame;
        CGAffineTransform t = CGAffineTransformMakeScale(1.0* 1/self.scrollView.zoomScale,1.0* 1/self.scrollView.zoomScale);
        CGRect rect2 = CGRectApplyAffineTransform(containerRect,t);
        
        rect2.origin.x = tmpPoint.x - rect2.size.width / 2;
        rect2.origin.y = tmpPoint.y - rect2.size.height / 2;
        
        NSArray *nodeRects = [GeometryHelper getNodeRectsFromObject:mazeControl.mazeObject TopLeft:CGPointMake(rect2.origin.x, rect2.origin.y)];
        bool intersects = NO;
        
        if (animationStarted){
            CGRect playerFrame = [movingView.layer.presentationLayer frame];
            for (NSValue *rect in nodeRects) {
                intersects = intersects || [GeometryHelper hexIntersectsHex:playerFrame Hex:[rect CGRectValue]];
            }
        }
        
        for (int x = 0; x < matrix.count; x++) {
            for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
                MazeNode *node = matrix[x][y];
                if (![node isEqual:[NSNull null]]&& [node isKindOfClass:[MazeNode class]] && node.object &&
                    (node.object.type == WALL ||
                     node.object.type == FIXEDWALL ||
                     node.object.type == COIN ||
                     node.object.type == START ||
                     node.object.type == END ) ){
                        for (NSValue *rect in nodeRects) {
                           // intersects = intersects || CGRectIntersectsRect(node.Frame, [rect CGRectValue]);
                            intersects = intersects || [GeometryHelper hexIntersectsHex:node.Frame Hex:[rect CGRectValue]];
                        }
                    }
            }
        }
        
        if (intersects){
            // red wall
            [mazeControl.mazeObject overlayWithColor:[UIColor redColor] alpha:0.6];
        }else{
            // brown wall
            [mazeControl.mazeObject removeOverlay];
        }
        
    }
    
    // check whether the wallobject is on the toolbar or gamefield
    if (lastDragPoint.y <= self.view.frame.size.height - 100 &&
        point.y > self.view.frame.size.height - 100) {
        // toolbar
        if ([control isKindOfClass:[UIMazeControl class]]){
            UIMazeControl *mazeControl = (UIMazeControl*)control;
            
            // scale to the right size
            UIView *imgView = mazeControl.mazeObject.containerView;
            if ([imgView isKindOfClass:[UIView class]]){
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                                 }];
            }
        }
        overGameField = NO;
    } else if (lastDragPoint.y >= self.view.frame.size.height - 100 &&
               point.y < self.view.frame.size.height - 100){
        // gamefield
        float scaleFactor = self.scrollView.zoomScale;
        
        if ([control isKindOfClass:[UIMazeControl class]]){
            UIMazeControl *mazeControl = (UIMazeControl*)control;
            
            // scale to the right size
            UIView *imgView = mazeControl.mazeObject.containerView;
            if ([imgView isKindOfClass:[UIView class]]){
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     ((UIView*)imgView).transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                                 }];
            }
            
        }
        overGameField = YES;
    }
    // remember last point
    lastDragPoint = point;
    
}

// called when the finger is lifted, hence ending the drag action
- (IBAction) itemDragExit:(id) sender withEvent:(UIEvent *) event {
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    UIControl *control = sender;
    if ([control isKindOfClass:[UIMazeControl class]]){
        UIMazeControl *mazeControl = (UIMazeControl*)control;
        if (point.y > self.view.frame.size.height - 100){
            // toolbar!
            int itemSize = [SettingsStore sharedStore].toolbarHeight-30 ;
            
            // scaling the wall for the toolbar
            [GeometryHelper scaleToToolbar:mazeControl.mazeObject withLength:@"height"];
            [GeometryHelper scaleToToolbar:mazeControl.mazeObject withLength:@"width"];
            [mazeControl.mazeObject removeOverlay];
            
            // calculate the center point
            point = CGPointMake(((UIView*)toolbarItems[mazeControl.mazeObject.category]).frame.size.width/2+10+mazeControl.mazeObject.category*(itemSize+10), ((UIView*)toolbarItems[mazeControl.mazeObject.category]).frame.size.height/2+self.toolBarView.frame.size.height/2-itemSize/2+10);
            mazeControl.mazeObject.containerView.center = point;
            
            [self.toolBarView addSubview:mazeControl.mazeObject.containerView];

            // update the category counter
            if(!mazeControl.mazeObject.toolbarItem){
                mazeControl.mazeObject.toolbarItem = YES;
                int tmpCount = [((UILabel*)toolbarItemsLabel[mazeControl.mazeObject.category]).text intValue];
                [(UILabel*)toolbarItemsLabel[mazeControl.mazeObject.category] setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:tmpCount+1]]];
            }
        } else {
            // gamefield!
            
            // first scale the object to the gamefield size
            mazeControl.mazeObject.containerView.center = point;
            if(mazeControl.mazeObject.toolbarItem){
                mazeControl.mazeObject.toolbarItem = NO;
                [(UIView*)toolbarItems[mazeControl.mazeObject.category] addSubview:mazeControl.mazeObject.containerView];
                int tmpCount = [((UILabel*)toolbarItemsLabel[mazeControl.mazeObject.category]).text intValue];
                [(UILabel*)toolbarItemsLabel[mazeControl.mazeObject.category] setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:tmpCount-1]]];
            }
            point = [[[event allTouches] anyObject] locationInView:self.scrollView];
            point.x -= scrollViewOffset.x;
            point.y -= scrollViewOffset.y;
            point = CGPointMake(point.x* 1/self.scrollView.zoomScale , point.y* 1/self.scrollView.zoomScale );
            [containerView addSubview:mazeControl.mazeObject.containerView];
            for (MazeNode *node in mazeControl.mazeObject.gridNodes) {
                NSValue *value = [NSValue valueWithCGPoint:node.MatrixCoords];
            }
            
            // scale the image view
            UIView *imgView = mazeControl.mazeObject.containerView;
            if ([imgView isKindOfClass:[UIView class]]){
                ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                mazeControl.mazeObject.containerView.center = point;
            }
            
            CGRect containerRect = mazeControl.mazeObject.containerView.frame;
            
            // calculate the coordinates where the object was dropped
            NSArray *dropCoords = [GeometryHelper alignToGrid:mazeControl.mazeObject Matrix:matrix TopLeft:CGPointMake(containerRect.origin.x, containerRect.origin.y)];
            for (NSValue *val in dropCoords) {
                CGPoint point = [val CGPointValue];
                MazeNode *node = matrix[(int)point.x][(int)point.y];
                bool flash = NO;
                if (node && [node isKindOfClass:[MazeNode class]] && !node.object){
                    if (animationStarted){
                        CGPoint matrixPoint = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position]gridSize:gridSize];
                        if (point.x == matrixPoint.x && point.y == matrixPoint.y) {
                            flash = YES;
                        }
                    }
                }else {
                    flash = YES;
                }
                if(flash){
                    [mazeControl.mazeObject flashView:[UIColor redColor] times:1];
                    
                    return;
                }
            }
            
            // than get the coordinates of the unterlaying grid nodes
            NSArray *alignedCoords = [GeometryHelper alignToValidGrid:mazeControl.mazeObject Matrix:matrix TopLeft:CGPointMake(containerRect.origin.x, containerRect.origin.y)];
            CGRect rect = [GeometryHelper rectForObject:alignedCoords Matrix:matrix];
            [mazeControl.mazeObject removeOverlay];
            
            
            // set the the object variable of the grid nodes
            for (NSValue *val in alignedCoords) {
                CGPoint coords = [val CGPointValue];
                ((MazeNode*) matrix[(int)coords.x][(int)coords.y]).object = mazeControl.mazeObject;
                [mazeControl.mazeObject.gridNodes addObject:matrix[(int)coords.x][(int)coords.y] ];
            }
           
            
            if (!animationComplete && animationStarted){
                //CGPoint playerCoords = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                
                CGPoint playerCoords;
                for (int i = 0; i < movingPath.count; i++) {
                    NSMutableArray *array = movingPath[i];
                    if ([array[1] boolValue] == NO){
                        if (i > 0)
                            playerCoords = [movingPath[i-1][0] CGPointValue];
                        else
                            playerCoords = [array[0] CGPointValue];
                        break;
                    }
                }
            
                if (![matrix[(int)playerCoords.x][(int)playerCoords.y] isKindOfClass:[MazeNode class]]){
                    NSLog(@"player position is not a maze node?!");
                    for (NSValue *val in alignedCoords) {
                        CGPoint coords = [val CGPointValue];
                        ((MazeNode*) matrix[(int)coords.x][(int)coords.y]).object = nil;
                    }
                    [mazeControl.mazeObject.gridNodes removeAllObjects];
                    return;
                }
                
                MazeNode *endNode = [self getEndNode];
                
                [GeometryHelper solveMazeFrom:matrix[(int)playerCoords.x][(int)playerCoords.y] To:endNode Matrix:matrix];
                NSArray *path = [GeometryHelper getShortestPathFrom:matrix[(int)playerCoords.x][(int)playerCoords.y] To:endNode];
                if (path.count == 0){
                    for (NSValue *val in alignedCoords) {
                        CGPoint coords = [val CGPointValue];
                        ((MazeNode*) matrix[(int)coords.x][(int)coords.y]).object = nil;
                    }
                    [mazeControl.mazeObject.gridNodes removeAllObjects];
                    [mazeControl.mazeObject overlayWithColor:[UIColor redColor] alpha:0.6];
                }else {
                    if ([imgView isKindOfClass:[UIView class]]){
                        ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                        rect.size = mazeControl.mazeObject.containerView.frame.size;
                        mazeControl.mazeObject.containerView.frame = rect;
                    }
                    
                    for (MazeNode* node in mazeControl.mazeObject.objectNodes) {
                        [self removeDragEventsFromNode:node];
                    }
                    
                    [self recalculateAnimationFromStart:matrix[(int)playerCoords.x][(int)playerCoords.y] toEnd:endNode withStepDuration:levelInfo.stepDuration];
                }

            } else {
                if ([imgView isKindOfClass:[UIView class]]){
                    ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                    rect.size = mazeControl.mazeObject.containerView.frame.size;
                    mazeControl.mazeObject.containerView.frame = rect;
                }

            }
        }
    }
    
    
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

-(void)viewDidAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    return [super viewDidAppear:animated];
}


-(void)initGridWithSize:(CGSize)size{
    float hex_height = [SettingsStore sharedStore].hexSize * 2;
    float hex_width = sqrt(3) / 2.0 * hex_height;
    
    
    gridSize = size;

    // Custom initialization
    self.view.backgroundColor = [UIColor whiteColor];
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.view.frame];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.contentSize = CGSizeMake((hex_width * gridSize.width) - (hex_width/2), hex_height * gridSize.height);
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale=0.25;
    self.scrollView.maximumZoomScale=1.0;
    [self.view addSubview:self.scrollView];
    
    // init the containerview with the scrollview
    containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    [self.scrollView addSubview:containerView];
    
    // generate a matrix...
    matrix = [GeometryHelper generateMatrixWithWidth:gridSize.width Height:gridSize.height withImageName:@"empty.png" inContainerView:containerView];
    
    // ... and set nodes to the matrix
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]) {
                matrix[x][y] = node.uiElement;
            }
        }
    }
}

// buildLevel draw the level from the saved file
-(void)buildLevel:(LevelInfo*)info{
    
    NSMutableArray *board= info.board;
    int yOffset = info.minY.intValue % 2 == 0 ? 2 : 1;
    for (int x = 0; x < board.count; x++) {
        for (int y = 0; y <((NSArray*)board[x]).count; y++){
            
            // if this node is new
            NSNumber *nodeType = board[x][y];
            id obj = matrix[x + 1][y + yOffset];
            if ([obj isEqual:[NSNull null]])
                continue;
            
            // make a single node
            MazeNode *node = [MazeNode node];
            node.Size = [SettingsStore sharedStore].hexSize;
            node.uiElement = obj;
            node.MatrixCoords = CGPointMake(x + 1,y + yOffset);
            node.center = node.uiElement.center;
            
            // check enums of objecttypes for this node
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
            
            // otherwise it is a wall
            if (nodeType.intValue == 0)
                matrix[x + 1][y + yOffset] = node.uiElement;
            else
                matrix[x + 1][y + yOffset] = node;
        }
    }
    
    // draw the 4 kinds of the 11 walltypes...
    NSMutableArray *wallNodes = [NSMutableArray array];
    objCounts = [NSMutableArray array];
    objNodes = [NSMutableArray array];
    for (NSNumber *key in info.walls) {
        for (int i = 0; i < [[info.walls objectForKey:key]intValue]; i++) {
            MazeObject *obj;
            if (key.intValue == 0){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
            }else if (key.intValue == 1){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,1)]];
            }else if (key.intValue == 2){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
            }else if (key.intValue == 3){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(2,0)]];
            }else if (key.intValue == 4){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,2)]];
            }else if (key.intValue == 5){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,2)]];
            }else if (key.intValue == 6){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(2,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(3,0)]];
            }else if (key.intValue == 7){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,-1)]];
            }else if (key.intValue == 8){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(2,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,-1)]];
            }else if (key.intValue == 9){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,-1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-2,2)]];
            }else if (key.intValue == 10){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,-1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-2,-2)]];
            }
            // add the nodes to a wallobject for the objectNodes
            [objNodes addObject:obj];
        }
    }
    
    // ...and make them draggable
    for (MazeNode *wallNode in wallNodes) {
        [self addDragEventsToNode:wallNode];
    }
    
    [self initToolbarObjects];
}

-(void)initToolbarObjects{
    
    /*
     Alternative Code:
    
    NSMutableArray* categoryArray = [NSMutableArray array];
    NSMutableArray* objNodesTmp = [NSMutableArray arrayWithArray:objNodes];
    while(objNodesTmp.count > 0){
        MazeObject* firstObject = [objNodesTmp firstObject];
        [objNodesTmp removeObject:firstObject];
        NSMutableArray* removeTmp = [NSMutableArray array];
        for (MazeObject* object in objNodesTmp) {
            if([GeometryHelper compareWallObject:firstObject compareWith:object]){
                [removeTmp addObject:object];
            }
        }
        for (MazeObject* object in removeTmp) {
            [objNodesTmp removeObject:object];
        }
        NSMutableArray* array = [NSMutableArray arrayWithObject:firstObject];
        [array addObjectsFromArray:removeTmp];
        [categoryArray addObject:array];
    }
    
    */
    
    // calculate how many different types of categories are given (0-4)
    differentObjectsCounter = objNodes.count;
    for(int i = 0; i < objNodes.count; i++){
        for(int j = i+1; j < objNodes.count; j++){
            if([GeometryHelper compareWallObject:(MazeObject*)objNodes[i] compareWith:(MazeObject*)objNodes[j]]){
                differentObjectsCounter--;
                break;
            }
            
        }
    }
    
    // atfer that we calculate which wallobjects belong to which category
    int categoryCounter = 0;
    for (int i = 0; i < objNodes.count; i++) {
        if(i == 0){
            // the first object gets the category 0
            ((MazeObject*)objNodes[i]).category = categoryCounter;
        }else{
            bool sameCategory = NO;
            for (int j = i-1; j>= 0; j--) {
                // if a previos object is the same, this one gets the same category
                if([GeometryHelper compareWallObject:(MazeObject*)objNodes[j] compareWith:(MazeObject*)objNodes[i]]){
                    ((MazeObject*)objNodes[i]).category = ((MazeObject*)objNodes[j]).category;
                    sameCategory = YES;
                }
            }
            // if not, it gets a new category and the counter is increased
            if(!sameCategory){
                categoryCounter++;
                if(i < objNodes.count){
                    ((MazeObject*)objNodes[i]).category = categoryCounter;
                }
            }
        }
    }
    
    // scale the wallobjects to the size of their category
    for (MazeObject* objects in objNodes) {
        for (MazeNode *node in objects.gridNodes) {
            node.object = nil;
        }
        [GeometryHelper scaleToToolbar:objects withLength:@"height"];
        [GeometryHelper scaleToToolbar:objects withLength:@"width"];
    }
    [self initToolbarItems];
    
    // remove red overlay
    for (MazeObject* objects in objNodes) {
        [objects removeOverlay];
        objects.toolbarItem = YES;
        [self.toolBarView addSubview:objects.containerView];
    }
}

// init the toolbar
-(void)initToolbar{
    int toolbarHeight = [SettingsStore sharedStore].toolbarHeight;
    self.toolBarView = [[UIView alloc]initWithFrame:CGRectMake(-5, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight)];
    self.toolBarView.backgroundColor = [UIColor clearColor];
    UIImage *backgroundImg = [UIImage imageNamed:@"toolbar.png"];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:backgroundImg];
    imgView.frame = CGRectMake(0, 0, self.toolBarView.frame.size.width + 5, self.toolBarView.frame.size.height);
    [self.toolBarView addSubview:imgView];
    [self.view addSubview:self.toolBarView];
}

// draw the borders for the categories and sets the centerpoints of the wallobjects
-(void)initToolbarItems{
    toolbarItems = [NSMutableArray array];
    toolbarItemsLabel = [NSMutableArray array];
    int itemSize = [SettingsStore sharedStore].toolbarHeight-30 ;
    for(int i = 0; i < differentObjectsCounter; i++){
        objCounts[i] = [NSNumber numberWithInt:0];
        
        // borders
        toolbarItems[i] = [[UIView alloc] initWithFrame:CGRectMake(10+i*(itemSize+10), self.toolBarView.frame.size.height/2-itemSize/2+10, itemSize, itemSize)];
        [((UIView*)toolbarItems[i]).layer setBorderWidth:1.0];
        [((UIView*)toolbarItems[i]).layer setBorderColor:[UIColor blackColor].CGColor];
        [self.toolBarView addSubview:toolbarItems[i]];
        
        // counter for the categories
        UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake(((UIView*)toolbarItems[i]).frame.size.width-15, ((UIView*)toolbarItems[i]).frame.size.height-15, 15, 15)];
        [label setBackgroundColor:[UIColor blackColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setFont:[UIFont boldSystemFontOfSize:12]];
        label.textAlignment = NSTextAlignmentCenter;
        
        // centerpoints
        for (MazeObject* items in objNodes) {
            if(items.category == i){
                objCounts[i] = [NSNumber numberWithInt:[objCounts[i] intValue]+1];
                items.containerView.center = CGPointMake(((UIView*)toolbarItems[items.category]).frame.size.width/2+10+items.category*(itemSize+10), ((UIView*)toolbarItems[items.category]).frame.size.height/2+self.toolBarView.frame.size.height/2-itemSize/2+10);
            }
        }
        
        // set counter as label
        [label setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:[objCounts[i] intValue]]]];
        [toolbarItemsLabel addObject:label];
        [((UIView*)toolbarItems[i]) addSubview:label];
    }
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint.x -= scrollViewOffset.x;
    touchPoint.y -= scrollViewOffset.y;
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    CGPoint matrixCoords = [GeometryHelper pixelToHex:touchPoint gridSize:gridSize];
    NSLog(@"touch down: (x:%.0f,y:%.0f)", matrixCoords.x, matrixCoords.y);
    
    return;
    
    MazeNode *node = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    if (pathView) {
        [pathView removeFromSuperview];
        pathView = nil;
    }
    
    if (![node isEqual:[NSNull null]]) {
        if (node.object == nil) {
            
            MazeObject *wall = [MazeObject objectWithType:COIN andCenter:CGPointMake(node.center.x, node.center.y)];
            MazeNode *nn = [wall generateAndAddNodeRelative:CGPointMake(0,0)];
            [self addDragEventsToNode:nn];
            node.object = wall;
            [containerView addSubview:wall.containerView];
            
        }else if (node.object.type == START){
            
            MazeNode *endNode = nil;
            for (int x = 0; x < matrix.count; x++) {
                for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
                    MazeNode *tmpNode = matrix[x][y];
                    if (![tmpNode isEqual:[NSNull null]]) {
                        if (tmpNode.object != nil && tmpNode.object.type == END)
                            endNode = tmpNode;
                    }
                }
            }
            
            [self animatePathFromStart:node toEnd:endNode withStepDuration:levelInfo.stepDuration];
            
        }
    }
}

-(void)animatePathFromStart:(MazeNode*)start toEnd:(MazeNode*)end withStepDuration:(float)duration{
    
    // set bools for animation
    animationStarted = YES;
    animationComplete = YES;
    
    // set the step counter
    menubar.steps = 0;
    
    // make the path
    pathView = [[UIBezierView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width * 1/self.scrollView.zoomScale, self.scrollView.contentSize.height * 1/self.scrollView.zoomScale)];
    movingPath = [NSMutableArray array];
    previousPath = [NSMutableArray array];
    
    // draw the figure
    UIImage *movingImage = [UIImage imageNamed:@"hex_small_red.png"];
    movingView = [[UIImageView alloc]initWithImage:movingImage];
    [pathView addSubview:movingView];
    
    lastWayPoint = start.MatrixCoords;
    [self recalculateAnimationFromStart:start toEnd:end withStepDuration:duration];
}

-(void)recalculateAnimationFromStart:(MazeNode*)start toEnd:(MazeNode*)end withStepDuration:(float)duration{
    /*
    if (!animationComplete){
        movingView.frame = [[movingView.layer presentationLayer] frame];
        CAAnimation *animation = [movingView.layer animationForKey:@"movingAnimation"];
        NSLog(@"animation class: %@", animation.class);
            interrupted = YES;
        [movingView.layer removeAnimationForKey:@"movingAnimation"];
    }*/
    
    
    
    // get the shortest path
    [GeometryHelper solveMazeFrom:start To:end Matrix:matrix];
    NSArray *shortestPath = [GeometryHelper getShortestPathFrom:start To:end];
    if (shortestPath.count == 0)
        return;
    
    // check if there is a wall in this path
    bool foundWall = NO;
    for (MazeNode* node in shortestPath) {
        if(node.isWall) {
            NSLog(@"isWall at position: %@", [NSValue valueWithCGPoint:node.MatrixCoords]);
            foundWall = YES;
        }
    }
    
    // draw the path
    UIBezierPath *bezierMovingPath = [UIBezierPath bezierPath];
    for (int i = 0; i < shortestPath.count; i++) {
        
        MazeNode *node = shortestPath[i];
        if (i == 0)
            [bezierMovingPath moveToPoint:node.center];
        else
            [bezierMovingPath addLineToPoint:node.center];
        
    }
    
    int delIndex = 0;
    for (NSMutableArray *array in movingPath) {
        if ([array[1] boolValue] == NO){
            break;
        }
        delIndex++;
    }
    
    NSMutableArray *movingPathTmp = [NSMutableArray arrayWithArray:movingPath];
    if (delIndex > 0)
        [movingPathTmp removeObjectsAtIndexes:[NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(delIndex, movingPathTmp.count - delIndex)]];
    
    for (int i = 0; i < shortestPath.count; i++) {
        MazeNode *val = shortestPath[i];
        if (i == 0){
            [movingPathTmp addObject:[NSMutableArray arrayWithObjects:[NSValue valueWithCGPoint:val.MatrixCoords], [NSNumber numberWithBool:YES], nil]];
        }else {
            [movingPathTmp addObject:[NSMutableArray arrayWithObjects:[NSValue valueWithCGPoint:val.MatrixCoords], [NSNumber numberWithBool:NO], nil]];
        }
    }
    
    NSArray *lastArray;
    int delIndex2 = -1;
    for (int i = 0; i < movingPathTmp.count; i++) {
        NSArray *arr = movingPathTmp[i];
        
        if (lastArray){
            if ([arr[0] CGPointValue].x == [lastArray[0] CGPointValue].x &&
                [arr[0] CGPointValue].y == [lastArray[0] CGPointValue].y ){
                delIndex2 = i;
                break;
            }
        }
        
        lastArray = arr;
    }
    
    if (delIndex2 > -1)
        [movingPathTmp removeObjectAtIndex:delIndex2];
    
    if (movingPath.count > 0 && movingPath.count == movingPathTmp.count){
        bool same = YES;
        for (int i = 0; i < movingPath.count; i++) {
            CGPoint p1 = [movingPath[i][0] CGPointValue];
            CGPoint p2 = [movingPathTmp[i][0] CGPointValue];
            if (!CGPointEqualToPoint(p1, p2)){
                same = NO;
                break;
            }
        }
        if (same)
            return;
        else {
            if (!animationComplete){
                movingView.frame = [[movingView.layer presentationLayer] frame];
                CAAnimation *animation = [movingView.layer animationForKey:@"movingAnimation"];
                NSLog(@"animation class: %@", animation.class);
                interrupted = YES;
                [movingView.layer removeAnimationForKey:@"movingAnimation"];
            }
            
        }
    }
    
    movingPath = [NSMutableArray arrayWithArray:movingPathTmp];

    UIBezierPath *bezierDrawingPath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < movingPath.count; i++) {
        NSArray *array = movingPath[i];
        MazeNode *node = matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y];
        if (i == 0){
            [bezierDrawingPath moveToPoint:node.center];
        }else {
            [bezierDrawingPath addLineToPoint:node.center];
        }
    }

    pathView.curvePath = bezierDrawingPath;
    [containerView addSubview:pathView];
    [pathView setNeedsDisplay];
 
 
    animationComplete = NO;

    NSLog(@"duration: %.2f", duration);
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.duration = shortestPath.count * duration;
    pathAnimation.path = bezierMovingPath.CGPath;
    pathAnimation.calculationMode = kCAAnimationLinear;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (!interrupted) {
            if ([movingPath[movingPath.count-1][1] boolValue]){
                [menubar resetButton];
            }
            
            //animationComplete = YES;
            
            for (int i = 0; i < movingPath.count; i++) {
                if ([movingPath[i][1] boolValue] == NO || i == movingPath.count -1){
                    MazeNode *node = matrix[(int)[movingPath[i][0] CGPointValue].x][(int)[movingPath[i][0] CGPointValue].y];
                    
                    movingView.center = node.center;
                    break;
                }
            }
            paused = NO;
        }else {
            interrupted = NO;
        }
        if ([movingPath[movingPath.count-1][1] boolValue]){
            [self gameOver];
        }
        
    }];
    [movingView.layer addAnimation:pathAnimation forKey:@"movingAnimation"];
    [CATransaction commit];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
        // while the level has not ended
        while (!animationComplete) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                @try {
                    CGPoint matrixPoint = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                    int steps = 0;
                    int coins = 0;
                    int i = 0;
                    for (NSMutableArray *array in movingPath) {
                        if ([array[1] boolValue] == NO){
                            if (CGPointEqualToPoint([array[0] CGPointValue], matrixPoint)){
                                array[1] = [NSNumber numberWithBool:YES];
                                if (previousPath.count > 0 && !CGPointEqualToPoint([previousPath[previousPath.count - 1]CGPointValue], matrixPoint))
                                    [previousPath addObject:[NSValue valueWithCGPoint:matrixPoint]];
                                else if (previousPath.count == 0)
                                    [previousPath addObject:[NSValue valueWithCGPoint:matrixPoint]];
                            }
                            break;
                        }else if (i > 0){
                            // Increment the step counter
                            steps++;
                        }
                        
                        // if there is a coin on the path, we increment the coin counter
                        MazeNode *node = matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y];
                        if (![node isEqual:[NSNull null]] &&
                            [node isKindOfClass:[MazeNode class]] && node.object && node.object.type == COIN){
                            coins++;
                        }
                        i++;
                    }
                    
                    menubar.steps = steps;
                    menubar.coins = coins;
                    
                    if (matrixPoint.x == end.MatrixCoords.x && matrixPoint.y == end.MatrixCoords.y){
                        animationStarted = NO;
                    }
                }
                @catch (NSError *error) {
                    NSLog(@"error: %@",error);
                }
            });
            usleep(pathAnimation.duration / shortestPath.count / 10.0 * 1000 * 1000);
        }
    });
    

}

// add all drag events to every single node of the wallobjects
-(void)addDragEventsToNode:(MazeNode*)node{
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
}

// remove all drag events to every single node of the wallobjects
-(void)removeDragEventsFromNode:(MazeNode*)node{
    [(UIMazeControl*)node.uiElement removeTarget:self action:@selector(itemDragBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
    [(UIMazeControl*)node.uiElement removeTarget:self action:@selector(itemMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [(UIMazeControl*)node.uiElement removeTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [(UIMazeControl*)node.uiElement removeTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
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
    contentsFrame.origin.y += 40;
    
    scrollViewOffset.x = contentsFrame.origin.x;
    scrollViewOffset.y = contentsFrame.origin.y;
    
    containerView.frame = contentsFrame;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// function for the game over screen at the end of a game
-(void)gameOver {
    // initializes and displays game over view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect area = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
    gameOverView = [[UIView alloc]initWithFrame:area];
    gameOverView.backgroundColor = [UIColor colorWithWhite:0.333 alpha:0.750];
    
    // game over label
    UILabel* gameOverLabel =[[UILabel alloc]initWithFrame:CGRectMake(0, 50, area.size.width, 50)];
    [gameOverLabel setText:@"Game over!"];
    [gameOverLabel setTextColor:[UIColor whiteColor]];
    [gameOverLabel setTextAlignment:NSTextAlignmentCenter];
    [gameOverLabel setFont: [UIFont fontWithName:@"Chalkduster" size:33.0]];
    [gameOverView addSubview:gameOverLabel];
    
    // check if the highscore needs to be updated
    if(menubar.steps > levelInfo.highScore){
        // new highscore label
        UILabel* newHighscore =[[UILabel alloc]initWithFrame:CGRectMake(140, 35, 250, 45)];
        [newHighscore setText:@"NEW HIGHSCORE"];
        [newHighscore setTextColor:[UIColor whiteColor]];
        [newHighscore setBackgroundColor:[UIColor redColor]];
        [newHighscore setTextAlignment:NSTextAlignmentCenter];
        [newHighscore setFont: [UIFont fontWithName:@"Chalkduster" size:15.0]];
        newHighscore.transform = CGAffineTransformMakeRotation(M_PI/4.0);
        [gameOverView addSubview:newHighscore];
    }
    
    // label for steps
    UILabel* descriptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 150, area.size.width, 50)];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    NSString *description = [NSString stringWithFormat:@"Steps: %i",menubar.steps];
    [descriptionLabel setFont: [UIFont fontWithName:@"System Bold" size:22.0]];
    [descriptionLabel setText:description];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [gameOverView addSubview:descriptionLabel];
    
    // label for coins
    UILabel* descriptionLabel2 = [[UILabel alloc]initWithFrame:CGRectMake(0, 200, area.size.width, 50)];
    [descriptionLabel2 setTextAlignment:NSTextAlignmentCenter];
    NSString *description2 = [NSString stringWithFormat:@"Coins: %i",menubar.coins];
    [descriptionLabel2 setFont: [UIFont fontWithName:@"System Bold" size:22.0]];
    [descriptionLabel2 setText:description2];
    [descriptionLabel2 setTextColor:[UIColor whiteColor]];
    [gameOverView addSubview:descriptionLabel2];
    
    // button to get to the startscreen
    UIButton* homeButton = [[UIButton alloc]initWithFrame:CGRectMake(area.size.width/2-60, 390, 120, 40)];
    homeButton.backgroundColor = [UIColor darkGrayColor];
    [homeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [homeButton setTitle:@"Home" forState:UIControlStateNormal];
    homeButton.layer.borderColor = [UIColor whiteColor].CGColor;
    homeButton.layer.borderWidth = 2.0f;
    [homeButton addTarget:self action:@selector(backtoHome) forControlEvents:UIControlEventTouchUpInside];
    [gameOverView addSubview:homeButton];
    
    // button to play the game again
    UIButton* resetButton = [[UIButton alloc]initWithFrame:CGRectMake(area.size.width/2-60, 300, 120, 40)];
    resetButton.backgroundColor = [UIColor darkGrayColor];
    [resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [resetButton setTitle:@"Play again" forState:UIControlStateNormal];
    resetButton.layer.borderColor = [UIColor whiteColor].CGColor;
    resetButton.layer.borderWidth = 2.0f;
    [resetButton addTarget:self action:@selector(playAgain) forControlEvents:UIControlEventTouchUpInside];
    [gameOverView addSubview:resetButton];
    
    // save the descriptions and update the highscore
    levelInfo.highScore = menubar.steps;
    levelInfo.highScoreCoins = menubar.coins;
    [[LevelManager sharedManager] saveLevel:levelInfo forID:levelInfo.ID];
    
    [self.view addSubview:gameOverView];
}

// function for home button
-(void) backtoHome {
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

// function to play again
-(void) playAgain{
    [self->gameOverView removeFromSuperview];
}

// get the node with the goal of the labyrinth
-(MazeNode*)getEndNode{
    MazeNode *endNode = nil;
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *tmpNode = matrix[x][y];
            if (![tmpNode isEqual:[NSNull null]] && [tmpNode isKindOfClass:[MazeNode class]]) {
                if (tmpNode.object != nil && tmpNode.object.type == END)
                    endNode = tmpNode;
            }
        }
    }
    return endNode;
}

@end
