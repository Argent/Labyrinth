//
//  SettingsStore.h
//  Labyrinth
//
//  Created by Benjamin Otto on 29.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsStore : NSObject

+(SettingsStore*)sharedStore;

@property (nonatomic) int hexSize;

@end
