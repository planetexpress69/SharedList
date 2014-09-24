//
//  PreferenceViewController.m
//  SharedList
//
//  Created by Martin Kautz on 23.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "PreferenceViewController.h"
#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>


@interface PreferenceViewController ()

@end

@implementation PreferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Einstellungen";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.theEndpointTextField.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"syncpoint"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (IBAction)triggerDelete:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Delete"
                                                       message:@"This will delete the entire list from all devices. Are you sure?"
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:@"OK", nil];
    [alertView show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {

        NSError *fetchError = nil;
        CBLQuery* query = [[self.database viewNamed: @"byDate"] createQuery];
        CBLQueryEnumerator* result = [query run: &fetchError];

        if (!fetchError) {

            for (CBLQueryRow *row in result) {
                CBLDocument *doc = [self.database documentWithID:row.documentID];
                NSError* deleteError;
                if (![doc deleteDocument:&deleteError]) {
                    NSLog(@"Error: %@", deleteError);
                }
                else {
                    NSError *compactError = nil;
                    if (![self.database compact:&compactError]) {
                        NSLog(@"Error: %@", compactError);
                    }
                    else {
                        NSLog(@"All done!");
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidChangeRecordNotification" object:nil];
                    }
                }
            }
        }
        else {
            NSLog(@"Error: %@", fetchError);
        }
    }
}

// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lazy loading of our database (from delegate)
// ---------------------------------------------------------------------------------------------------------------------
- (CBLDatabase *)database
{
    if (_database == nil) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        _database = appDelegate.database;
    }
    return _database;
}


@end
