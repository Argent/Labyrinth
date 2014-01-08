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
@property (nonatomic, strong) NSMutableArray *walls;
@property (nonatomic) NSString *name;

- (id)initWithMatrix:(NSArray*)matrix walls:(NSArray*)walls name:(NSString*)name;
- (id)initWithDictionary:(NSDictionary*)dict;
- (NSDictionary*) getDictionary;

@end


