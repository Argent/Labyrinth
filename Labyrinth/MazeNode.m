//
//  MazeNode.m
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "MazeNode.h"
#import "UIMazeControl.h"

@interface MazeNode(){
    NSMutableArray *neigbours;
    UIView *overlay;
}
@end


@implementation MazeNode


+(MazeNode *)node{
    return [[MazeNode alloc]init];
}

+(MazeNode *)nodeWithSize:(float)size {
    return [[MazeNode alloc]initWithSize:size];
}

-(id)init{
    self = [super init];
    if (self){
        neigbours = [NSMutableArray array];
        self.steps = -1;
    }
    return self;
}

-(id)initWithSize:(float)size {
    self = [self init];
    if (self){
        self.Size = size;
    }
    return self;
}

-(bool)isWall {
    if (!self.object)
        return NO;
    return self.object.type == WALL;
}


-(bool)isStart {
    if (!self.object)
        return NO;
    return self.object.type == START;
}


-(bool)isEnd {
    if (!self.object)
        return NO;
    return self.object.type == END;
    
}

-(void)addNeighbours:(MazeNode *)node {
    [neigbours addObject:node];
}

-(NSArray *)neighbours{
    return neigbours;
}

-(CGPoint)Anchor {
    float hex_height = self.height;
    float hex_width = self.width;
    
    CGPoint anchor = CGPointMake(self.center.x, self.center.y);
    anchor.x -= hex_width / 2;
    anchor.y -= hex_height / 2;
    return anchor;
}

-(CGRect)Frame {
    float hex_height = self.height;
    CGPoint anchor = self.Anchor;
    CGRect frame = CGRectMake(anchor.x, anchor.y, sqrt(3) / 2.0 * hex_height, self.Size * 2);
    return frame;
}

-(float)width {
    return sqrt(3) / 2.0 * self.height;
}

-(float)height {
    return self.Size * 2;
}

-(void)flashView:(UIColor *)color times:(float)times{
    if (self.uiElement){
        UIImageView *imgView;
        if ([self.uiElement isKindOfClass:[UIImageView class]]){
            imgView = (UIImageView*)self.uiElement;
        }else if ([self.uiElement isKindOfClass:[UIMazeControl class]]){
            imgView = (UIImageView*)((UIMazeControl*)self.uiElement).view;
        }else {
            return;
        }
        
        UIView *flashOverlay = [[UIView alloc] initWithFrame:[imgView frame]];
        flashOverlay.userInteractionEnabled = NO;
        
        UIImageView *maskImageView = [[UIImageView alloc] initWithImage:imgView.image];
        [maskImageView setFrame:[flashOverlay bounds]];
        
        [[flashOverlay layer] setMask:[maskImageView layer]];
        
        [flashOverlay setBackgroundColor:color];
        
        [self.uiElement addSubview:flashOverlay];
        
        flashOverlay.alpha = 0.7f;
        [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionAutoreverse animations:^{
            [UIView setAnimationRepeatCount:times / 2.0];
            flashOverlay.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [flashOverlay removeFromSuperview];
        }];
    }
}

-(void)overlayWithColor:(UIColor *)color alpha:(float)alpha {
    if (self.uiElement){
        UIImageView *imgView;
        if ([self.uiElement isKindOfClass:[UIImageView class]]){
            imgView = (UIImageView*)self.uiElement;
        }else if ([self.uiElement isKindOfClass:[UIMazeControl class]]){
            imgView = (UIImageView*)((UIMazeControl*)self.uiElement).view;
        }else {
            return;
        }
        
        if (overlay){
            [overlay removeFromSuperview];
        }
        overlay = [[UIView alloc] initWithFrame:[imgView frame]];
        overlay.userInteractionEnabled = NO;
        
        UIImageView *maskImageView = [[UIImageView alloc] initWithImage:imgView.image];
        [maskImageView setFrame:[overlay bounds]];
        
        [[overlay layer] setMask:[maskImageView layer]];
        
        [overlay setBackgroundColor:color];
        
        [self.uiElement addSubview:overlay];
        
        overlay.alpha = alpha;
    }
}

-(void)removeOverlay {
    if (overlay){
        [overlay removeFromSuperview];
        overlay = nil;
    }
}

@end
