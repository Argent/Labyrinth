//
//  MazeObject.m
//  Labyrinth
//
//  Created by Benjamin Otto on 28.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "MazeObject.h"
#import "UIMazeControl.h"
#import "SettingsStore.h"

@interface MazeObject(){
    NSMutableArray *objectArray;
    NSMutableArray *relativeCoords;
    CGPoint initCenter;
}

@end

@implementation MazeObject

+(MazeObject *)objectWithType:(ObjectType)type andCenter:(CGPoint)center {
   return  [[MazeObject alloc]initWithType:type andCenter:center];
}

-(id)init{
    self = [super init];
    if (self){
        objectArray = [NSMutableArray array];
        relativeCoords = [NSMutableArray array];
        self.isDraggable = NO;
        self.containerView = [[UIView alloc]init];
        _gridNodes = [NSMutableArray array];
    }
    return self;
}

-(id)initWithType:(ObjectType)type andCenter:(CGPoint)center {
    self = [self init];
    if (self){
        self.type = type;
        switch (type) {
            case WALL:
                self.imageName = @"hex_brown.png";
                self.isDraggable = YES;
                break;
                
            case FIXEDWALL:
                self.imageName = @"hex_darkbrown.png";
                self.isDraggable = NO;
                break;
                
            case COIN:
                self.imageName = @"hex_coin.png";
                self.isDraggable = NO;
                break;
                
            case START:
                self.imageName = @"hex_turquoise.png";
                self.isDraggable = NO;
                break;
                
            case STARTEDIT:
                self.imageName = @"hex_turquoise.png";
                self.isDraggable = YES;
                break;
                
            case END:
                self.imageName = @"hex_petrol.png";
                self.isDraggable = NO;
                break;
                
                
            case ENDEDIT:
                self.imageName = @"hex_petrol.png";
                self.isDraggable = YES;
                break;
                
                
            default:
                break;
        }
        initCenter = center;
        self.containerView.center = center;
        self.toolbarItem = YES;

    }
    return self;
}

-(void)addObjectNode:(MazeNode *)node withCoords:(CGPoint) coords{
    [objectArray addObject:node];
    [relativeCoords addObject:[NSValue valueWithCGPoint:coords]];
    
    
    float minX = FLT_MAX;
    float minY = FLT_MAX;
    float maxX = 0;
    float maxY = 0;
    for (int i = 0; i < objectArray.count; i++) {
        MazeNode *node = objectArray[i];
        CGPoint relPoint = [relativeCoords[i] CGPointValue];
        
        if ((int)relPoint.y % 2 == 0)
            node.uiElement.center = CGPointMake(relPoint.x * node.width , relPoint.y * node.Size * 1.5);
        else
            node.uiElement.center = CGPointMake( (relPoint.x * node.width) -(node.width / 2) , relPoint.y * node.Size * 1.5);
        
        [self.containerView addSubview:node.uiElement];
        
        minX = MIN(minX, node.uiElement.frame.origin.x);
        minY = MIN(minY, node.uiElement.frame.origin.y);
        
        maxX = MAX(maxX, node.uiElement.frame.size.width + node.uiElement.frame.origin.x);
        maxY = MAX(maxY, node.uiElement.frame.size.height + node.uiElement.frame.origin.y);
    }
    
    self.containerView.frame = CGRectMake(self.containerView.center.x +  minX, self.containerView.center.y + minY, maxX - minX, maxY - minY);
    

    
    for (MazeNode *node in objectArray) {
        /*CGPoint center = node.uiElement.center;
        center.x += node.width / 2;
        center.y += node.Size;
        node.uiElement.center = center;*/
        
        CGRect frame = node.uiElement.frame;
        frame.origin.x -= minX;
        frame.origin.y -= minY;
        node.uiElement.frame = frame;
    }
    
    /*
    CGRect fr = self.containerView.frame;
    CGPoint tp = self.containerView.center;
    
    int blub = 0;
    blub++;
     */
     
    /*
    for (MazeNode *node in objectArray ) {
        CGRect uiFrame = node.uiElement.frame;
        uiFrame.origin.x = uiFrame.origin.x - self.containerView.frame.origin.x;
        uiFrame.origin.y = uiFrame.origin.y - self.containerView.frame.origin.y;
        node.uiElement.frame = uiFrame;
    }
    */
    
   // self.containerView.center = CGPointMake( minX + ((maxX - minX) / 2.0),  minY + ((maxY - minY) / 2.0));
    
    
}

-(MazeNode*)generateAndAddNodeRelative:(CGPoint)coords {
    MazeNode *node = [MazeNode nodeWithSize:[SettingsStore sharedStore].hexSize];

    //node.center = center;

    UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:self.imageName]];
    UIMazeControl *uiControl = [[UIMazeControl alloc] initWithFrame:imgView.frame];
    node.uiElement = uiControl;
    uiControl.mazeObject = self;
    uiControl.view = imgView;
    uiControl.userInteractionEnabled = self.isDraggable;
    [uiControl addSubview:imgView];
    
    [self addObjectNode:node withCoords:coords];

    return node;
}

-(void)flashView:(UIColor *)color times:(float)times {
    for (MazeNode *node in self.objectNodes) {
        [node flashView:color times:times];
    }
}

-(void)overlayWithColor:(UIColor *)color alpha:(float)alpha{
    for (MazeNode *node in self.objectNodes) {
        [node overlayWithColor:color alpha:alpha];
    }
}

-(void)removeOverlay{
    for (MazeNode *node in self.objectNodes) {
        [node removeOverlay];
    }
}


-(NSArray *)objectCoordinates {
    return [NSArray arrayWithArray:relativeCoords];
}

-(NSArray *)objectNodes{
    return [NSArray arrayWithArray:objectArray];
}

@end
