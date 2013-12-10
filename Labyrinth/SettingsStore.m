//
//  SettingsStore.m
//  Labyrinth
//
//  Created by Benjamin Otto on 29.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "SettingsStore.h"

@implementation SettingsStore

+(SettingsStore *)sharedStore{
    static SettingsStore *sharedStore = nil;
    if (!sharedStore){
        sharedStore = [[super allocWithZone:nil]init];
        sharedStore.hexSize = 30;
    }
    return sharedStore;
}

-(float)width {
    return sqrt(3) / 2.0 * self.height;
}

-(float)height {
    return self.hexSize * 2;
}


@end
