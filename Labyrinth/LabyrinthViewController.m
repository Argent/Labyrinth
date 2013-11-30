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
#import "SettingsStore.h"


@interface LabyrinthViewController () {
    UIView *containerView;
    NSMutableArray *matrix;
    
    int grid_max_width;
    int grid_max_height;
    
    CGPoint lastDragPoint;
    bool touchedDown;
}
@end

@implementation LabyrinthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
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
            [(UIMazeControl*)wallNode.uiElement addTarget:self action:@selector(itemDragBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
            [(UIMazeControl*)wallNode.uiElement addTarget:self action:@selector(itemMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
            [(UIMazeControl*)wallNode.uiElement addTarget:self action:@selector(itemDragExit:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self.toolBarView addSubview:obj.containerView];
        
    }
    return self;
}

- (IBAction) itemDragBegan:(id) sender withEvent:(UIEvent *) event {
    NSLog(@"Drag began");
    lastDragPoint = [[[event allTouches] anyObject] locationInView:self.view];
    touchedDown = YES;
}

- (IBAction) itemMoved:(id) sender withEvent:(UIEvent *) event {
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    
    //NSLog(@"(x:%f,y:%f)",point.x,point.y);
    
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

    }
    
    lastDragPoint = point;
    
}

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
            point = [[[event allTouches] anyObject] locationInView:containerView];
            mazeControl.mazeObject.containerView.center = point;
            //TODO: snap objects in grid when dropping
            
            /*CGPoint roundedPoint = [self pixelToHex:CGPointMake(mazeControl.mazeObject.containerView.frame.origin.x, mazeControl.mazeObject.containerView.frame.origin.y)];
            MazeNode *node = matrix[(int)roundedPoint.x][(int)roundedPoint.y];
            NSLog(@"dropped on: (x:%f,y%f)",roundedPoint.x,roundedPoint.y);
            NSLog(@"dropped on: (x:%f,y%f)",node.Anchor.x,node.Anchor.y);
            mazeControl.mazeObject.containerView.frame = CGRectMake(node.Anchor.x, node.Anchor.y, mazeControl.mazeObject.containerView.frame.size.width, mazeControl.mazeObject.containerView.frame.size.height);*/
            [containerView addSubview:mazeControl.mazeObject.containerView];
            UIView *imgView = mazeControl.mazeObject.containerView;
            if ([imgView isKindOfClass:[UIView class]]){
                ((UIView*)imgView).transform = CGAffineTransformMakeScale(1.0, 1.0);
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
    
    grid_max_width = 20;
    grid_max_height = 20;
    
    // Custom initialization
    self.view.backgroundColor = [UIColor whiteColor];
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.view.frame];
    self.scrollView.backgroundColor = [UIColor blackColor];
    
    self.scrollView.contentSize = CGSizeMake(hex_width * (grid_max_width + 1), hex_height * grid_max_height);
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
            
            [containerView addSubview:start.containerView];
            [containerView addSubview:end.containerView];
            
            break;
        }
        
    }
    
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint=[gesture locationInView:self.scrollView];
    touchPoint = CGPointMake(touchPoint.x* 1/self.scrollView.zoomScale, touchPoint.y* 1/self.scrollView.zoomScale);
    
    //NSLog(@"Touch Point: (x:%.2f,y:%.2f)", touchPoint.x, touchPoint.y);
    
    CGPoint matrixCoords = [self pixelToHex:touchPoint];
    //NSLog(@"Touch Matrix: (x:%.2f,y:%.2f)", matrixCoords.x, matrixCoords.y);
    
    MazeNode *node = matrix[(int)matrixCoords.x][(int)matrixCoords.y];
    
    if (![node isEqual:[NSNull null]]) {
        //NSLog(@"Touch Node Center: (x:%.2f,y:%.2f)", node.center.x, node.center.y);
        
        MazeObject *start = [MazeObject objectWithType:START andCenter:CGPointMake(node.center.x, node.center.y)];
        MazeNode *nn = [start generateAndAddNodeRelative:CGPointMake(0,0)];
        [containerView addSubview:start.containerView];
        
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
    
    return CGPointMake(q, r);
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
            node.steps = -1;
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
            [neighbours addObject:val];
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
    
    containerView.frame = contentsFrame;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
