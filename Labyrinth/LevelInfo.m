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
#define kHighScore @"highscore"
#define kStepDuration @"stepduration"
#define kBoardKey @"board"
#define kWallsKey @"walls"
#define kMinX @"minX"
#define kMinY @"minY"
#define kName @"name"

@implementation LevelInfo

- (id)initWithMatrix:(NSArray*)matrix walls:(NSDictionary*)walls name:(NSString*)name
{
    self = [super init];
    if (self) {

        self.walls=[walls mutableCopy];
        self.name=name;
        
        self.board=[self generateBoardFromMatrix:matrix];
        
    }
    
    return self;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
    
    self=[super init];
    if (self){
        self.walls=[dict objectForKey:kWallsKey];
        
        self.board=[dict objectForKey:kBoardKey];
        
        self.minX= [dict objectForKey:kMinX];
        self.minY=[dict objectForKey:kMinY];
        
        self.name = [dict objectForKey:kName];
        
        self.stepDuration = [[dict objectForKey:kStepDuration]floatValue];
        self.highScore = [[dict objectForKey:kHighScore]intValue];
        
    }
    return self;
    
}


-(NSDictionary *)getDictionary{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.board forKey:kBoardKey];
    
    if(!self.name){
        self.name=@"noName";
    }
    
    [dict setObject:self.name forKey:kName];
    
    NSLog(@"namegetDict:%@",self.name);
    
    if (self.walls) {
        [dict setObject:self.walls forKey:kWallsKey];
    }
    if (self.minX) {
        [dict setObject:self.minX forKey:kMinX];
    }
    if (self.minY) {
        [dict setObject:self.minY forKey:kMinY];
    }
    
    [dict setObject:[NSNumber numberWithFloat:self.stepDuration] forKey:kStepDuration];
    [dict setObject:[NSNumber numberWithInt:self.highScore] forKey:kHighScore];
    
    return dict;
}

-(NSMutableArray*)generateBoardFromMatrix:(NSArray*) matrix{
    NSMutableArray *board= [NSMutableArray array];
    
    NSDictionary *cropedDict =[GeometryHelper cropMatrix:matrix];
    self.minX=[cropedDict objectForKey:@"minX"];
    NSLog(@"minX:%@", self.minX);
    self.minY=[cropedDict objectForKey:@"minY"];
    NSLog(@"minY:%@", self.minY);
    NSArray*  cropedMatrix= [cropedDict objectForKey:@"matrix"];
    // NSLog(@"%i",cropedMatrix.count);
    
    for(int x=0; x<cropedMatrix.count; x++){
        [board addObject:[NSMutableArray array]];
        for(int y=0; y<((NSMutableArray*)cropedMatrix[x]).count; y++){
            MazeNode *node = cropedMatrix[x][y];
            if ([node isKindOfClass:[MazeNode class]] && node.isWall){
                [board[x] addObject:[NSNumber numberWithInteger:2]];
            }
            else if ([node isKindOfClass:[MazeNode class]] && node.object && node.object.type == START){
                [board[x] addObject:[NSNumber numberWithInteger:3]];
            }
            else if ([node isKindOfClass:[MazeNode class]] && node.object && node.object.type == COIN){
                [board[x] addObject:[NSNumber numberWithInteger:5]];
            }
            
            else if ([node isKindOfClass:[MazeNode class]] && node.object && node.object.type == END){
                [board[x] addObject:[NSNumber numberWithInteger:4]];
            }
            
            else if ([node isKindOfClass:[MazeNode class]] && !node.object){
                [board[x] addObject:[NSNumber numberWithInteger:1]];
            }
            else {
                [board[x] addObject:[NSNumber numberWithInteger:0]];
            }
            //NSLog(@"(x:%i,y:%i) = %@", x,y,board[x][y]);
            
        }
    }
    
    return board;
}





@end

