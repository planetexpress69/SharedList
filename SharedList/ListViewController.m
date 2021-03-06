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
#import "StatusViewController.h"
#import "PreferenceViewController.h"

@interface ListViewController ()
@property (nonatomic, assign) BOOL showingSyncButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation ListViewController
// -------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// -------------------------------------------------------------------------------------------------
- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Hungerliste";

  // wire the query view to the dataSource object
  CBLLiveQuery* query     = [[[self.database viewNamed:@"byDate"] createQuery] asLiveQuery];
  query.descending        = YES;
  self.dataSource.query   = query;

  [self updateSyncURL];

  self.tableView.backgroundView   = nil;
  self.tableView.backgroundColor  = [UIColor whiteColor];
  self.view.backgroundColor       = [UIColor whiteColor];

  [self.view addSubview:self.statusViewController.view];

  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(updateSyncURL)
                                              name:@"EndpointDidChangeNotification"
                                            object:nil];
}

// -------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  self.database = nil;
}

// -------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.title = @"Hungerliste";
  [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

// -------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.title = @"Hungerliste";
}

// -------------------------------------------------------------------------------------------------
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter]removeObserver:self];
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Setup sync.
// -------------------------------------------------------------------------------------------------
- (void)updateSyncURL {

  if (!self.database) {
    return;
  }
  NSURL *newRemoteURL     = nil;
  NSString *pref          = [[NSUserDefaults standardUserDefaults] objectForKey:@"syncpoint"];
  if (pref.length > 0)
    newRemoteURL = [NSURL URLWithString: pref];

  [self forgetSync];

  if (newRemoteURL) {
    // Tell the database to use this URL for bidirectional sync.
    _pull = [self.database createPullReplication:newRemoteURL];
    _push = [self.database createPushReplication:newRemoteURL];
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


// -------------------------------------------------------------------------------------------------
#pragma mark - Stop observing current push/pull replication, if any.
// -------------------------------------------------------------------------------------------------
- (void)forgetSync {
  NSNotificationCenter *nctr = [NSNotificationCenter defaultCenter];
  if (_pull) {
    [nctr removeObserver:self name:nil object:_pull];
    _pull = nil;
  }
  if (_push) {
    [nctr removeObserver:self name:nil object:_push];
    _push = nil;
  }
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Navigation - Preparation before pushing the DetailViewController
// -------------------------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"addSegue"]) {
    DetailViewController *detailViewController = [segue destinationViewController];
    detailViewController.mode = DetailControllerModeAdd;
    detailViewController.record = nil;
  }
  else if ([segue.identifier isEqualToString:@"edtSegue"]) {
    DetailViewController *detailViewController = [segue destinationViewController];
    detailViewController.mode = DetailControllerModeEdt;

    // get the appr. record from selected cell and pass it to the detail view controller
    ListCell *selectedCell      = (ListCell *)sender;
    NSIndexPath *indexPath      = [self.tableView indexPathForCell:selectedCell];
    CBLQueryRow *row            = self.dataSource.rows[indexPath.row];
    CBLDocument *doc            = row.document;
    detailViewController.record = doc;
  }
}


// -------------------------------------------------------------------------------------------------
#pragma mark - CBLUITableDelegate <UITableViewDelegate> protocol methods
// -------------------------------------------------------------------------------------------------
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

  if ([props[@"date"]length] > 10) {
    cell.dateLabel.text = [self makeTinyDate:props[@"date"]];
  }
  else {
    cell.dateLabel.text         = props[@"date"];
  }

  cell.valueLabel.text        = [NSString stringWithFormat:@"%.2f", ((NSNumber *)props[@"price"]).floatValue];
  return cell;
}

/** Called after the query's results change, before the table view is reloaded. */

- (void)couchTableSource:(CBLUITableSource*)source
     willUpdateFromQuery:(CBLLiveQuery*)query
{
  [self updateStatusView];
}


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
 [self updateStatusView];
 return YES;
 }
 */

/** Called upon failure of a document deletion triggered by the user deleting a row. */

- (void)couchTableSource:(CBLUITableSource*)source
            deleteFailed:(NSError*)error
{
  NSLog(@"couchTableSource:deleteFailed:");
}



// -------------------------------------------------------------------------------------------------
#pragma mark - Callbacks to update UI in dependance of sync's progress
// -------------------------------------------------------------------------------------------------
- (void)replicationProgress:(NSNotificationCenter*)n
{
  if (_pull.status == kCBLReplicationActive || _push.status == kCBLReplicationActive) {
    // Sync is active -- aggregate the progress of both replications and compute a fraction:
    unsigned completed = _pull.completedChangesCount + _push.completedChangesCount;
    unsigned total = _pull.changesCount+ _push.changesCount;
    NSLog(@"SYNC progress: %u / %u", completed, total);
    [self runSpinAnimationOnView:self.prefsButton.customView duration:3.0f rotations:1 repeat:1];
    [self showSyncStatus];
    // Update the progress bar, avoiding divide-by-zero exceptions:
    ////progress.progress = (completed / (float)MAX(total, 1u));
  } else {
    // Sync is idle -- hide the progress bar and show the config button:
    [self stopSpinAnimationOnView:self.prefsButton.customView];
    [self showSyncButton];
  }

  // Check for any change in error status and display new errors:
  NSError* error = _pull.lastError ? _pull.lastError : _push.lastError;
  if (error != _syncError) {
    _syncError = error;
    if (error) {
      NSLog(@"error: %@", error);
    }
  }
  //[self updateStatusView];
}


// -------------------------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate protocol methods
// -------------------------------------------------------------------------------------------------
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 58.0f;
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Lazy loading of our database (from delegate)
// -------------------------------------------------------------------------------------------------
- (CBLDatabase *)database
{
  if (_database == nil) {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = appDelegate.database;
  }
  return _database;
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Rotation animation
// -------------------------------------------------------------------------------------------------
- (void)runSpinAnimationOnView:(UIView *)view
                      duration:(CGFloat)duration
                     rotations:(CGFloat)rotations
                        repeat:(float)repeat;
{
  CABasicAnimation* rotationAnimation;
  rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
  rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
  rotationAnimation.duration = duration;
  rotationAnimation.cumulative = YES;
  rotationAnimation.repeatCount = repeat;

  [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopSpinAnimationOnView:(UIView *)view
{
  [view.layer removeAllAnimations];
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Lazy loading of our StatusViewController
// -------------------------------------------------------------------------------------------------
- (StatusViewController *)statusViewController
{
  if (_statusViewController == nil) {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _statusViewController = [sb instantiateViewControllerWithIdentifier:@"StatusViewController"];
    _statusViewController.view.frame = CGRectMake(0,
                                                  self.view.frame.size.height - 56,
                                                  self.view.frame.size.width,
                                                  144);
    _statusViewController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    _statusViewController.view.userInteractionEnabled = YES;
  }
  return _statusViewController;
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Updates the status
// -------------------------------------------------------------------------------------------------
- (void)updateStatusView
{
  NSArray *rows       = self.dataSource.rows;
  CGFloat sum         = 0.0f;
  CGFloat sumBirte    = 0.0f;
  CGFloat sumJens     = 0.0f;

  for (CBLQueryRow *row in rows) {
    NSNumber *price = row.document.properties[@"price"];
    sum += price.floatValue;

    if ([row.document.properties[@"user"]isEqualToString:@"Jens"]) {
      sumJens += price.floatValue;
    }

    if ([row.document.properties[@"user"]isEqualToString:@"Birte"]) {
      sumBirte += price.floatValue;
    }
  }

  self.statusViewController.sumValueLabel.text = [NSString stringWithFormat:@"%.2f", sum];
  self.statusViewController.us1TitleLabel.text = @"Birte";
  self.statusViewController.us1ValueLabel.text = [NSString stringWithFormat:@"%.2f", sumBirte];
  self.statusViewController.us2TitleLabel.text = @"Jens";
  self.statusViewController.us2ValueLabel.text = [NSString stringWithFormat:@"%.2f", sumJens];
  [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Lazy loading of PreferenceViewController
// -------------------------------------------------------------------------------------------------
- (PreferenceViewController *)prefsViewController
{
  if (_prefsViewController == nil) {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _prefsViewController = [sb instantiateViewControllerWithIdentifier:@"PreferenceViewController"];
  }
  return _prefsViewController;
}


// -------------------------------------------------------------------------------------------------
#pragma mark - Visual candy
// -------------------------------------------------------------------------------------------------
- (void)showSyncButton {
  if (!self.showingSyncButton) {
    self.showingSyncButton = YES;
    UIBarButtonItem* syncButton =
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"]
                       landscapeImagePhone:[UIImage imageNamed:@"gear"]
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(triggerOpenPrefs:)];
    self.navigationItem.leftBarButtonItem = syncButton;
  }
}


// -------------------------------------------------------------------------------------------------
- (void)showSyncStatus {
  if (self.showingSyncButton) {
    self.showingSyncButton = NO;
    if (!self.spinner) {
      self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    [self.spinner startAnimating];
    UIBarButtonItem* progressItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinner];
    progressItem.enabled = NO;
    self.navigationItem.leftBarButtonItem = progressItem;
  }
}

// -------------------------------------------------------------------------------------------------
#pragma mark - Open preferences
// -------------------------------------------------------------------------------------------------
- (IBAction)triggerOpenPrefs:(id)sender
{
  [self.navigationController pushViewController:self.prefsViewController animated:YES];
}

- (NSString *)makeTinyDate:(NSString *)largeDate {
  NSDateFormatter *longFormatter = [[NSDateFormatter alloc]init];
  [longFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
  NSDateFormatter *shrtFormatter = [[NSDateFormatter alloc]init];
  [shrtFormatter setDateFormat:@"dd.MM.yyyy"];

  NSDate *date = [longFormatter dateFromString:largeDate];
  return [shrtFormatter stringFromDate:date];
}
@end
