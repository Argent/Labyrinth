//
//  WallInfo.h
//  Labyrinth
//
//  Created by Corina Schemainda on 03.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WallInfo : NSObject

@property (nonatomic,strong)NSMutableArray *WallList;

-(id)initWithNodes:(NSMutableArray*) walls;

@end
