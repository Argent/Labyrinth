//
//  AppDelegate.m
//  Labyrinth
//
//  Created by Benjamin Otto on 26.11.13.
//  Copyright (c) 2013 Benjamin Otto. All rights reserved.
//

#import "AppDelegate.h"
#import "LevelInfo.h"
#import "LevelsMenuViewController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //get file paths
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentPaths objectAtIndex:0];
    NSString *documentPlistPath = [documentsDirectory stringByAppendingPathComponent:@"levels.plist"];
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *bundlePlistPath = [bundlePath stringByAppendingPathComponent:@"levels.plist"];
    NSError *error = nil;
    
    //if file exists in the documents directory, get it
    if([[NSFileManager defaultManager] fileExistsAtPath:documentPlistPath]){
        NSLog(@"file already exists");
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:documentPlistPath error:&error];
        NSDate *dateDocuments;
        if (!error) {
            dateDocuments = [attributes fileModificationDate];
            NSLog(@"Date documents: %@", dateDocuments);
        }else {
            NSLog(@"Error description: %@ \n", [error localizedDescription]);
            NSLog(@"Error reason: %@", [error localizedFailureReason]);
        }
        
        NSError *error2;
        attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:bundlePlistPath error:&error2];
        NSDate *dateBundle;
        if (!error2){
            dateBundle = [attributes fileModificationDate];
            NSLog(@"Date bundle: %@", dateBundle);
        }else {
            NSLog(@"Error description: %@ \n", [error localizedDescription]);
            NSLog(@"Error reason: %@", [error localizedFailureReason]);
        }
        
        if (dateBundle && dateDocuments) {
            if ([dateBundle compare:dateDocuments] > 0){
                error = nil;
                NSLog(@"bundle file newer");
                if ([[NSFileManager defaultManager]removeItemAtPath:documentPlistPath error:&error]){
                    NSLog(@"removed older file from documents dir");
                    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:bundlePlistPath toPath:documentPlistPath error:&error];
                    if (!success){
                        NSLog(@"Error description: %@ \n", [error localizedDescription]);
                        NSLog(@"Error reason: %@", [error localizedFailureReason]);
                    }else {
                        NSLog(@"copied newer item");
                    }
                }
            }else {
                NSLog(@"documents file newer");
            }
        }
    }
    //if file does not exist, create it from existing plist
    else {
        
        BOOL success = [[NSFileManager defaultManager] copyItemAtPath:bundlePlistPath toPath:documentPlistPath error:&error];
        if (!success){
            NSLog(@"Error description: %@ \n", [error localizedDescription]);
            NSLog(@"Error reason: %@", [error localizedFailureReason]);
        }
        
    }
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    //self.rootViewController = [[LabyrinthViewController alloc]initWithNibName:nil bundle:nil];
    //self.rootViewController = [[LabyrinthEditorViewController alloc]initWithNibName:nil bundle:nil];
    self.rootViewController = [[StartMenuViewController alloc]initWithNibName:@"StartMenuViewController" bundle:nil];
    //self.rootViewController = [[LevelsMenuViewController alloc]initWithNibName:@"LevelsMenuViewController" bundle:nil];
    self.window.rootViewController = self.rootViewController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
