//
//  LevelsCell.m
//  Labyrinth
//
//  Created by Corina Schemainda on 11.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import "LevelsCell.h"

@implementation LevelsCell


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
        
        self.contentView.layer.borderWidth = 2.0;
        self.contentView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.backgroundColor = [UIColor darkGrayColor];
        
        
        self.label= [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height)];
        self.label.center=CGPointMake(frame.size.width/2, frame.size.height/2);
        self.label.textAlignment=NSTextAlignmentCenter;
        
        [self.contentView addSubview:_label];
        
        self.imgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height)];
        
        [self.contentView addSubview:self.imgView];
        
        
        /* UIView *backgroundView = [[UIView alloc]initWithFrame:self.bounds];
         backgroundView.layer.borderColor = [[UIColor whiteColor]CGColor];
         backgroundView.layer.borderWidth = 2.0f;
         self.selectedBackgroundView = backgroundView;*/
        
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

@end
