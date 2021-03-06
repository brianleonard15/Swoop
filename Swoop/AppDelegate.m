//
//  AppDelegate.m
//  Swoop
//
//  Created by Brian on 1/1/15.
//  Copyright (c) 2015 Brian Leonard. All rights reserved.
//

#import "AppDelegate.h"
#import <Quickblox/Quickblox.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Set QuickBlox credentials
    //
    [QBApplication sharedApplication].applicationId = 18124;
    [QBConnection registerServiceKey:@"RpuP8gbgbRLf3EH"];
    [QBConnection registerServiceSecret:@"RZSMHBryBDuaMpm"];
    [QBSettings setAccountKey:@"ESNqqzHrGdWb3iwapocg"];
    [[UITabBar appearance] setBarTintColor:[UIColor clearColor]];
    [[UITabBar appearance] setBackgroundImage:[UIImage new]];
    [[UITabBar appearance] setBackgroundColor:[UIColor clearColor]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    QBUUser *currentUser = [QBUUser user];
    currentUser.customData = @"offline";
    [QBRequest updateUser:currentUser successBlock:^(QBResponse *response, QBUUser *user) {
        // User updated successfully
        NSLog(@"yay");
    } errorBlock:^(QBResponse *response) {
        // Handle error
        NSLog(@"uhoh");
    }];

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    QBUUser *currentUser = [QBUUser user];
    currentUser.customData = @"online";
    [QBRequest updateUser:currentUser successBlock:^(QBResponse *response, QBUUser *user) {
        // User updated successfully
        NSLog(@"yay");
    } errorBlock:^(QBResponse *response) {
        // Handle error
        NSLog(@"uhoh");
    }];

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
