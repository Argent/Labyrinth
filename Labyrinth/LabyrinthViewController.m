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


@interface LabyrinthViewController () {
    UIView *containerView;
    UIBezierView *pathView;
    NSMutableArray *matrix;
    
    CGSize gridSize;

    CGPoint lastDragPoint;
    bool touchedDown;
    bool overGameField;
    
    CGPoint scrollViewOffset;
    
    UIImageView *movingView;
    bool animationComplete;
    bool animationStarted;
    NSMutableArray *movingPath;
    bool interrupted;
}
@end

@implementation LabyrinthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        scrollViewOffset = CGPointMake(0.0, 0.0);
        [self initGrid];
        [self initToolbar];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
        [self.scrollView addGestureRecognizer:singleTap];
        
        NSMutableArray *wallNodes = [NSMutableArray array];
        MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(50, 60)];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,2)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,3)]];
         MazeObject *obj2 = [MazeObject objectWithType:WALL andCenter:CGPointMake(150, 60)];
        [wallNodes addObject:[obj2 generateAndAddNodeRelative:CGPointMake(0,0)]];
        [wallNodes addObject:[obj2 generateAndAddNodeRelative:CGPointMake(1,0)]];
        [wallNodes addObject:[obj2 generateAndAddNodeRelative:CGPointMake(-1,1)]];
         MazeObject *obj3 = [MazeObject objectWithType:WALL andCenter:CGPointMake(250, 60)];
        [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(0,0)]];
        [wallNodes addObject:[obj3 generateAndAddNodeRelative:CGPointMake(1,0)]];
        
       /* [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,4)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,4)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,-1)]];*/
        
    
        for (MazeNode *wallNode in wallNodes) {
            [self addDragEventsToNode:wallNode];
        }
        
        [self.toolBarView addSubview:obj.containerView];
        [self.toolBarView addSubview:obj2.containerView];
        [self.toolBarView addSubview:obj3.containerView];
        CGRect frame =  obj.containerView.frame;
        frame.origin.y = 0;
        obj.containerView.frame = frame;
        
        //[obj2 flashView:[UIColor redColor] times:5];
        
    }
    return self;
}

//TODO: Remove object from grid when dragging..

// Called when a drag on a maze object started
- (IBAction) itemDragBegan:(id) sender withEvent:(UIEvent *) event {
    NSLog(@"Drag began");
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
        
        /*
        CGPoint tmpPoint = [[[event allTouches] anyObject] locationInView:self.scrollView];
        tmpPoint.x -= scrollViewOffset.x;
        tmpPoint.y -= scrollViewOffset.y;
        tmpPoint = CGPointMake(tmpPoint.x* 1/self.scrollView.zoomScale , tmpPoint.y* 1/self.scrollView.zoomScale );
        
        CGRect containerRect = mazeControl.mazeObject.containerView.frame;
        CGAffineTransform t = CGAffineTransformMakeScale(1.0,1.0);
        CGRect rect2 = CGRectApplyAffineTransform(containerRect,t);
        
        NSArray *dropCoords = [GeometryHelper alignToGrid:mazeControl.mazeObject Matrix:matrix TopLeft:CGPointMake(rect2.origin.x, rect2.origin.y)];
    
        NSLog(@"dings");
        bool flash = NO;
        for (NSValue *val in dropCoords) {
            CGPoint p = [val CGPointValue];
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
           
        }
        if(flash){
            [mazeControl.mazeObject overlayWithColor:[UIColor redColor] alpha:0.7];
        }else {
            [mazeControl.mazeObject removeOverlay];
        }
        */
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
            point = [[[event allTouches] anyObject] locationInView:self.toolBarView];
            point.y = 60;
            mazeControl.mazeObject.containerView.center = point;
            [self.toolBarView addSubview:mazeControl.mazeObject.containerView];
        } else {
            NSLog(@"Dropped on game field");
            // first scale the object to the gamefield size
            mazeControl.mazeObject.containerView.center = point;
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
                if (node && !node.object){
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
            
            NSLog(@"%@",alignedCoords);
            
            if ([imgView isKindOfClass:[UIView class]]){
                ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                rect.size = mazeControl.mazeObject.containerView.frame.size;
                mazeControl.mazeObject.containerView.frame = rect;
            }
            
            // set the the object variable of the grid nodes
            for (NSValue *val in alignedCoords) {
                CGPoint coords = [val CGPointValue];
                ((MazeNode*) matrix[(int)coords.x][(int)coords.y]).object = mazeControl.mazeObject;
                [mazeControl.mazeObject.gridNodes addObject:matrix[(int)coords.x][(int)coords.y] ];
            }
            
            if (!animationComplete && animationStarted){
                CGPoint playerCoords = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                NSLog(@"Matrix: (%.2f,%.2f)",playerCoords.x, playerCoords.y);
                
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
                
                [self recalculateAnimationFromStart:matrix[(int)playerCoords.x][(int)playerCoords.y] toEnd:endNode withStepDuration:1];

            }
        }
    }
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated {
    self.scrollView.zoomScale = 0.48;
    return [super viewDidAppear:animated];
}


-(void)initGrid{
    float hex_height = [SettingsStore sharedStore].hexSize * 2;
    float hex_width = sqrt(3) / 2.0 * hex_height;
    
    
    gridSize = CGSizeMake(20, 20);

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
    
    matrix = [GeometryHelper generateMatrixWithWidth:gridSize.width Height:gridSize.height withImageName:@"hex_gray.png" inContainerView:containerView];
     while (true) {
        CGPoint startP =  CGPointMake(arc4random()%(int)gridSize.width,arc4random()%(int)gridSize.height);
        CGPoint endP =  CGPointMake(arc4random()%(int)gridSize.width,arc4random()%(int)gridSize.height);
        
        MazeNode *nodeStart = (MazeNode*)matrix[(int)startP.x][(int)startP.y];
        MazeNode *nodeEnd = (MazeNode*)matrix[(int)endP.x][(int)endP.y];
        
        
        if (![nodeStart isEqual:[NSNull null]] && ![nodeEnd isEqual:[NSNull null]] && !(startP.x == endP.x && startP.y == endP.y)){
            
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
        
    }
    
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

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint.x -= scrollViewOffset.x;
    touchPoint.y -= scrollViewOffset.y;
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    
    //NSLog(@"Touch Point: (x:%.2f,y:%.2f)", touchPoint.x, touchPoint.y);
    
    CGPoint matrixCoords = [GeometryHelper pixelToHex:touchPoint gridSize:gridSize];
    NSLog(@"Touch Matrix: (x:%.2f,y:%.2f)", matrixCoords.x, matrixCoords.y);
    
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
            /*
            MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
            MazeNode *nn = [wall generateAndAddNodeRelative:CGPointMake(0,0)];
            [self addDragEventsToNode:nn];
            node.object = wall;
            [containerView addSubview:wall.containerView];
            */
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
    pathView = [[UIBezierView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width * 1/self.scrollView.zoomScale, self.scrollView.contentSize.height * 1/self.scrollView.zoomScale)];
    
    movingPath = [NSMutableArray array];
    UIImage *movingImage = [UIImage imageNamed:@"hex_small_red.png"];
    movingView = [[UIImageView alloc]initWithImage:movingImage];
    [pathView addSubview:movingView];
    
    [self recalculateAnimationFromStart:start toEnd:end withStepDuration:duration];
}

-(void)recalculateAnimationFromStart:(MazeNode*)start toEnd:(MazeNode*)end withStepDuration:(float)duration{
    NSLog(@"start: (%.1f,%.1f)",start.MatrixCoords.x,start.MatrixCoords.y);
    if (!animationComplete){
        movingView.frame = [[movingView.layer presentationLayer] frame];
        [movingView.layer removeAnimationForKey:@"movingAnimation"];
    }
    
    [GeometryHelper solveMazeFrom:start To:end Matrix:matrix];
    NSArray *shortestPath = [GeometryHelper getShortestPathFrom:start To:end];
    NSLog(@"shortest path: %i steps", shortestPath.count);
    
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
    
    [movingPath removeObjectsInRange:NSMakeRange(delIndex, movingPath.count - delIndex)];
    
    UIBezierPath *bezierDrawingPath = [UIBezierPath bezierPath];
    for (int i = 0; i < ((movingPath.count > 0?(movingPath.count -1):0) + shortestPath.count); i++) {
        if (i == 0 && movingPath.count > 0){
            NSArray *array = movingPath[i];
            MazeNode *node = matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y];
            [bezierDrawingPath moveToPoint:node.center];
            NSLog(@"start: (%.1f,%.1f)",[array[0] CGPointValue].x,[array[0] CGPointValue].y);
        }else if (i < movingPath.count){
            NSArray *array = movingPath[i];
            MazeNode *node = matrix[(int)[array[0] CGPointValue].x][(int)[array[0] CGPointValue].y];
            [bezierDrawingPath addLineToPoint:node.center];
            NSLog(@"(%.1f,%.1f)",[array[0] CGPointValue].x,[array[0] CGPointValue].y);
        }else {
            MazeNode *node = shortestPath[i - (movingPath.count > 0?(movingPath.count - 1):0)];
            if (i == 0)
                [bezierDrawingPath moveToPoint:node.center];
            else
                [bezierDrawingPath addLineToPoint:node.center];
            NSLog(@"(%.1f,%.1f)",node.MatrixCoords.x,node.MatrixCoords.y);
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
    
    animationComplete = NO;
    interrupted = YES;
    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.duration = shortestPath.count * 1;
    pathAnimation.path = bezierMovingPath.CGPath;
    pathAnimation.calculationMode = kCAAnimationLinear;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (!interrupted) {
            animationComplete = YES;
            
            for (int i = 0; i < movingPath.count; i++) {
                if ([movingPath[i][1] boolValue] == NO || i == movingPath.count -1){
                    MazeNode *node = matrix[(int)[movingPath[i][0] CGPointValue].x][(int)[movingPath[i][0] CGPointValue].y];
                    
                    movingView.center = node.center;
                    break;
                }
            }
        }else {
            interrupted = NO;
        }
        // [movingView.layer removeFromSuperlayer];
    }];
    [movingView.layer addAnimation:pathAnimation forKey:@"movingAnimation"];
    [CATransaction commit];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,                                     (unsigned long)NULL), ^(void) {
        while (!animationComplete) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                @try {
                    //NSLog(@"(%.2f,%.2f)",[movingView.layer.presentationLayer position].x, [movingView.layer.presentationLayer position].y);
                    CGPoint matrixPoint = [GeometryHelper pixelToHex:[movingView.layer.presentationLayer position] gridSize:gridSize];
                    // NSLog(@"dings");
                    for (NSMutableArray *array in movingPath) {
                        if ([array[1] boolValue] == NO){
                            if ([array[0] CGPointValue].x == matrixPoint.x && [array[0] CGPointValue].y == matrixPoint.y){
                                array[1] = [NSNumber numberWithBool:YES];
                              //  NSLog(@"(%.2f,%.2f)",matrixPoint.x, matrixPoint.y);
                            }
                            break;
                        }
                    }
                    if (matrixPoint.x == end.MatrixCoords.x && matrixPoint.y == end.MatrixCoords.y){
                        animationStarted = NO;
                    }
                }
                @catch (NSError *error) {
                    NSLog(@"error: %@",error);
                }
            });
            usleep(pathAnimation.duration / shortestPath.count / 4.0 * 1000 * 1000);
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
    
    scrollViewOffset.x = contentsFrame.origin.x;
    scrollViewOffset.y = contentsFrame.origin.y;
    
    containerView.frame = contentsFrame;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
