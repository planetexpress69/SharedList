//
//  ListViewController.h
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@class CBLDatabase, CBLReplication, StatusViewController, PreferenceViewController;

@interface ListViewController : UIViewController <CBLUITableDelegate>
{
    NSURL* remoteSyncURL;
    CBLReplication* _pull;
    CBLReplication* _push;
    NSError* _syncError;

}
// ---------------------------------------------------------------------------------------------------------------------
@property (strong, nonatomic)               CBLDatabase                 *database;
@property (weak, nonatomic)     IBOutlet    UITableView                 *tableView;
@property (weak, nonatomic)     IBOutlet    CBLUITableSource            *dataSource;
@property (strong, nonatomic)               StatusViewController        *statusViewController;
@property (strong, nonatomic)               PreferenceViewController    *prefsViewController;
@property (weak, nonatomic)     IBOutlet    UIBarButtonItem             *prefsButton;
// ---------------------------------------------------------------------------------------------------------------------
@end
