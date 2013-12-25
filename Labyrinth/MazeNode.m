//
//  MazeNode.m
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "MazeNode.h"

@interface MazeNode(){
    NSMutableArray *neigbours;
}
@end


@implementation MazeNode


+(MazeNode *)node{
    return [[MazeNode alloc]init];
}

+(MazeNode *)nodeWithSize:(float)size {
    return [[MazeNode alloc]initWithSize:size];
}

-(id)init{
    self = [super init];
    if (self){
        neigbours = [NSMutableArray array];
        self.steps = -1;
    }
    return self;
}

-(id)initWithSize:(float)size {
    self = [self init];
    if (self){
        self.Size = size;
    }
    return self;
}

-(bool)isWall {
    if (!self.object)
        return NO;
    return self.object.type == WALL;
}


-(bool)isStart {
    if (!self.object)
        return NO;
    return self.object.type == START;
}


-(bool)isEnd {
    if (!self.object)
        return NO;
    return self.object.type == END;
    
}

-(void)addNeighbours:(MazeNode *)node {
    [neigbours addObject:node];
}

-(NSArray *)neighbours{
    return neigbours;
}

-(CGPoint)Anchor {
    float hex_height = self.height;
    float hex_width = self.width;
    
    CGPoint anchor = CGPointMake(self.center.x, self.center.y);
    anchor.x -= hex_width / 2;
    anchor.y -= hex_height / 2;
    return anchor;
}

-(CGRect)Frame {
    float hex_height = self.height;
    CGPoint anchor = self.Anchor;
    CGRect frame = CGRectMake(anchor.x, anchor.y, sqrt(3) / 2.0 * hex_height, self.Size * 2);
    return frame;
}

-(float)width {
    return sqrt(3) / 2.0 * self.height;
}

-(float)height {
    return self.Size * 2;
}

@end
