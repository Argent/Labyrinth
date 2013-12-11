//
//  TwoFingerScrollView.h
//  Labyrinth
//
//  Created by Benjamin Otto on 11.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwoFingerScrollView : UIScrollView{
    IBOutlet UIResponder *touchFilter;
    
    NSSet* savedTouches;
    UIEvent* savedEvent;
    NSTimer* touchesBeganTimer;
    BOOL allowMultiTouch;
    
    double pass2scroller;
    float zoomScale[2];
    BOOL timerWasDelayed;
}



@end
