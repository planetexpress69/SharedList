//
//  DetailViewController.m
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "DetailViewController.h"
#import "DataEntryCell.h"
#import "AppDelegate.h"

@interface DetailViewController ()
@property (nonatomic, assign, getter = isDirty) BOOL dirty;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@end

@implementation DetailViewController
// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.saveButton = [[UIBarButtonItem alloc]initWithTitle:@"Save"
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(save:)];
    
    self.navigationItem.rightBarButtonItem          = self.saveButton;
    self.navigationItem.rightBarButtonItem.enabled  = NO;

    self.itemTitleCell.dataField.delegate           = self;
    self.itemPriceCell.dataField.delegate           = self;
    self.itemDateCell.dataField.delegate            = self;
    self.itemTitleCell.selectionStyle               = UITableViewCellSelectionStyleNone;
    self.itemPriceCell.selectionStyle               = UITableViewCellSelectionStyleNone;
    self.itemDateCell.selectionStyle                = UITableViewCellSelectionStyleNone;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.database = nil;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.mode == DetailControllerModeAdd ? @"Add" : @"Edt";
    self.dirty = NO;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Persistence to Couch DB
// ---------------------------------------------------------------------------------------------------------------------
- (void)save
{
    if (self.record) { // --- edit existing ----------------------------------------------------------------------------

        if (!self.isDirty) {
            // record seems to be unchanged, so: bailing out!
            return;
        }

        if (self.itemTitleCell.dataField.text.length == 0 || self.itemPriceCell.dataField.text.length == 0) {
            // no title or no price, so: bailing out!
            return;
        }

        NSMutableDictionary *mutableProps = [self.record.properties mutableCopy];
        mutableProps[@"item"]   = self.itemTitleCell.dataField.text;
        mutableProps[@"price"]  = [NSNumber numberWithFloat:
                                  [self.itemPriceCell.dataField.text
                                   stringByReplacingOccurrencesOfString:@"," withString:@"."].floatValue];
        mutableProps[@"user"]   = [[NSUserDefaults standardUserDefaults]objectForKey:@"user"];
        mutableProps[@"date"]   = self.itemDateCell.dataField.text;

        NSError* error;
        if (![self.record putProperties:mutableProps error:&error]) {
            NSLog(@"Error! %@", error.localizedDescription);
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidChangeRecordNotification" object:nil];
        }
    }
    else { // --- add new ----------------------------------------------------------------------------------------------

        if (self.itemTitleCell.dataField.text.length == 0 || self.itemPriceCell.dataField.text.length == 0) {
            // no title or no price
            return;
        }

        NSDictionary *props = @{
                                @"item"         : self.itemTitleCell.dataField.text,
                                @"price"        : [NSNumber numberWithFloat:[self.itemPriceCell.dataField.text
                                                                      stringByReplacingOccurrencesOfString:@","
                                                                      withString:@"."].floatValue],
                                @"date"         : self.itemDateCell.dataField.text,
                                @"user"         : self.itemUserCell.textLabel.text,
                                @"check"        : @NO,
                                @"created_at"   : [CBLJSON JSONObjectWithDate: [NSDate date]]
                                };

        CBLDocument *doc = [self.database createDocument];

        NSError* error;
        if (![doc putProperties:props error:&error]) {
            NSLog(@"Error! %@", error.localizedDescription);
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidAddRecordNotification" object:nil];
        }
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource protocol methods
// ---------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

// ---------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 3 : 1;
}

// ---------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Refactor! This is all pretty experimental & spaghetti!

    if (indexPath.section == 0) {

        if (self.mode == DetailControllerModeAdd) {

            switch (indexPath.row) {
                case 0: {
                    self.itemTitleCell.dataField.text           = @"";
                    self.itemTitleCell.dataField.placeholder    = @"Blumenkohl";
                    return self.itemTitleCell;
                }
                    break;
                case 1: {
                    self.itemPriceCell.dataField.text           = @"";
                    self.itemPriceCell.dataField.placeholder    = @"1.95";
                    return self.itemPriceCell;
                }
                    break;
                default: {
                    NSDate *now = [NSDate date];
                    NSDateFormatter *formatter                  = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"dd.MM.yyyy"];
                    //[formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
                    NSString *stringFromDate                    = [formatter stringFromDate:now];
                    self.itemDateCell.dataField.text            = stringFromDate;
                    self.itemDateCell.dataField.placeholder     = @"06.07.2014";
                    return self.itemDateCell;
                }
                    break;
            }
        }

        else  /* if (self.mode == DetailControllerModeEdt) */ {

            NSDictionary *props = self.record.properties;

            switch (indexPath.row) {

                case 0: {
                    self.itemTitleCell.dataField.text           = props[@"item"];
                    self.itemTitleCell.dataField.placeholder    = @"Blumenkohl";
                    self.itemTitleCell.dataField.keyboardType   = UIKeyboardTypeDefault;
                    self.itemTitleCell.dataField.delegate       = self;
                    return self.itemTitleCell;
                }
                    break;

                case 1: {
                    self.itemPriceCell.dataField.text           = [NSString stringWithFormat:@"%.2f", ((NSNumber *)props[@"price"]).floatValue];
                    self.itemPriceCell.dataField.placeholder    = @"1.95";
                    self.itemPriceCell.dataField.keyboardType   = UIKeyboardTypeNumbersAndPunctuation;
                    self.itemPriceCell.dataField.delegate       = self;
                    return self.itemPriceCell;
                }
                    break;

                default: {
                    NSString *s = nil;
                    if (((NSString *)props[@"date"]).length == 0) {
                        NSDate *now                             = [NSDate date];
                        NSDateFormatter *formatter              = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"dd.MM.yyyy"];
                        //[formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
                        s                                       = [formatter stringFromDate:now];
                    } else {
                        s                                       = [NSString stringWithFormat:@"%@", props[@"date"]];
                    }
                    self.itemDateCell.dataField.text            = s;
                    self.itemDateCell.dataField.placeholder     = @"06.07.2014";
                    self.itemDateCell.dataField.keyboardType    = UIKeyboardTypeNumbersAndPunctuation;
                    self.itemDateCell.dataField.delegate        = self;
                    return self.itemDateCell;
                }
                    break;
            }
        }
    }
    else {
        self.itemUserCell.textLabel.text = [self defaultUser];
        return self.itemUserCell;
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate protocol methods
// ---------------------------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    self.dirty = YES;

    if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSString *sCurrentUser = cell.textLabel.text;
        if ([sCurrentUser isEqualToString:@"Birte"]) {
            [[NSUserDefaults standardUserDefaults]setObject:@"Jens" forKey:@"user"];
        }
        else {
            [[NSUserDefaults standardUserDefaults]setObject:@"Birte" forKey:@"user"];
        }

        [[NSUserDefaults standardUserDefaults]synchronize];
        [self.tableView reloadData];
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


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Get the default user from preferences
// ---------------------------------------------------------------------------------------------------------------------
- (NSString *)defaultUser
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"user"];
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Keyboard show/hide callbacks
// ---------------------------------------------------------------------------------------------------------------------
- (void)keyboardWillShow:(NSNotification *)notification;
{
    self.dirty = YES;

    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [self.tableView  contentInset];
    NSLog(@"show insets: %@", NSStringFromUIEdgeInsets(insets));
    NSLog(@"show table frame :%@", NSStringFromCGRect(self.tableView.frame));
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [self.tableView  contentInset];
    NSLog(@"hide insets: %@", NSStringFromUIEdgeInsets(insets));
    NSLog(@"show table frame :%@", NSStringFromCGRect(self.tableView.frame));

    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - UITextFieldDelegate protocol methods
// ---------------------------------------------------------------------------------------------------------------------
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.dirty = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - User triggered action
// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)save:(id)sender
{
    [self save];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
