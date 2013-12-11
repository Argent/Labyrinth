//
//  TwoFingerScrollView.m
//  Labyrinth
//
//  Created by Benjamin Otto on 11.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "TwoFingerScrollView.h"

@implementation TwoFingerScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        for (UIGestureRecognizer* r in self.gestureRecognizers) {
            if ([r isKindOfClass:[UIPanGestureRecognizer class]]) {
                [((UIPanGestureRecognizer*)r) setMaximumNumberOfTouches:2];
                [((UIPanGestureRecognizer*)r) setMinimumNumberOfTouches:2];
                zoomScale[0] = -1.0;
                zoomScale[1] = -1.0;
            }
            timerWasDelayed = NO;
        }

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

-(void)lockZoomScale {
    
    
    zoomScale[0] = self.minimumZoomScale;
    zoomScale[1] = self.maximumZoomScale;
    [self setMinimumZoomScale:self.zoomScale];
    [self setMaximumZoomScale:self.zoomScale];
  //  NSLog(@"locked %.2f %.2f",self.minimumZoomScale,self.maximumZoomScale);
}
-(void)unlockZoomScale {
    if (zoomScale[0] != -1 && zoomScale[1] != -1) {
        [self setMinimumZoomScale:zoomScale[0]];
        [self setMaximumZoomScale:zoomScale[1]];
        zoomScale[0] = -1.0;
        zoomScale[1] = -1.0;
      //  NSLog(@"unlocked %.2f %.2f",self.minimumZoomScale,self.maximumZoomScale);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   // NSLog(@"began %i",[event allTouches].count);
    [self setCanCancelContentTouches:YES];
    if ([event allTouches].count == 1){
        touchesBeganTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(firstTouchTimerFired:) userInfo:nil repeats:NO];
        //[touchesBeganTimer retain];
        [touchFilter touchesBegan:touches withEvent:event];
    }
}

//if one finger touch gets canceled by two finger touch, this timer gets delayed
// so we can! use this method to disable zooming, because it doesnt get called when two finger touch events are wanted; otherwise we would disable zooming while zooming
-(void)firstTouchTimerFired:(NSTimer*)timer {
   // NSLog(@"fired");
    [self setCanCancelContentTouches:NO];
    //if already locked: unlock
    //this happens because two finger gesture delays timer until touch event finishes.. then we dont want to lock!
    if (timerWasDelayed) {
        [self unlockZoomScale];
    }
    else {
        [self lockZoomScale];
    }
    timerWasDelayed = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //    NSLog(@"moved %i",[event allTouches].count);
    [touchFilter touchesMoved:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
   // NSLog(@"ended %i",[event allTouches].count);
    [touchFilter touchesEnded:touches withEvent:event];
    [self unlockZoomScale];
}

//[self setCanCancelContentTouches:NO];
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
   // NSLog(@"canceled %i",[event allTouches].count);
    [touchFilter touchesCancelled:touches withEvent:event];
    [self unlockZoomScale];
    timerWasDelayed = YES;
}





@end
