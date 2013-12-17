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
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, readonly) int toolbarHeight;

@end
