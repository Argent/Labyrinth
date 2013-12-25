//
//  LevelInfo.m
//  Labyrinth
//
//  Created by Corina Schemainda on 16.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "LevelInfo.h"
#import "MazeNode.h"
#import "GeometryHelper.h"

#define kStartKey @"start"
#define kEndKey @"end"
#define kBoardKey @"board"
#define kWallsKey @"walls"
#define kMinX @"minX"
#define kMinY @"minY"

@implementation LevelInfo

- (id)initWithStart:(CGPoint)start end:(CGPoint)end matrix:(NSArray*)matrix walls:(NSArray*)walls
{
    self = [super init];
    if (self) {
        self.start=start;
        self.end=end;
        self.walls=[walls mutableCopy];
    
        
        self.board=[self generateBoardFromMatrix:matrix];

    }
    
    return self;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
    
    self=[super init];
    if (self){
        self.start=[[dict objectForKey:kStartKey]CGPointValue];
        self.end=[[dict objectForKey:kEndKey]CGPointValue];
        
        self.walls=[dict objectForKey:kWallsKey];
        
        self.board=[dict objectForKey:kBoardKey];
        
        self.minX= [dict objectForKey:kMinX];
        self.minY=[dict objectForKey:kMinY];
       
        
        
        
    }
    return self;
    
}
    
    

-(NSDictionary *)getDictionary{
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSValue valueWithCGPoint:self.start], kStartKey,
            [NSValue valueWithCGPoint:self.end], kEndKey,
            self.board, kBoardKey,
            self.walls, kWallsKey,
            self.minX, kMinX,
            self.minY, kMinY,
            nil];
}

-(NSMutableArray*)generateBoardFromMatrix:(NSArray*) matrix{
    NSMutableArray *board= [NSMutableArray array];
    
    NSDictionary *cropedDict =[GeometryHelper cropMatrix:matrix];
    self.minX=[cropedDict objectForKey:@"minX"];
    self.minY=[cropedDict objectForKey:@"minY"];
    NSArray*  cropedMatrix= [cropedDict objectForKey:@"matrix"];
   // NSLog(@"%i",cropedMatrix.count);
    
    for(int x=0; x<cropedMatrix.count; x++){
        [board addObject:[NSMutableArray array]];
      for(int y=0; y<((NSMutableArray*)cropedMatrix[x]).count; y++){
          MazeNode *node = cropedMatrix[x][y];
          if ([node isKindOfClass:[MazeNode class]] && node.isWall){
               [board[x] addObject:[NSNumber numberWithInteger:2]];
               NSLog(@"%@", board[x][y]);
          }
          
          if ([node isKindOfClass:[MazeNode class]] && node.isStart){
              [board[x] addObject:[NSNumber numberWithInteger:3]];
              NSLog(@"%@", board[x][y]);
          }
          
          if ([node isKindOfClass:[MazeNode class]] && node.isEnd){
              [board[x] addObject:[NSNumber numberWithInteger:4]];
              NSLog(@"%@", board[x][y]);
          }
          
          else if ([node isKindOfClass:[MazeNode class]] && !node.isWall && !node.isEnd && !node.isStart){
               [board[x] addObject:[NSNumber numberWithInteger:1]];
               NSLog(@"%@", board[x][y]);
           }
           else {
               [board[x] addObject:[NSNumber numberWithInteger:0]];
                NSLog(@"%@", board[x][y]);
           }
           
               }  //NSLog(@"%@", board[x][y]);
            }

    return board;
}


@end

