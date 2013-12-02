//
//  UIBezierView.m
//  Labyrinth
//
//  Created by Benjamin Otto on 01.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "UIBezierView.h"

@implementation UIBezierView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [super drawRect:rect];
    UIBezierPath *path = self.curvePath;
    if(path){
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle = kCGLineJoinBevel;
        [[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5] setStroke];
        path.lineWidth = 15.0;
        [path stroke];
    }
}


@end
