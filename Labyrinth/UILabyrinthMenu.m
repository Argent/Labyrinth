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
 
    bool inAction;
}
@end

@implementation UILabyrinthMenu

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        inAction = NO;
        
        self.startButton = [[UIButton alloc]initWithFrame:CGRectMake(70, 0, 40, 40)];
        [self.startButton setTitle:@"Play" forState:UIControlStateNormal];
        [self.startButton addTarget:self action:@selector(startButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.startButton];
        self.stopButton = [[UIButton alloc]initWithFrame:CGRectMake(5, 8, 60, 25)];
        [self.stopButton setTitle:@"   Back" forState:UIControlStateNormal];
        [self.stopButton setBackgroundImage:[UIImage imageNamed:@"back_arrow.png"] forState:UIControlStateNormal];
        [self.stopButton setTitleColor:[UIColor colorWithRed:0.224 green:0.504 blue:0.915 alpha:1.000] forState:UIControlStateNormal];
        [self.stopButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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
    if(inAction){
        inAction = NO;
        [self.startButton setTitle:@"Play" forState:UIControlStateNormal];
        if(self.stopBlock){
            self.stopBlock();
        }
    }else {
        inAction = YES;
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
        if (self.startPauseBlock){
            self.startPauseBlock(inAction);
        }
    }
    
    
}

-(IBAction)backButtonPressed:(id)sender{
    if (self.backBlock){
        self.backBlock();
    }
}

-(void)resetButton{
    inAction = NO;
    [self.startButton setTitle:@"Play" forState:UIControlStateNormal];
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
