//
//  MazeNode.h
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MazeObject.h"

@class MazeObject;

@interface MazeNode : NSObject

@property (nonatomic) CGPoint center;
@property (nonatomic) CGPoint MatrixCoords;
@property (nonatomic, readonly) CGPoint Anchor;
@property (nonatomic, readonly) CGRect Frame;
@property (nonatomic) float Size;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, readonly) NSArray *neighbours;
@property (nonatomic, weak) UIView *uiElement;
@property (nonatomic, readonly) bool isWall;
@property (nonatomic) bool isStart;
@property (nonatomic, readonly) bool isEnd;

@property (nonatomic, strong) MazeObject *object;


@property (nonatomic) int steps;

+(MazeNode*)node;
+(MazeNode*)nodeWithSize:(float)size;
-(id)init;
-(id)initWithSize:(float)size;

-(void)addNeighbours:(MazeNode*)node;

@end
