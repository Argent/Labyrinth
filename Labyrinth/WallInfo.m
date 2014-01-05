//
//  WallInfo.m
//  Labyrinth
//
//  Created by Corina Schemainda on 03.01.14.
//  Copyright (c) 2014 Benjamin Otto. All rights reserved.
//

#import "WallInfo.h"
#import "NSMutableArray+QueueAdditions.h"
#import "MazeNode.h"
#import "MazeObject.h"

@implementation WallInfo

-(id)initWithNodes:(NSMutableArray*) nodes{
    self = [super init];
    if (self) {}
    
    return self;
}
  /*  NSMutableArray* wallArray=[NSMutableArray array];
    MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0, 0)];
        for (int x=0; x<nodes.count; x++) {
           // if (nodes[x]==1){
                [wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
            }
        }
 
   
        
        
        
    }
    return self;
}*/




/*NSMutableArray* wallArray=[NSMutableArray array];
MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(0, 0)];
[wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
[wallArray addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];*/









/*NSMutableArray *wallNodes = [NSMutableArray array];
MazeObject *obj = [MazeObject objectWithType:WALL andCenter:CGPointMake(50, 60)];
[wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(0,0)]];
[wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(1,0)]];
[wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,1)]];
[wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,2)]];
[wallNodes addObject:[obj generateAndAddNodeRelative:CGPointMake(-1,3)]];*/
    

@end
