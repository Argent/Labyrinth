//
//  LevelManager.h
//  Labyrinth
//
//  Created by Corina Schemainda on 16.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelInfo.h"

@interface LevelManager : NSObject

@property(nonatomic, strong) NSMutableArray *levels;

+(LevelManager*)sharedManager;
-(BOOL)saveLevel:(LevelInfo*)levelInfo forID:(NSInteger)ID;

@end
