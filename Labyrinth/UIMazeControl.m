//
//  UIMazeControl.m
//  Labyrinth
//
//  Created by Benjamin Otto on 29.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "UIMazeControl.h"

@implementation UIMazeControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] initWithFrame:self.frame];
    
    if (copy) {
        // Copy NSObject subclasses
        [copy setMazeObject:self.mazeObject];
        [copy setView:self.view];
    }
    
    return copy;
}

@end
