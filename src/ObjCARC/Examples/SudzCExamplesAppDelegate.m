//
//  SudzCExamplesAppDelegate.m
//  SudzCExamples
//
//  An example application for the generated data
//  Generated by Sudz-C (https://github.com/jkichline/sudzc)
//

#import "SudzCExamplesAppDelegate.h"

@implementation SudzCExamplesAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
