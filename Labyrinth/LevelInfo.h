//
//  LevelInfo.h
//  Labyrinth
//
//  Created by Corina Schemainda on 16.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LevelInfo : NSObject
@property (nonatomic,strong)  NSMutableArray *board;
@property (nonatomic,strong) NSNumber *minX;
@property (nonatomic,strong) NSNumber *minY;
@property (nonatomic) CGPoint start;
@property (nonatomic) CGPoint end;
@property (nonatomic, strong) NSMutableArray *walls;

- (id)initWithStart:(CGPoint)start end:(CGPoint)end matrix:(NSArray*)matrix walls:(NSArray*)walls;
- (id)initWithDictionary:(NSDictionary*)dict;
- (NSDictionary*) getDictionary;

@end


