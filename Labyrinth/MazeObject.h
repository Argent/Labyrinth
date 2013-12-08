//
//  MazeObject.h
//  Labyrinth
//
//  Created by Benjamin Otto on 28.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MazeNode.h"

@class MazeNode;

typedef enum {
    WALL,
    COIN,
    START,
    STARTEDIT,
    END,
    ENDEDIT
} ObjectType;

@interface MazeObject : NSObject

@property (nonatomic, strong) NSArray *objectNodes;
@property (nonatomic) ObjectType type;
@property (nonatomic) bool isDraggable;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSString *imageName;


+(MazeObject*)objectWithType:(ObjectType)type andCenter:(CGPoint)center;

-(id)init;
-(id)initWithType:(ObjectType)type andCenter:(CGPoint)center;

-(MazeNode*)generateAndAddNodeRelative:(CGPoint)coords;

@end
