//
//  UILabyrinthMenu.m
//  Labyrinth
//
//  Created by Benjamin Otto on 16.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "UILabyrinthMenu.h"

@interface UILabyrinthMenu(){
    UILabel *stepsCounter;
    UILabel *coinCounter;
 
    bool paused;
}
@end

@implementation UILabyrinthMenu

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        paused = YES;
        
        self.startButton = [[UIButton alloc]initWithFrame:CGRectMake(5, 0, 60, 40)];
        [self.startButton setTitle:@"Play" forState:UIControlStateNormal];
        [self.startButton addTarget:self action:@selector(startButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.startButton];
        self.stopButton = [[UIButton alloc]initWithFrame:CGRectMake(70, 0, 40, 40)];
        [self.stopButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self.stopButton addTarget:self action:@selector(stopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.stopButton];
        
        stepsCounter = [[UILabel alloc]initWithFrame:CGRectMake(130, 5, 100, 30)];
        stepsCounter.text = @"Steps: 0";
        stepsCounter.textColor = [UIColor whiteColor];
        stepsCounter.font = [UIFont boldSystemFontOfSize:20];
        coinCounter = [[UILabel alloc]initWithFrame:CGRectMake(230, 5, 80, 30)];
        coinCounter.text = @"Coins: 0";
        coinCounter.textColor = [UIColor whiteColor];
        coinCounter.font = [UIFont boldSystemFontOfSize:20];
        
        [self addSubview:stepsCounter];
        [self addSubview:coinCounter];
    }
    return self;
}

-(void)setCoins:(int)coins{
    _coins = coins;
    coinCounter.text = [NSString stringWithFormat:@"Coins: %i",_coins];
}

-(void)setSteps:(int)steps{
    _steps = steps;
    stepsCounter.text = [NSString stringWithFormat:@"Steps: %i",_steps];
}

-(IBAction)startButtonPressed:(id)sender{
    if(paused){
        paused = NO;
        [self.startButton setTitle:@"Pause" forState:UIControlStateNormal];
        
    }else {
        paused = YES;
        [self.startButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    if (self.startPauseBlock){
        self.startPauseBlock(!paused);
    }
    
}

-(IBAction)stopButtonPressed:(id)sender{
    if (self.stopBlock){
        self.stopBlock();
    }
    if (!paused){
        paused = YES;
        [self.startButton setTitle:@"Play" forState:UIControlStateNormal];

    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
