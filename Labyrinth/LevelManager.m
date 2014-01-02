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
        if(ID<0 || ID>=self.levels.count|| self.levels.count==0){
            NSDictionary *dict = [levelInfo getDictionary];
        [self.levels addObject:dict];
        }
        
        else {
            NSDictionary *dict = [levelInfo getDictionary];
            [self.levels replaceObjectAtIndex:ID withObject:dict];
        }
    }
    
    else{
        
        [self.levels removeObjectAtIndex:ID];
    }
    NSString *filename = [self levelsFileName];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.levels];
    
    if([data writeToFile:filename atomically:YES]){
        NSLog(@"hallo");
    }
    

    return true;
}

//load levels document

-(void)loadLevels{
    
    NSString *fileName = [self levelsFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        NSData *data = [NSData dataWithContentsOfFile:fileName];
        
        self.levels=[NSKeyedUnarchiver unarchiveObjectWithData:data];

    }
    else{
        self.levels=[NSMutableArray array];
    }
   
}




//search for document path

- (NSString *)levelsFileName
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
   
    
    
    
    return [documentPath stringByAppendingPathComponent:@"levels.plist"];
}

@end
