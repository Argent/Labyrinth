//
//  LevelManager.m
//  Labyrinth
//
//  Created by Corina Schemainda on 16.12.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "LevelManager.h"

@implementation LevelManager

static LevelManager *_instance;

+(LevelManager *)sharedManager{
    if(!_instance){
        _instance=[[LevelManager alloc] init];
        
    }
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self loadLevels];
    }
    return self;
}


-(BOOL)saveLevel:(LevelInfo *)levelInfo forID:(NSInteger)ID{
    
    if(levelInfo){
    if(ID<0 || ID>=self.levels.count){
        [self.levels addObject:[levelInfo getDictionary]];
    }
    else {
        
        if (levelInfo){
        
            [self.levels replaceObjectAtIndex:ID withObject:[levelInfo getDictionary]];
        }
             else
            {
                [self.levels removeObjectAtIndex:ID];
            }

    }
    
    }
    
    [self.levels writeToFile:[self levelsFileName] atomically:YES];
    

    return true;
}

//load levels document

-(void)loadLevels{
    
    NSString *fileName = [self levelsFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        self.levels=[NSMutableArray arrayWithContentsOfFile:fileName];

    }
    else
        self.levels=[NSMutableArray array];
    
    
    
}


//search for document path

- (NSString *)levelsFileName
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths lastObject];
    
    
    
    return [documentPath stringByAppendingPathComponent:@"levels.plist"];
}

@end
