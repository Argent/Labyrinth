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
                
            case COIN:
                self.imageName = @"hex_turquoise.png";
                self.isDraggable = NO;
                break;
                
            case START:
                self.imageName = @"hex_turquoise.png";
                self.isDraggable = NO;
                break;
                
            case END:
                self.imageName = @"hex_petrol.png";
                self.isDraggable = NO;
                break;
            default:
                break;
        }
        initCenter = center;
        self.containerView.center = center;

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
        node.uiElement.center = CGPointMake(relPoint.x * node.width , relPoint.y * node.Size * 3);
        
        [self.containerView addSubview:node.uiElement];
        
        minX = MIN(minX, node.uiElement.frame.origin.x);
        minY = MIN(minY, node.uiElement.frame.origin.y);
        
        maxX = MAX(maxX, node.uiElement.frame.size.width + node.uiElement.frame.origin.x);
        maxY = MAX(maxY, node.uiElement.frame.size.height + node.uiElement.frame.origin.y);
    }
    
    self.containerView.frame = CGRectMake(self.containerView.center.x +  minX, self.containerView.center.y + minY, maxX - minX, maxY - minY);
    
    for (MazeNode *node in objectArray) {
        CGPoint center = node.uiElement.center;
        center.x += node.width / 2;
        center.y += node.Size;
        node.uiElement.center = center;
    }

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
    uiControl.userInteractionEnabled = self.isDraggable;
    [uiControl addSubview:imgView];
    
    [self addObjectNode:node withCoords:coords];

    return node;
}



-(NSArray *)objectNodes{
    return [NSArray arrayWithArray:objectArray];
}

@end
