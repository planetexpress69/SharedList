//
//  ListViewController.h
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@class CBLDatabase, CBLReplication;

@interface ListViewController : UIViewController <CBLUITableDelegate>
{
    NSURL* remoteSyncURL;
    CBLReplication* _pull;
    CBLReplication* _push;
    NSError* _syncError;

}
// ---------------------------------------------------------------------------------------------------------------------
@property (strong, nonatomic)               CBLDatabase         *database;
@property (strong, nonatomic) IBOutlet      UITableView         *tableView;
@property (strong, nonatomic) IBOutlet      CBLUITableSource    *dataSource;
// ---------------------------------------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------------------------------------
@end
