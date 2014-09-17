//
//  ListViewController.m
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "ListViewController.h"
#import "DetailViewController.h"
#import <CouchbaseLite/CouchbaseLite.h>
#import "ListCell.h"
#import "AppDelegate.h"

@interface ListViewController ()
@end

@implementation ListViewController
// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Hungerliste";
    
    // wire the query view to the dataSource object
    CBLLiveQuery* query     = [[[self.database viewNamed:@"byDate"] createQuery] asLiveQuery];
    query.descending        = YES;
    self.dataSource.query   = query;

    // Configure sync if necessary:
    [self updateSyncURL];

}

// ---------------------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.database = nil;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear!");
    self.navigationController.toolbarHidden = NO;
    [[UIToolbar appearance]setTintColor:[UIColor whiteColor]];
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Setup sync.
// ---------------------------------------------------------------------------------------------------------------------
- (void)updateSyncURL {

    if (!self.database)
        return;

    NSURL* newRemoteURL     = nil;
    NSString *pref          = [[NSUserDefaults standardUserDefaults] objectForKey:@"syncpoint"];
    if (pref.length > 0)
        newRemoteURL = [NSURL URLWithString: pref];

    [self forgetSync];

    if (newRemoteURL) {
        // Tell the database to use this URL for bidirectional sync.
        _pull = [self.database createPullReplication: newRemoteURL];
        _push = [self.database createPushReplication: newRemoteURL];
        _pull.continuous = _push.continuous = YES;
        // Observe replication progress changes, in both directions:
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(replicationProgress:)
                     name: kCBLReplicationChangeNotification object: _pull];
        [nctr addObserver: self selector: @selector(replicationProgress:)
                     name: kCBLReplicationChangeNotification object: _push];
        [_push start];
        [_pull start];
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Stop observing current push/pull replication, if any.
// ---------------------------------------------------------------------------------------------------------------------
- (void) forgetSync {
    NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
    if (_pull) {
        [nctr removeObserver: self name: nil object: _pull];
        _pull = nil;
    }
    if (_push) {
        [nctr removeObserver: self name: nil object: _push];
        _push = nil;
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Navigation - Preparation before pushing the DetailViewController
// ---------------------------------------------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    DetailViewController *detailViewController = [segue destinationViewController]; // get controller from storyboard

    if ([segue.identifier isEqualToString:@"addSegue"]) {
        detailViewController.mode = DetailControllerModeAdd;
        detailViewController.record = nil;
    }
    else {
        detailViewController.mode = DetailControllerModeEdt;

        // get the appr. record from selected cell and pass it to the detail view controller
        ListCell *selectedCell = (ListCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
        CBLQueryRow *row        = self.dataSource.rows[indexPath.row];
        CBLDocument *doc        = row.document;
        detailViewController.record = doc;
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - CBLUITableDelegate <UITableViewDelegate> protocol methods
// ---------------------------------------------------------------------------------------------------------------------
/** Allows delegate to return its own custom cell, just like -tableView:cellForRowAtIndexPath:.
 If this returns nil the table source will create its own cell, as if this method were not implemented. */
- (UITableViewCell *)couchTableSource:(CBLUITableSource*)source
                cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    CBLQueryRow *row        = source.rows[indexPath.row];
    CBLDocument *doc        = row.document;
    NSDictionary *props     = doc.properties;

    static NSString *CellIdentifier = @"ListCell";
    ListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.itemNameLabel.highlightedTextColor = [UIColor whiteColor];

    cell.itemNameLabel.text     = props[@"item"];
    cell.spenderLabel.text      = props[@"user"];
    cell.dateLabel.text         = props[@"date"];
    cell.valueLabel.text        = [NSString stringWithFormat:@"%.2f", ((NSNumber *)props[@"price"]).floatValue];
    return cell;
}

/** Called after the query's results change, before the table view is reloaded. */
/*
- (void)couchTableSource:(CBLUITableSource*)source
     willUpdateFromQuery:(CBLLiveQuery*)query
{
    NSLog(@"couchTableSource:willUpdateFromQuery");
}
*/

/** Called after the query's results change to update the table view. 
 If this method is not implemented by the delegate, reloadData is called on the table view.*/
/*
- (void)couchTableSource:(CBLUITableSource*)source
         updateFromQuery:(CBLLiveQuery*)query
            previousRows:(NSArray *)previousRows
{
    NSLog(@"couchTableSource:updateFromQuery:previousRows");
}
*/
/** Called from -tableView:cellForRowAtIndexPath: just before it returns, 
 giving the delegate a chance to customize the new cell. */
/*
- (void)couchTableSource:(CBLUITableSource*)source
             willUseCell:(UITableViewCell*)cell
                  forRow:(CBLQueryRow*)row
{
    NSLog(@"couchTableSource:willUseCell:forRow");
}
*/

/** Called when the user wants to delete a row.
 If the delegate implements this method, it will be called *instead of* the
 default behavior of deleting the associated document.
 @param source  The CBLUITableSource
 @param row  The query row corresponding to the row to delete
 @return  True if the row was deleted, false if not. */
/*
- (bool)couchTableSource:(CBLUITableSource*)source
               deleteRow:(CBLQueryRow*)row
{
    NSLog(@"couchTableSource:deleteRow:");
    return YES;
}
*/

/** Called upon failure of a document deletion triggered by the user deleting a row. */
/*
- (void)couchTableSource:(CBLUITableSource*)source
            deleteFailed:(NSError*)error
{
    NSLog(@"couchTableSource:deleteFailed:");
}
*/


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Callbacks to update UI in dependance of sync's progress
// ---------------------------------------------------------------------------------------------------------------------
- (void) replicationProgress: (NSNotificationCenter*)n
{
    if (_pull.status == kCBLReplicationActive || _push.status == kCBLReplicationActive) {
        // Sync is active -- aggregate the progress of both replications and compute a fraction:
        unsigned completed = _pull.completedChangesCount + _push.completedChangesCount;
        unsigned total = _pull.changesCount+ _push.changesCount;
        NSLog(@"SYNC progress: %u / %u", completed, total);
        ////[self showSyncStatus];
        // Update the progress bar, avoiding divide-by-zero exceptions:
        ////progress.progress = (completed / (float)MAX(total, 1u));
    } else {
        // Sync is idle -- hide the progress bar and show the config button:
        ////[self showSyncButton];
    }

    // Check for any change in error status and display new errors:
    NSError* error = _pull.lastError ? _pull.lastError : _push.lastError;
    if (error != _syncError) {
        _syncError = error;
        if (error) {
            NSLog(@"error: %@", error);
        }
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate protocol methods
// ---------------------------------------------------------------------------------------------------------------------
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58.0f;
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