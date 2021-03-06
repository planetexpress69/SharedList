//
//  AppDelegate.m
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "AppDelegate.h"
#import "ListViewController.h"
#import <Couchbaselite/CouchbaseLite.h>

#define kDefaultUser            @"Birte"
#define kDatabaseName           @"spendings"
#define kDefaultSyncDbURL       @"http://couch.nets.de:5984/spendings"


@interface AppDelegate ()
@end

@implementation AppDelegate
// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (instancetype)init
{
    if (self = [super init]) {

        // Register default URL to sync with
        NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
        NSDictionary *appdefaults   = @{
                                        @"syncpoint" : kDefaultSyncDbURL,
                                        @"user" : kDefaultUser
                                        };
        [defaults registerDefaults:appdefaults];
        [defaults synchronize];

        // Initialize Couchbase Lite and find/create my database:
        NSError* error;
        self.database = [[CBLManager sharedInstance] databaseNamed: @"spendings" error:&error];
        if (!self.database) {
            [self showAlert:@"Couldn't open database" error:error fatal:YES];
        }

        // Define a view with a map function that indexes to-do items by creation date:
        [[self.database viewNamed: @"byDate"] setMapBlock: MAPBLOCK({
            id date = doc[@"created_at"];
            if (date)
                emit(date, doc);
        }) reduceBlock: nil version: @"1.1"];

        // and a validation function requiring parseable dates:
        [self.database setValidationNamed: @"created_at" asBlock: VALIDATIONBLOCK({
            if (newRevision.isDeletion)
                return;
            id date = (newRevision.properties)[@"created_at"];
            if (date && ! [CBLJSON dateWithJSONObject: date]) {
                [context rejectWithMessage: [@"invalid date " stringByAppendingString: [date description]]];
            }
        })];

        [[UITextField appearance] setTintColor:[UIColor blackColor]];

    }
    return self;
}

// ---------------------------------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"26fd72e47692482a823b13ba0b82069a"];
    //[[BITHockeyManager sharedHockeyManager] startManager];
    //[[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    [self setupUI];

    return YES;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
    // or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
    // Games should use this method to pause the game.
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application
    // state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of
    // applicationWillTerminate: when the user quits.
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive.
    // If the application was previously in the background, optionally refresh the user interface.
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate.
    // See also applicationDidEnterBackground:.
}

// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Error helper
// ---------------------------------------------------------------------------------------------------------------------
- (void)showAlert: (NSString*)message error: (NSError*)error fatal: (BOOL)fatal
{
    if (error) {
        message = [NSString stringWithFormat: @"%@\n\n%@", message, error.localizedDescription];
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: (fatal ? @"Fatal Error" : @"Error")
                                                    message: message
                                                   delegate: (fatal ? self : nil)
                                          cancelButtonTitle: (fatal ? @"Quit" : @"Sorry")
                                          otherButtonTitles: nil];
    [alert show];
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    exit(0);
}

// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - UI appearance code
// ---------------------------------------------------------------------------------------------------------------------
- (void)setupUI
{
    UIFont *titleFont       = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f];
    UIFont *barButtonFont   = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];

    //[[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:1.0 green:0.3 blue:0.0 alpha:.8]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];


    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName   : [UIColor whiteColor],
                                                           NSFontAttributeName              : titleFont
                                                           }];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName   : [UIColor whiteColor],
                                                           NSFontAttributeName              : barButtonFont
                                                           }
                                                forState:UIControlStateNormal];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName   : [UIColor lightGrayColor],
                                                           NSFontAttributeName              : barButtonFont
                                                           }
                                                forState:UIControlStateDisabled];
}

@end
