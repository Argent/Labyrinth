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


@interface LabyrinthViewController () {
    UIView *containerView;
    UIBezierView *pathView;
    NSMutableArray *matrix;
    
    int grid_max_width;
    int grid_max_height;
    
    CGPoint lastDragPoint;
    bool touchedDown;
    bool overGameField;
    
    CGPoint scrollViewOffset;
}
@end

@implementation LabyrinthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        scrollViewOffset = CGPointMake(0.0, 0.0);
        [self initGrid];
        
        int toolbarHeight = 100;
        self.toolBarView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight)];
        self.toolBarView.contentSize = CGSizeMake(self.view.frame.size.width * 2, toolbarHeight);
        self.toolBarView.backgroundColor = [UIColor clearColor];
        UIImage *backgroundImg = [UIImage imageNamed:@"toolbar.png"];
        UIImageView *imgView = [[UIImageView alloc]initWithImage:backgroundImg];
        imgView.frame = CGRectMake(0 - 100, 0, self.toolBarView.contentSize.width + 200, self.toolBarView.contentSize.height);
        [self.toolBarView addSubview:imgView];
        [self.view addSubview:self.toolBarView];
        
        NSMutableArray *wallNodes = [NSMutableArray array];
        MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(50, 60)];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
        [wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
       
        for (MazeNode *wallNode in wallNodes) {
            [self addDragEventsToNode:wallNode];
        }
        
        [self.toolBarView addSubview:obj.containerView];
       /* CGRect frame =  obj.containerView.frame;
        frame.origin.y = 0;
        obj.containerView.frame = frame;*/
        
    }
    return self;
}

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
    
    // if the object is on the gamefield, round its position to the underlaying grid
    /*
     if (overGameField && [control isKindOfClass:[UIMazeControl class]]){
     UIMazeControl *mazeControl = (UIMazeControl*)control;
     float nodeHeightOffset = [SettingsStore sharedStore].hexSize;
     float nodeWidthOffset = sqrtf(3)/2 * nodeHeightOffset;
     
     CGRect rect = mazeControl.mazeObject.containerView.frame;
     // multiply with inverse zoomscale to find the right game coordinates
     CGPoint roundedPoint = [self pixelToHex:CGPointMake((rect.origin.x  * 1/self.scrollView.zoomScale )+ nodeWidthOffset, (rect.origin.y * 1/self.scrollView.zoomScale )+ nodeHeightOffset)];
     MazeNode *node = matrix[(int)roundedPoint.x][(int)roundedPoint.y];
     // multiply with zoomscale again because the object is not on the gamefield yet but on the container view bellow
     rect.origin.x = node.Anchor.x * self.scrollView.zoomScale;
     rect.origin.y = node.Anchor.y * self.scrollView.zoomScale;
     
     mazeControl.mazeObject.containerView.frame = rect;
     }
     */
    
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
            mazeControl.mazeObject.containerView.center = point;
            point = [[[event allTouches] anyObject] locationInView:self.scrollView];
            point.x -= scrollViewOffset.x;
            point.y -= scrollViewOffset.y;
            point = CGPointMake(point.x* 1/self.scrollView.zoomScale + 10, point.y* 1/self.scrollView.zoomScale + 10);
            
            float centerOffsetX = mazeControl.mazeObject.containerView.center.x - mazeControl.mazeObject.containerView.frame.origin.x;
            float centerOffsetY = mazeControl.mazeObject.containerView.center.y - mazeControl.mazeObject.containerView.frame.origin.y;
            
            point.x -= centerOffsetX;
            point.y -= centerOffsetY;
            
            CGPoint matrixCoords = [self pixelToHex:point];
            MazeNode *node = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
            
            CGRect rect = mazeControl.mazeObject.containerView.frame;
            rect.origin.x = node.Anchor.x;
            rect.origin.y = node.Anchor.y;
            
            [containerView addSubview:mazeControl.mazeObject.containerView];
            UIView *imgView = mazeControl.mazeObject.containerView;
            if ([imgView isKindOfClass:[UIView class]]){
                ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
                rect.size = mazeControl.mazeObject.containerView.frame.size;
                mazeControl.mazeObject.containerView.frame = rect;
                
            }
            
            //once the item has been put on the gamefield, update the grid to recognize the new object
            CGPoint mostLeftNode = CGPointMake(FLT_MAX, FLT_MAX);
            for (NSValue *val in mazeControl.mazeObject.objectCoordinates) {
                CGPoint matrixOffset = [val CGPointValue];
                if ((matrixOffset.x < mostLeftNode.x )||
                    (matrixOffset.x == mostLeftNode.x && (int)matrixOffset.y%2 == 0)){
                    mostLeftNode.x = matrixOffset.x;
                    mostLeftNode.y = matrixOffset.y;
                }
                
            }
            
            
            CGPoint mostLeftNodeCoords = CGPointMake(rect.origin.x, (rect.origin.y + node.Size) + mostLeftNode.y * node.Size * 1.5);
            if ((int)mostLeftNode.y % 2 == 0)
                mostLeftNodeCoords.x -= node.width / 2;
            CGPoint mostLeftNodeMatrixCoords = [self pixelToHex:mostLeftNodeCoords];
            MazeNode *mostLeftMazeNode = matrix[(int)mostLeftNodeMatrixCoords.x][(int)mostLeftNodeMatrixCoords.y];
            
            
            mostLeftMazeNode.object = mazeControl.mazeObject;
            for (NSValue *val in mazeControl.mazeObject.objectCoordinates) {
                CGPoint matrixOffset = [val CGPointValue];
                if (!(mostLeftNode.x == matrixOffset.x && mostLeftNode.y == matrixOffset.y)){
                    CGPoint newMatrixCoords = CGPointMake(mostLeftNodeMatrixCoords.x - (mostLeftNode.x - matrixOffset.x), mostLeftNodeMatrixCoords.y - (mostLeftNode.y - matrixOffset.y));
                    MazeNode *objectNode;
                    if ((int)newMatrixCoords.y % 2 == 1 && (int)matrixOffset.y % 2 == 1)
                        objectNode = matrix[(int)newMatrixCoords.x + 1][(int)newMatrixCoords.y];
                    else
                        objectNode = matrix[(int)newMatrixCoords.x][(int)newMatrixCoords.y];
                    
                    objectNode.object =  mazeControl.mazeObject;
                    
                    /*
                    MazeObject *wall = [MazeObject objectWithType:START andCenter:CGPointMake(objectNode.center.x, objectNode.center.y)];
                    [wall generateAndAddNodeRelative:CGPointMake(0,0)];
                    [containerView addSubview:wall.containerView];
                    */
                }
            }
            /*
            
            
            MazeObject *wall = [MazeObject objectWithType:START andCenter:CGPointMake(mostLeftMazeNode.center.x, mostLeftMazeNode.center.y)];
            [wall generateAndAddNodeRelative:CGPointMake(0,0)];
            [containerView addSubview:wall.containerView];
            */
            
            /*
             // calculate the position of the object before the scale transform
             CGRect rect = mazeControl.mazeObject.containerView.frame;
             rect.origin.x -= scrollViewOffset.x;
             rect.origin.y -= scrollViewOffset.y;
             
             rect.origin.x *= 1/self.scrollView.zoomScale;
             rect.origin.y *= 1/self.scrollView.zoomScale;
             
             
             [containerView addSubview:mazeControl.mazeObject.containerView];
             UIView *imgView = mazeControl.mazeObject.containerView;
             if ([imgView isKindOfClass:[UIView class]]){
             ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
             // after the transformation, position the object at the coordinates we calculated before
             rect.size =mazeControl.mazeObject.containerView.frame.size;
             
             mazeControl.mazeObject.containerView.frame = rect;
             
             }*/
            
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
    
    grid_max_width = 20;
    grid_max_height = 20;
    
    // Custom initialization
    self.view.backgroundColor = [UIColor whiteColor];
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.view.frame];
    self.scrollView.backgroundColor = [UIColor blackColor];
    
    self.scrollView.contentSize = CGSizeMake((hex_width * grid_max_width) - (hex_width/2), hex_height * grid_max_height);
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale=0.25;
    self.scrollView.maximumZoomScale=1.0;
    
    [self.view addSubview:self.scrollView];
    
    containerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    [self.scrollView addSubview:containerView];
    
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    [self.scrollView addGestureRecognizer:singleTap];
    
    matrix = [NSMutableArray array];
    
    float currentX =  hex_width / 2;
    float currentY = hex_height / 2;
    bool even;
    for (int x = 0; x < grid_max_width; x++) {
        [matrix addObject:[NSMutableArray array]];
        currentY = hex_height / 2;
        for (int y = 0; y < grid_max_height; y++) {
            if(y%2 == 0){
                even = true;
            }else{
                even = false;
            }
            
            if ((even && x < grid_max_width-1) ||
                (!even && x > 0)){
                
                MazeNode *node = [MazeNode node];
                node.Size = [SettingsStore sharedStore].hexSize;
                node.center = CGPointMake(currentX, currentY);
                node.MatrixCoords = CGPointMake(x, y);
                
                UIImageView *uiImage = [[UIImageView alloc]initWithFrame:node.Frame];
                [uiImage setImage:[UIImage imageNamed:@"hex_gray.png"]];
                [containerView addSubview:uiImage];
                
                node.uiElement = uiImage;
                
                [matrix[x] addObject:node];
            } else {
                [matrix[x] addObject:[NSNull null]];
            }
            currentY += hex_height * 3/4;
            
            if (!even) {
                currentX += hex_width / 2;
            } else {
                currentX -= hex_width / 2;
            }
        }
        
        currentX += hex_width;
    }
    
    
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]) {
                NSArray *neigbours = [self getNeighboursFrom:CGPointMake(x, y)];
                for (NSValue *val in neigbours) {
                    CGPoint neigbour = [val CGPointValue];
                    
                    MazeNode *node2 = matrix[(int)neigbour.x][(int)neigbour.y];
                    if (![node2 isEqual:[NSNull null]])
                        [node addNeighbours:node2];
                }
            }
        }
    }
    
    while (true) {
        CGPoint startP =  CGPointMake(arc4random()%grid_max_width,arc4random()%grid_max_height);
        CGPoint endP =  CGPointMake(arc4random()%grid_max_width,arc4random()%grid_max_height);
        
        MazeNode *nodeStart = (MazeNode*)matrix[(int)startP.x][(int)startP.y];
        MazeNode *nodeEnd = (MazeNode*)matrix[(int)endP.x][(int)endP.y];
        
        
        if (![nodeStart isEqual:[NSNull null]] && ![nodeEnd isEqual:[NSNull null]] && !(startP.x == endP.x && startP.y == endP.y)){
            
            MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(nodeStart.center.x, nodeStart.center.y)];
            [start generateAndAddNodeRelative:CGPointMake(0,0)];
            
            MazeObject *end = [MazeObject objectWithType:END andCenter:CGPointMake(nodeEnd.center.x, nodeEnd.center.y)];
            [end generateAndAddNodeRelative:CGPointMake(0,0)];
            
            nodeStart.object = start;
            nodeEnd.object = end;
            
            [containerView addSubview:start.containerView];
            [containerView addSubview:end.containerView];
            
            break;
        }
        
    }
    
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint.x -= scrollViewOffset.x;
    touchPoint.y -= scrollViewOffset.y;
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    
    //NSLog(@"Touch Point: (x:%.2f,y:%.2f)", touchPoint.x, touchPoint.y);
    
    CGPoint matrixCoords = [self pixelToHex:touchPoint];
    //NSLog(@"Touch Matrix: (x:%.2f,y:%.2f)", matrixCoords.x, matrixCoords.y);
    
    MazeNode *node = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    if (pathView) {
        [pathView removeFromSuperview];
        pathView = nil;
    }
    
    if (![node isEqual:[NSNull null]]) {
        //NSLog(@"Touch Node Center: (x:%.2f,y:%.2f)", node.center.x, node.center.y);
        
        
        if (node.object == nil) {
            
            MazeObject *wall = [MazeObject objectWithType:WALL andCenter:CGPointMake(node.center.x, node.center.y)];
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
            
            [self solveMazeFrom:node To:endNode];
            NSArray *shortestPath = [self getShortestPathFrom:node To:endNode];
            NSLog(@"shortest path: %i steps", shortestPath.count);
            pathView = [[UIBezierView alloc]initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width * 1/self.scrollView.zoomScale, self.scrollView.contentSize.height * 1/self.scrollView.zoomScale)];
            
            UIBezierPath *bezierPath = [UIBezierPath bezierPath];
            for (int i = 0; i < shortestPath.count; i++) {
                
                MazeNode *node = shortestPath[i];
                if (i == 0)
                    [bezierPath moveToPoint:node.center];
                else
                    [bezierPath addLineToPoint:node.center];
                
            }
            pathView.curvePath = bezierPath;
            [containerView addSubview:pathView];
            [pathView setNeedsDisplay];
        }
        
        //NSLog(@"Touch GenNode Center: (x:%.2f,y:%.2f)", nn.uiElement.center.x, nn.uiElement.center.y);
        //NSLog(@"Touch Container Center: (x:%.2f,y:%.2f)", start.containerView.center.x, start.containerView.center.y);
        //NSLog(@"Touch Container Frame: (x:%.2f,y:%.2f,width:%.2f,height:%.2f)", start.containerView.frame.origin.x, start.containerView.frame.origin.y, start.containerView.frame.size.width, start.containerView.frame.size.height);
        
        /*
         NSArray *neighbours =  [self getNeighboursFrom:matrixCoords];
         for (NSValue *neighbour in neighbours) {
         CGPoint coords = [neighbour CGPointValue];
         MazeNode *node = matrix[(int)coords.x][(int)coords.y];
         if (![node isEqual:[NSNull null]]) {
         [((UIImageView*)node.uiElement) setImage:[UIImage imageNamed:@"hex_red.png"]];
         };
         }*/
    }
}

// TODO: does not work for lower zoom scales
-(CGPoint)pixelToHex:(CGPoint)pixel{
    // axial coordinates
    float q = (1.0/3.0*sqrt(3.0) * pixel.x - 1.0/3.0 * pixel.y) / [SettingsStore sharedStore].hexSize;
    float r = 2.0/3.0 * pixel.y / [SettingsStore sharedStore].hexSize;
    
    // convert to cube coordinates
    float x = q;
    float z = r;
    float y = -x-z;
    
    // hex rounding
    
    float rx = round(x);
    float ry = round(y);
    float rz = round(z);
    
    float x_diff = abs(rx - x);
    float y_diff = abs(ry - y);
    float z_diff = abs(rz - z);
    
    if (x_diff > y_diff && x_diff > z_diff){
        rx = -ry-rz;
    }else if (y_diff > z_diff){
        ry = -rx-rz;
    }else{
        rz = -rx-ry;
    }
    
    // convert cube to odd-r offset
    
    q = rx + (rz - ((int)rz&1)) / 2;
    r = rz - 1;
    
    q = MIN(MAX(q, 0), grid_max_width -1);
    r= MIN(MAX(r, 0), grid_max_height -1);
    
    return CGPointMake(q, r);
}

-(void)addDragEventsToNode:(MazeNode*)node{
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [(UIMazeControl*)node.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
}


-(NSArray*)getShortestPathFrom:(MazeNode*)startPoint To:(MazeNode*)endPoint{
    
    NSMutableArray *path = [NSMutableArray array];
    [path addObject:startPoint];
    MazeNode *currentNode = startPoint;
    while (!(currentNode.MatrixCoords.x == endPoint.MatrixCoords.x && currentNode.MatrixCoords.y == endPoint.MatrixCoords.y)) {
        MazeNode *minStepsNode = nil;
        for (MazeNode *neighbour in currentNode.neighbours) {
            if (neighbour.steps > -1) {
                if (!minStepsNode || minStepsNode.steps > neighbour.steps)
                    minStepsNode = neighbour;
            }
        }
        if (!minStepsNode){
            NSLog(@"no path found");
            return [NSArray array];
        }
        
        [path addObject:minStepsNode];
        currentNode = minStepsNode;
    }
    
    return path;
    
}


-(void)solveMazeFrom:(MazeNode*)startPoint To:(MazeNode*)endPoint{
    for (int x = 0; x < matrix.count; x++) {
        for (int y = 0; y < ((NSArray*)matrix[0]).count; y++) {
            MazeNode *node = matrix[x][y];
            if (![node isEqual:[NSNull null]]){
                node.steps = -1;
            }
        }
    }
    
    endPoint.steps = 0;
    
    // MazeNode *currentNode = endPoint;
    
    NSMutableArray *nodeList = [NSMutableArray array];
    [nodeList addObject:endPoint];
    
    while (nodeList.count > 0) {
        
        MazeNode *currentNode = [nodeList dequeue];
        NSArray *neighbours = currentNode.neighbours;
        for (MazeNode *node in neighbours) {
            int nextStepValue = currentNode.steps + 1;
            if (!node.isWall && (node.steps == -1 || nextStepValue < node.steps)) {
                node.steps = nextStepValue;
                [nodeList enqueue:node];
            }
        }
    }
    
    NSLog(@"solved");
    
}

-(NSArray*)getNeighboursFrom:(CGPoint) point {
    
    bool even = ((int)point.y) % 2 != 0;
    NSMutableArray *neighboursTmp = [NSMutableArray array];
    if (even) {
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y + 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y + 1)]];
        
    }else {
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y - 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x - 1, point.y)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y + 1)]];
        [neighboursTmp addObject:[NSValue valueWithCGPoint:CGPointMake(point.x + 1, point.y + 1)]];
    }
    
    NSMutableArray *neighbours = [NSMutableArray array];
    
    for (NSValue *val in neighboursTmp) {
        CGPoint point = [val CGPointValue];
        if ((point.x >= 0 && point.x < grid_max_width) &&
            (point.y >= 0 && point.y < grid_max_height)) {
            bool even = (int)point.y % 2 == 0;
            if ((even && point.x >= 0 && point.x < grid_max_width -1) ||
                (!even && point.x > 0 && point.x < grid_max_width)) {
                [neighbours addObject:val];
            }
        }
    }
    
    return neighbours;
    
}



- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
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
