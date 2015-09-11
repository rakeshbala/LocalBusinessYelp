//
//  AppDelegate.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "AppDelegate.h"
#import "OAuthClass.h"

@interface AppDelegate ()
@property (strong, nonatomic) NSMutableData *container;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.container = [NSMutableData data];
    OAuthClass *oCl = [[OAuthClass alloc]init];
    NSMutableURLRequest *req = [oCl createRequest];
    
    NSURLConnection *conn = [[NSURLConnection alloc]initWithRequest:req delegate:self startImmediately:NO];
    [conn start];
    return YES;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    [self.container appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"%@",response);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString *fullResponse = [[NSString alloc]initWithData:self.container encoding:NSUTF8StringEncoding];
    NSLog(@"%@",fullResponse);
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"%@",error.localizedDescription);
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
