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
                
                [self animatePathFromStart:startNode toEnd:endNode withStepDuration:1];
                }else {
                    movingView.layer.speed = 1.0;
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
        
        
        //CGRect frame =  obj1.containerView.frame;
        //frame.origin.y = 0;
        //obj1.containerView.frame = frame;
        
        //[obj2 flashView:[UIColor redColor] times:5];
        
        overlayRects = [NSMutableArray array];
        
        lastX = 0.0;
        lastY = 0.0;
        
    }
    return self;
}

//TODO: Remove object from grid when dragging..

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
    
    //NSLog(@"Touch point(x:%.0f,y:%.0f)",point.x,point.y);
    
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
                    node.object = nil;
                }
                [mazeControl.mazeObject.gridNodes removeAllObjects];
                
                if (!animationComplete && animationStarted){
                    CGPoint playerCoords = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                    //NSLog(@"Matrix: (%.2f,%.2f)",playerCoords.x, playerCoords.y);
                    if (![matrix[(int)playerCoords.x][(int)playerCoords.y] isKindOfClass:[MazeNode class]]){
                        NSLog(@"player position is not a maze node?!");
                        
                        return;
                    }
                    
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
                    
                    [self recalculateAnimationFromStart:matrix[(int)playerCoords.x][(int)playerCoords.y] toEnd:endNode withStepDuration:1];
                    
                }
            }
        }
        touchedDown = NO;
    }
    
    if ([control isKindOfClass:[UIMazeControl class]]){
        UIMazeControl *mazeControl = (UIMazeControl*)control;
        
        [self.view addSubview:mazeControl.mazeObject.containerView];
        
        //point.x -= scrollViewOffset.x;
        //point.y -= scrollViewOffset.y;
        
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
        
       // NSLog(@"%@",nodeRects);
        
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
            [mazeControl.mazeObject overlayWithColor:[UIColor redColor] alpha:0.6];
        }else {
            [mazeControl.mazeObject removeOverlay];
        }
        
        
        /*
        for (UIView *view in overlayRects) {
            [view removeFromSuperview];
        }
        
        [overlayRects removeAllObjects];
        for (NSValue *val in nodeRects) {
            CGRect rect = [val CGRectValue];
            UIView *view = [[UIView alloc]initWithFrame:rect];
            view.layer.borderColor = [UIColor blackColor].CGColor;
            view.layer.borderWidth = 5.0f;
            [containerView addSubview:view];
            [overlayRects addObject:view];
        }
         */
        
        /*
        NSArray *dropCoords = [GeometryHelper alignToGrid:mazeControl.mazeObject Matrix:matrix TopLeft:CGPointMake(rect2.origin.x, rect2.origin.y)];
        
        NSLog(@"%@",dropCoords);
        bool flash = NO;
        for (NSValue *val in dropCoords) {
            CGPoint p = [val CGPointValue];
            if ([GeometryHelper isValidMatrixCoord:p Matrix:matrix]){
                
                
                MazeNode *node = matrix[(int)p.x][(int)p.y];
                
                if (node && !node.object){
                    if (animationStarted){
                        CGPoint matrixPoint = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position]gridSize:gridSize];
                        if (p.x == matrixPoint.x && p.y == matrixPoint.y) {
                            flash = YES;
                            break;
                        }
                    }
                }else {
                    flash = YES;
                    break;
                }
            }else {
                flash = YES;
            }
        }
        if(flash){
            [mazeControl.mazeObject overlayWithColor:[UIColor redColor] alpha:0.7];
        }else {
            [mazeControl.mazeObject removeOverlay];
        }*/
        
    }
    /*
     [self.view addSubview:control];
     control.center = point;
     */
    
    if (lastDragPoint.y <= self.view.frame.size.height - 100 &&
        point.y > self.view.frame.size.height - 100) {
        NSLog(@"crossed border to toolbar");
        if ([control isKindOfClass:[UIMazeControl class]]){
            UIMazeControl *mazeControl = (UIMazeControl*)control;
            
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
        NSLog(@"crossed border to game field");
        float scaleFactor = self.scrollView.zoomScale;
        
        if ([control isKindOfClass:[UIMazeControl class]]){
            UIMazeControl *mazeControl = (UIMazeControl*)control;
            
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
    lastDragPoint = point;
    
}

// called when the finger is lifted, hence ending the drag action
- (IBAction) itemDragExit:(id) sender withEvent:(UIEvent *) event {
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    UIControl *control = sender;
    if ([control isKindOfClass:[UIMazeControl class]]){
        UIMazeControl *mazeControl = (UIMazeControl*)control;
        if (point.y > self.view.frame.size.height - 100){
            NSLog(@"Dropped on toolbar");
            int itemSize = [SettingsStore sharedStore].toolbarHeight-30 ;
           // point = [[[event allTouches] anyObject] locationInView:self.toolBarView];
           // [mazeControl.mazeObject.containerView removeFromSuperview];
            [GeometryHelper scaleToToolbar:mazeControl.mazeObject withLength:@"height"];
            [GeometryHelper scaleToToolbar:mazeControl.mazeObject withLength:@"width"];
            [mazeControl.mazeObject removeOverlay];
            point = CGPointMake(((UIView*)toolbarItems[mazeControl.mazeObject.category]).frame.size.width/2+10+mazeControl.mazeObject.category*(itemSize+10), ((UIView*)toolbarItems[mazeControl.mazeObject.category]).frame.size.height/2+self.toolBarView.frame.size.height/2-itemSize/2+10);
            mazeControl.mazeObject.containerView.center = point;
            
            [self.toolBarView addSubview:mazeControl.mazeObject.containerView];

            if(!mazeControl.mazeObject.toolbarItem){
                mazeControl.mazeObject.toolbarItem = YES;
                int tmpCount = [((UILabel*)toolbarItemsLabel[mazeControl.mazeObject.category]).text intValue];
                [(UILabel*)toolbarItemsLabel[mazeControl.mazeObject.category] setText:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:tmpCount+1]]];
            }
        } else {
            NSLog(@"Dropped on game field");
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
            UIView *imgView = mazeControl.mazeObject.containerView;
            if ([imgView isKindOfClass:[UIView class]]){
                ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                mazeControl.mazeObject.containerView.center = point;
            }
            
            CGRect containerRect = mazeControl.mazeObject.containerView.frame;
            
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
            
            //NSLog(@"%@",alignedCoords);
            [mazeControl.mazeObject removeOverlay];
            
            
            // set the the object variable of the grid nodes
            for (NSValue *val in alignedCoords) {
                CGPoint coords = [val CGPointValue];
                ((MazeNode*) matrix[(int)coords.x][(int)coords.y]).object = mazeControl.mazeObject;
                [mazeControl.mazeObject.gridNodes addObject:matrix[(int)coords.x][(int)coords.y] ];
            }
            
            
            if (!animationComplete && animationStarted){
                CGPoint playerCoords = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                if (![matrix[(int)playerCoords.x][(int)playerCoords.y] isKindOfClass:[MazeNode class]]){
                    NSLog(@"player position is not a maze node?!");
                    for (NSValue *val in alignedCoords) {
                        CGPoint coords = [val CGPointValue];
                        ((MazeNode*) matrix[(int)coords.x][(int)coords.y]).object = nil;
                    }
                    [mazeControl.mazeObject.gridNodes removeAllObjects];
                    return;
                }
               // NSLog(@"Matrix: (%.2f,%.2f)",playerCoords.x, playerCoords.y);
                
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
                    
                    [self recalculateAnimationFromStart:matrix[(int)playerCoords.x][(int)playerCoords.y] toEnd:endNode withStepDuration:1];
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
    
    containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    [self.scrollView addSubview:containerView];
    
    matrix = [GeometryHelper generateMatrixWithWidth:gridSize.width Height:gridSize.height withImageName:@"empty.png" inContainerView:containerView];
    
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]) {
                matrix[x][y] = node.uiElement;
            }
        }
    }
    /*
     while (true) {
        CGPoint startP =  CGPointMake(arc4random()%(int)gridSize.width,arc4random()%(int)gridSize.height);
        CGPoint endP =  CGPointMake(arc4random()%(int)gridSize.width,arc4random()%(int)gridSize.height);
        
        MazeNode *nodeStart = (MazeNode*)matrix[(int)startP.x][(int)startP.y];
        MazeNode *nodeEnd = (MazeNode*)matrix[(int)endP.x][(int)endP.y];
        
        
        if (![nodeStart isEqual:[NSNull null]] && ![nodeEnd isEqual:[NSNull null]] && !(startP.x == endP.x && startP.y == endP.y)
            && [GeometryHelper distanceFromHex:startP toHex:endP] > 10){
            
            MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(nodeStart.center.x, nodeStart.center.y)];
            [start generateAndAddNodeRelative:CGPointMake(0,0)];
            [start.gridNodes addObject:nodeStart];
            
            MazeObject *end = [MazeObject objectWithType:END andCenter:CGPointMake(nodeEnd.center.x, nodeEnd.center.y)];
            [end generateAndAddNodeRelative:CGPointMake(0,0)];
            [end.gridNodes addObject:nodeEnd];
            
            nodeStart.object = start;
            nodeEnd.object = end;
            
            [containerView addSubview:start.containerView];
            [containerView addSubview:end.containerView];
            
            break;
        }
        
    }*/
}

-(void)buildLevel:(LevelInfo*)info{
    
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
    
    NSMutableArray *wallNodes = [NSMutableArray array];
    objCounts = [NSMutableArray array];
    objNodes = [NSMutableArray array];
    for (NSNumber *key in info.walls) {
        for (int i = 0; i < [[info.walls objectForKey:key]intValue]; i++) {
            MazeObject *obj;
            if (key.intValue == 0){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
            }else if (key.intValue == 1){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,2)]];
            }else if (key.intValue == 2){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
            }else if (key.intValue == 3){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,2)]];
            }else if (key.intValue == 4){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,1)]];
            }else if (key.intValue == 5){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-2,2)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
            }else if (key.intValue == 6){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,2)]];
            }else if (key.intValue == 7){
                obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,1)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,2)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,3)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(2,3)]];
                [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(2,4)]];
            }
            [objNodes addObject:obj];
        }
    }
    
    
    for (MazeNode *wallNode in wallNodes) {
        [self addDragEventsToNode:wallNode];
    }
    
    [self initToolbarObjects];
    
    
     /*
    
    NSMutableArray *wallNodes = [NSMutableArray array];
    objCounts = [NSMutableArray array];
    objNodes = [NSMutableArray array];
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
    
    MazeObject *obj4 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj4 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj4 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj4 generateAndAddNodeRelative:CGPointMake(0,2)]];
    [objNodes addObject:obj4];
    
    MazeObject *obj6 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj6 generateAndAddNodeRelative:CGPointMake(-1,2)]];
    [objNodes addObject:obj6];
    MazeObject *obj3 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(0,1)]];
    [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(0,2)]];
    [objNodes addObject:obj3];
    MazeObject *obj5 = [MazeObject objectWithType:WALL andCenter:CGPointMake(0,0)];
    [wallNodes addObject:[obj5 generateAndAddNodeRelative:CGPointMake(0,0)]];
    [wallNodes addObject:[obj5 generateAndAddNodeRelative:CGPointMake(1,0)]];
    [objNodes addObject:obj5];
    
     [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,4)]];
     [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,4)]];
     [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,-1)]];
    
    
    for (MazeNode *wallNode in wallNodes) {
        [self addDragEventsToNode:wallNode];
    }
    
    differentObjectsCounter = objNodes.count;
    for(int i = 0; i < objNodes.count; i++){
        for(int j = i+1; j < objNodes.count; j++){
            if([GeometryHelper compareWallObject:(MazeObject*)objNodes[i] compareWith:(MazeObject*)objNodes[j]]){
                differentObjectsCounter--;
                break;
            }
            
        }
    }
    
    int categoryCounter = 0;
    for (int i = 0; i < objNodes.count; i++) {
        if(i == 0){
            ((MazeObject*)objNodes[i]).category = categoryCounter;
        }else{
            bool sameCategory = NO;
            for (int j = i-1; j>= 0; j--) {
                if([GeometryHelper compareWallObject:(MazeObject*)objNodes[j] compareWith:(MazeObject*)objNodes[i]]){
                    ((MazeObject*)objNodes[i]).category = ((MazeObject*)objNodes[j]).category;
                    //   NSLog(@"i: %i, j: %i, differentObejctsCounter: %i",i,j,differentObjectsCounter);
                    //   NSLog(@"category-j: %i, category-i: %i",((MazeObject*)objNodes[j]).category,((MazeObject*)objNodes[i]).category);
                    sameCategory = YES;
                }
            }
            if(!sameCategory){
                categoryCounter++;
                if(i < objNodes.count){
                    ((MazeObject*)objNodes[i]).category = categoryCounter;
                    //  NSLog(@"category-i: %i",((MazeObject*)objNodes[i]).category);
                }
            }
        }
    }
    
    /*
    for(int i = 0; i <= differentObjectsCounter; i++){
        NSLog(@"i ist: %i",i);
        if(i == 0){
            ((MazeObject*)objNodes[i]).category = categoryCounter;
        }else{
            bool sameCategory = NO;
            for(int j = i-1; j >= 0; j--){
                
                if(i > differentObjectsCounter){
                    break;
                }
                if([GeometryHelper compareWallObject:(MazeObject*)objNodes[j] compareWith:(MazeObject*)objNodes[i]]){
                    ((MazeObject*)objNodes[i]).category = ((MazeObject*)objNodes[j]).category;
                 //   NSLog(@"i: %i, j: %i, differentObejctsCounter: %i",i,j,differentObjectsCounter);
                 //   NSLog(@"category-j: %i, category-i: %i",((MazeObject*)objNodes[j]).category,((MazeObject*)objNodes[i]).category);
                    sameCategory = YES;
                }
            }
            if(!sameCategory){
                categoryCounter++;
                if(i < objNodes.count){
                    ((MazeObject*)objNodes[i]).category = categoryCounter;
                  //  NSLog(@"category-i: %i",((MazeObject*)objNodes[i]).category);
                }
            }
            
        }
    }
     
    for (MazeObject* objects in objNodes) {
        [GeometryHelper scaleToToolbar:objects withLength:@"height"];
        [GeometryHelper scaleToToolbar:objects withLength:@"width"];
    }
    [self initToolbarItems];
    [self.toolBarView addSubview:obj1.containerView];
    [self.toolBarView addSubview:obj2.containerView];
    [self.toolBarView addSubview:obj3.containerView];
    [self.toolBarView addSubview:obj4.containerView];
    [self.toolBarView addSubview:obj5.containerView];
    [self.toolBarView addSubview:obj6.containerView];
     */
}

-(void)initToolbarObjects{
    differentObjectsCounter = objNodes.count;
    for(int i = 0; i < objNodes.count; i++){
        for(int j = i+1; j < objNodes.count; j++){
            if([GeometryHelper compareWallObject:(MazeObject*)objNodes[i] compareWith:(MazeObject*)objNodes[j]]){
                differentObjectsCounter--;
                break;
            }
            
        }
    }
    int categoryCounter = 0;
    for (int i = 0; i < objNodes.count; i++) {
        if(i == 0){
            ((MazeObject*)objNodes[i]).category = categoryCounter;
        }else{
            bool sameCategory = NO;
            for (int j = i-1; j>= 0; j--) {
                if([GeometryHelper compareWallObject:(MazeObject*)objNodes[j] compareWith:(MazeObject*)objNodes[i]]){
                    ((MazeObject*)objNodes[i]).category = ((MazeObject*)objNodes[j]).category;
                    sameCategory = YES;
                }
            }
            if(!sameCategory){
                categoryCounter++;
                if(i < objNodes.count){
                    ((MazeObject*)objNodes[i]).category = categoryCounter;
                }
            }
        }
    }
    
    for (MazeObject* objects in objNodes) {
        for (MazeNode *node in objects.gridNodes) {
            node.object = nil;
        }
        [GeometryHelper scaleToToolbar:objects withLength:@"height"];
        [GeometryHelper scaleToToolbar:objects withLength:@"width"];
    }
    [self initToolbarItems];
    for (MazeObject* objects in objNodes) {
        [objects removeOverlay];
        objects.toolbarItem = YES;
        [self.toolBarView addSubview:objects.containerView];
    }
}

-(void)initToolbar{
    int toolbarHeight = [SettingsStore sharedStore].toolbarHeight;
    self.toolBarView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight)];
    self.toolBarView.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
    self.toolBarView.backgroundColor = [UIColor clearColor];
    UIImage *backgroundImg = [UIImage imageNamed:@"toolbar.png"];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:backgroundImg];
    imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView.contentSize.width + 200, self.toolBarView.contentSize.height);
    
    [self.toolBarView addSubview:imgView];
    [self.view addSubview:self.toolBarView];
}

-(void)initToolbarItems{
    toolbarItems = [NSMutableArray array];
    toolbarItemsLabel = [NSMutableArray array];
    int itemSize = [SettingsStore sharedStore].toolbarHeight-30 ;
    for(int i = 0; i < differentObjectsCounter; i++){
        objCounts[i] = [NSNumber numberWithInt:0];
        
        toolbarItems[i] = [[UIView alloc] initWithFrame:CGRectMake(10+i*(itemSize+10), self.toolBarView.frame.size.height/2-itemSize/2+10, itemSize, itemSize)];
        [((UIView*)toolbarItems[i]).layer setBorderWidth:1.0];
        [((UIView*)toolbarItems[i]).layer setBorderColor:[UIColor blackColor].CGColor];
        [self.toolBarView addSubview:toolbarItems[i]];
        UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake(((UIView*)toolbarItems[i]).frame.size.width-15, ((UIView*)toolbarItems[i]).frame.size.height-15, 15, 15)];
        [label setBackgroundColor:[UIColor blackColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setFont:[UIFont boldSystemFontOfSize:12]];
        label.textAlignment = NSTextAlignmentCenter;
        for (MazeObject* items in objNodes) {
            if(items.category == i){
                objCounts[i] = [NSNumber numberWithInt:[objCounts[i] intValue]+1];
                items.containerView.center = CGPointMake(((UIView*)toolbarItems[items.category]).frame.size.width/2+10+items.category*(itemSize+10), ((UIView*)toolbarItems[items.category]).frame.size.height/2+self.toolBarView.frame.size.height/2-itemSize/2+10);
                //NSLog(@"center: (x:%.0f,y:%.0f)",items.containerView.center.x,items.containerView.center.y);
            }
        }
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
    
    //NSLog(@"Touch Point: (x:%.2f,y:%.2f)", touchPoint.x, touchPoint.y);
    
    CGPoint matrixCoords = [GeometryHelper pixelToHex:touchPoint gridSize:gridSize];
    //NSLog(@"Touch Matrix: (x:%.2f,y:%.2f)", matrixCoords.x, matrixCoords.y);
    
    //CGPoint pixelCoords = [GeometryHelper hexToPixel:matrixCoords];
    // NSLog(@"Touch Point calculated: (x:%.2f,y:%.2f)", pixelCoords.x, pixelCoords.y);
    
    MazeNode *node = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    if (pathView) {
        [pathView removeFromSuperview];
        pathView = nil;
       // movingView.frame = [[movingView.layer presentationLayer] frame];
       // [movingView.layer removeAnimationForKey:@"movingAnimation"];
    }
    
    if (![node isEqual:[NSNull null]]) {
        //NSLog(@"Touch Node Center: (x:%.2f,y:%.2f)", node.center.x, node.center.y);
        
        
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
            
            [self animatePathFromStart:node toEnd:endNode withStepDuration:1];
            
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
}

-(void)animatePathFromStart:(MazeNode*)start toEnd:(MazeNode*)end withStepDuration:(float)duration{
    animationStarted = YES;
    animationComplete = YES;
    menubar.steps = 0;
    pathView = [[UIBezierView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width * 1/self.scrollView.zoomScale, self.scrollView.contentSize.height * 1/self.scrollView.zoomScale)];
    
    movingPath = [NSMutableArray array];
    previousPath = [NSMutableArray array];
    UIImage *movingImage = [UIImage imageNamed:@"hex_small_red.png"];
    movingView = [[UIImageView alloc]initWithImage:movingImage];
    [pathView addSubview:movingView];
    
    lastWayPoint = start.MatrixCoords;
    
    [self recalculateAnimationFromStart:start toEnd:end withStepDuration:duration];
}

-(void)recalculateAnimationFromStart:(MazeNode*)start toEnd:(MazeNode*)end withStepDuration:(float)duration{
    //NSLog(@"start: (%.1f,%.1f)",start.MatrixCoords.x,start.MatrixCoords.y);
    /*
    if (!animationComplete){
        movingView.frame = [[movingView.layer presentationLayer] frame];
        CAAnimation *animation = [movingView.layer animationForKey:@"movingAnimation"];
        NSLog(@"animation class: %@", animation.class);
            interrupted = YES;
        [movingView.layer removeAnimationForKey:@"movingAnimation"];
    }*/
    
    [GeometryHelper solveMazeFrom:start To:end Matrix:matrix];
    NSArray *shortestPath = [GeometryHelper getShortestPathFrom:start To:end];
    NSLog(@"shortest path: %i steps", shortestPath.count);
    if (shortestPath.count == 0)
        return;
    
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
            if ([array[0] CGPointValue].x == start.MatrixCoords.x && [array[0] CGPointValue].y == start.MatrixCoords.y){
                array[1] = [NSNumber numberWithBool:YES];
                delIndex++;
            }
            break;
        }
        delIndex++;
    }
    
    if (movingPath.count > 0 && delIndex > 0){
        bool same = YES;
        for (int i = delIndex - 1; i < movingPath.count; i++) {
            if (i - (delIndex-1) >= shortestPath.count){
                same = NO;
                break;
            }
            CGPoint p1 = [movingPath[i][0] CGPointValue];
            CGPoint p2 = [shortestPath[i - (delIndex-1)] MatrixCoords];
           // NSArray *ar = @[[NSValue valueWithCGPoint:p1], [NSValue valueWithCGPoint:p2]];
           // NSLog(@"%@", ar);
            if (!(p1.x == p2.x && p1.y == p2.y)){
                same = NO;
                break;
            }
        }
        //NSLog(@"%@", same ? @"path is equal" : @"path is not equal");
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
    
    [movingPath removeObjectsInRange:NSMakeRange(delIndex, movingPath.count - delIndex)];
    
    UIBezierPath *bezierDrawingPath = [UIBezierPath bezierPath];
    for (int i = 0; i < ((movingPath.count > 0?(movingPath.count -1):0) + shortestPath.count); i++) {
        if (i == 0 && movingPath.count > 0){
            NSArray *array = movingPath[i];
            MazeNode *node = matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y];
            [bezierDrawingPath moveToPoint:node.center];
           // NSLog(@"start: (%.1f,%.1f)",[array[0] CGPointValue].x,[array[0] CGPointValue].y);
        }else if (i < movingPath.count){
            NSArray *array = movingPath[i];
            MazeNode *node = matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y];
            [bezierDrawingPath addLineToPoint:node.center];
           // NSLog(@"(%.1f,%.1f)",[array[0] CGPointValue].x,[array[0] CGPointValue].y);
        }else {
            MazeNode *node = shortestPath[i - (movingPath.count > 0?(movingPath.count - 1):0)];
            if (i == 0)
                [bezierDrawingPath moveToPoint:node.center];
            else
                [bezierDrawingPath addLineToPoint:node.center];
            //NSLog(@"(%.1f,%.1f)",node.MatrixCoords.x,node.MatrixCoords.y);
        }
    }
    /*
     pathView.curvePath = nil;
     [pathView setNeedsDisplay];
     [pathView removeFromSuperview];
     pathView = nil;
     pathView = [[UIBezierView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width * 1/self.scrollView.zoomScale, self.scrollView.contentSize.height * 1/self.scrollView.zoomScale)];
     */
    pathView.curvePath = bezierDrawingPath;
    [containerView addSubview:pathView];
    //[containerView addSubview:movingView];
    [pathView setNeedsDisplay];
    

    for (MazeNode *val in shortestPath) {
        [movingPath addObject:[NSMutableArray arrayWithObjects:[NSValue valueWithCGPoint:val.MatrixCoords], [NSNumber numberWithBool:NO], nil]];
    }
    
    NSArray *lastArray;
    int delIndex2 = -1;
    for (int i = 0; i < movingPath.count; i++) {
        NSArray *arr = movingPath[i];
        
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
        [movingPath removeObjectAtIndex:delIndex2];
    
    animationComplete = NO;

    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.duration = shortestPath.count * 1.5;
    pathAnimation.path = bezierMovingPath.CGPath;
    pathAnimation.calculationMode = kCAAnimationLinear;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (!interrupted) {
            if ([movingPath[movingPath.count-1][1] boolValue]){
                [menubar resetButton];
            }
            
            animationComplete = YES;
            
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
        
        // [movingView.layer removeFromSuperlayer];
    }];
    [movingView.layer addAnimation:pathAnimation forKey:@"movingAnimation"];
    [CATransaction commit];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
        while (!animationComplete) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                @try {
                    //NSLog(@"(%.2f,%.2f)",[movingView.layer.presentationLayer position].x, [movingView.layer.presentationLayer position].y);
                    CGPoint matrixPoint = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                    // NSLog(@"dings");
                    int steps = 0;
                    int coins = 0;
                    int i = 0;
                    
                    
                    for (NSMutableArray *array in movingPath) {
                        if ([array[1] boolValue] == NO){
                            if ([array[0] CGPointValue].x == matrixPoint.x && [array[0] CGPointValue].y == matrixPoint.y){
                                array[1] = [NSNumber numberWithBool:YES];
                                if (previousPath.count > 0 && !CGPointEqualToPoint([previousPath[previousPath.count - 1]CGPointValue], matrixPoint))
                                    [previousPath addObject:[NSValue valueWithCGPoint:matrixPoint]];
                                else if (previousPath.count == 0)
                                    [previousPath addObject:[NSValue valueWithCGPoint:matrixPoint]];
                            }
                            break;
                        }else if (i > 0){
                            steps++;
                        }
                        
                        if (![matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y] isEqual:[NSNull null]] &&
                            [matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y] isKindOfClass:[MazeNode class]] &&((MazeNode*)matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y]).object && ((MazeNode*)matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y]).object.type == COIN){
                            coins++;
                        }
                        
                        i++;
                    }
                    
                    /*
                    for (int i = 0; i < previousPath.count; i++) {
                        CGPoint prevCoord = [previousPath[i] CGPointValue];
                        if (
                    }
                    
                    if (previousPath.count > 0 ) {
                        CGPoint lastPoint = [previousPath[previousPath.count - 1] CGPointValue];
                        if (!CGPointEqualToPoint(lastPoint,matrixPoint) && !CGPointEqualToPoint(matrixPoint,start.MatrixCoords)){
                            [previousPath addObject:[NSValue valueWithCGPoint:matrixPoint]];
                            NSLog(@"%@", previousPath);
                        }
                    }else if (CGPointEqualToPoint(matrixPoint,start.MatrixCoords)){
                        [previousPath addObject:[NSValue valueWithCGPoint:matrixPoint]];
                    }
                    for (NSValue *val in previousPath) {
                        MazeNode *node = matrix[(int)[val CGPointValue].x][(int)[val CGPointValue].y];
                        if (node && ![node isEqual:[NSNull null]] && [node isKindOfClass:[MazeNode class]]){
                            if (node.object && node.object.type == COIN)
                                coins++;
                        }
                    }
                    steps = previousPath.count - 1;
                    
                    lastWayPoint = matrixPoint;
                    */
                    
                    //if ([movingPath[movingPath.count-1][1] boolValue] == YES)
                    //    steps++;
                    
                   // NSLog(@"Steps: %i", steps);
                    
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
            usleep(pathAnimation.duration / shortestPath.count / 8.0 * 1000 * 1000);
        }
    });
    

}

-(void)addDragEventsToNode:(MazeNode*)node{
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
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

-(void)gameOver {
    //initializes and displays game over view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect area = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
    gameOverView = [[UIView alloc]initWithFrame:area];
    gameOverView.backgroundColor = [UIColor colorWithWhite:0.333 alpha:0.750];
    
    UILabel* gameOverLabel =[[UILabel alloc]initWithFrame:CGRectMake(0, 50, area.size.width, 50)];
    [gameOverLabel setText:@"Game over!"];
    [gameOverLabel setTextColor:[UIColor whiteColor]];
    [gameOverLabel setTextAlignment:NSTextAlignmentCenter];
    [gameOverLabel setFont: [UIFont fontWithName:@"Chalkduster" size:33.0]];
    [gameOverView addSubview:gameOverLabel];
    
    UILabel* descriptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 150, area.size.width, 50)];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    NSString *description = [NSString stringWithFormat:@"Steps: %i",menubar.steps];
    [descriptionLabel setFont: [UIFont fontWithName:@"System Bold" size:22.0]];
    [descriptionLabel setText:description];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [gameOverView addSubview:descriptionLabel];
    
    UILabel* descriptionLabel2 = [[UILabel alloc]initWithFrame:CGRectMake(0, 200, area.size.width, 50)];
    [descriptionLabel2 setTextAlignment:NSTextAlignmentCenter];
    NSString *description2 = [NSString stringWithFormat:@"Coins: %i",menubar.coins];
    [descriptionLabel2 setFont: [UIFont fontWithName:@"System Bold" size:22.0]];
    [descriptionLabel2 setText:description2];
    [descriptionLabel2 setTextColor:[UIColor whiteColor]];
    [gameOverView addSubview:descriptionLabel2];
    
    UIButton* homeButton = [[UIButton alloc]initWithFrame:CGRectMake(area.size.width/2-60, 390, 120, 40)];
    homeButton.backgroundColor = [UIColor darkGrayColor];
    [homeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [homeButton setTitle:@"Home" forState:UIControlStateNormal];
    homeButton.layer.borderColor = [UIColor whiteColor].CGColor;
    homeButton.layer.borderWidth = 2.0f;
    [homeButton addTarget:self action:@selector(backtoHome) forControlEvents:UIControlEventTouchUpInside];
    [gameOverView addSubview:homeButton];
    
    UIButton* resetButton = [[UIButton alloc]initWithFrame:CGRectMake(area.size.width/2-60, 300, 120, 40)];
    resetButton.backgroundColor = [UIColor darkGrayColor];
    [resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [resetButton setTitle:@"Play again" forState:UIControlStateNormal];
    resetButton.layer.borderColor = [UIColor whiteColor].CGColor;
    resetButton.layer.borderWidth = 2.0f;
    [resetButton addTarget:self action:@selector(playAgain) forControlEvents:UIControlEventTouchUpInside];
    [gameOverView addSubview:resetButton];
    
    [self.view addSubview:gameOverView];
}

-(void) backtoHome {
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

-(void) playAgain{
    [self->gameOverView removeFromSuperview];
}

@end
