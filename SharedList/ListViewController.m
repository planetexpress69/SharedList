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

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Hungerliste";

    // get a reference to the database from delegate
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.database = appDelegate.database;

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



    NSAssert(self.database != nil, @"Not hooked up to database yet");
    CBLLiveQuery* query = [[[self.database viewNamed:@"byDate"] createQuery] asLiveQuery];
    query.descending = YES;
    self.dataSource.query = query;

    // Configure sync if necessary:
    [self updateSyncURL];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear!");
    self.navigationController.toolbarHidden = NO;
    [[UIToolbar appearance]setTintColor:[UIColor whiteColor]];
}


// Updates the database's sync URL from the saved pref.
- (void)updateSyncURL {
    if (!self.database)
        return;


    NSURL* newRemoteURL = nil;
    NSString *pref = [[NSUserDefaults standardUserDefaults] objectForKey:@"syncpoint"];
    if (pref.length > 0)
        newRemoteURL = [NSURL URLWithString: pref];

    [self forgetSync];

    if (newRemoteURL) {

        NSLog(@"sssss");
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


// Stops observing the current push/pull replications, if any.
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




#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {


    DetailViewController *detailViewController = [segue destinationViewController];

    if ([segue.identifier isEqualToString:@"addSegue"]) {
        detailViewController.mode = DetailControllerModeAdd;
        detailViewController.record = nil;
    } else {
        detailViewController.mode = DetailControllerModeEdt;
        ListCell *selectedCell = (ListCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
        CBLQueryRow *row        = self.dataSource.rows[indexPath.row];
        CBLDocument *doc        = row.document;
        detailViewController.record = doc;
    }


    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


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


// Called in response to replication-change notifications. Updates the progress UI.
- (void) replicationProgress: (NSNotificationCenter*)n {
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

/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}
 */

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58.0f;
}


@end
