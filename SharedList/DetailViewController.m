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

@end

@implementation DetailViewController
// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad {

    [super viewDidLoad];

    // wire the table
    self.theTableView.delegate = self;
    self.theTableView.dataSource = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.database = nil;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.mode == DetailControllerModeAdd ? @"Add" : @"Edt";
    self.navigationController.toolbarHidden = YES;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];


    // TODO: Refactor! This is all pretty experimental & spaghetti!

    if (self.record) { // edit existing



        NSMutableDictionary *mutableProps = [self.record.properties mutableCopy];

        DataEntryCell *cell0 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:
                                                 [NSIndexPath indexPathForRow:0 inSection:0]];
        mutableProps[@"item"] = cell0.dataField.text;

        DataEntryCell *cell1 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:
                                                 [NSIndexPath indexPathForRow:1 inSection:0]];

        if (cell0.dataField.text.length == 0 || cell1.dataField.text.length == 0) {
            return;
        }

        mutableProps[@"price"] = [NSNumber numberWithFloat:
                                  [cell1.dataField.text stringByReplacingOccurrencesOfString:@","
                                                                                  withString:@"."].floatValue];

        mutableProps[@"user"] = [[NSUserDefaults standardUserDefaults]objectForKey:@"user"];

        NSError* error;
        if (![self.record putProperties:mutableProps error: &error]) {
            NSLog(@"Error! %@", error.localizedDescription);
        }
    }
    else {    // add new

        DataEntryCell *cell0 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:
                                                 [NSIndexPath indexPathForRow:0 inSection:0]];
        DataEntryCell *cell1 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:
                                                 [NSIndexPath indexPathForRow:1 inSection:0]];

        UITableViewCell *userCell = [self.theTableView cellForRowAtIndexPath:
                                     [NSIndexPath indexPathForRow:0 inSection:1]];

        if (cell0.dataField.text.length == 0 || cell1.dataField.text.length == 0) {
            return;
        }

        NSDictionary *props = @{
                                @"item" : cell0.dataField.text,
                                @"price" : [NSNumber numberWithFloat:[cell1.dataField.text
                                                                      stringByReplacingOccurrencesOfString:@","
                                                                      withString:@"."].floatValue],
                                @"date" : @"",
                                @"user" : userCell.textLabel.text,
                                @"check":      @NO,
                                @"created_at": [CBLJSON JSONObjectWithDate: [NSDate date]]
                                };

        CBLDocument *doc = [self.database createDocument];

        NSError* error;
        if (![doc putProperties:props error:&error]) {
            NSLog(@"Error! %@", error.localizedDescription);
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

    static NSString *CellIdentifier = @"DataEntryCell";
    DataEntryCell *cell = (DataEntryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DataEntryCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.mode == DetailControllerModeAdd) {

        switch (indexPath.row) {
            case 0: {
                cell.dataField.text = @"";
                cell.dataField.placeholder = @"Blumenkohl";
            }
                break;
            case 1: {
                cell.dataField.text = @"";
                cell.dataField.placeholder = @"1.95";
            }
                break;
            case 2: {
                cell.dataField.text = @"";
                cell.dataField.placeholder = @"06.07.2014";
            }
                break;


            default:
                cell.dataField.text = @"";
                break;
        }


    }
    else if (self.mode == DetailControllerModeEdt) {


        NSDictionary *props = self.record.properties;

        switch (indexPath.row) {
            case 0: {
                cell.dataField.text = props[@"item"];
                cell.dataField.placeholder = @"Blumenkohl";
                cell.dataField.keyboardType = UIKeyboardTypeDefault;
                cell.dataField.delegate = self;
            }
                break;
            case 1: {
                cell.dataField.text = [NSString stringWithFormat:@"%.2f", ((NSNumber *)props[@"price"]).floatValue];
                cell.dataField.placeholder = @"1.95";
                cell.dataField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                cell.dataField.delegate = self;


            }
                break;
            case 2: {
                cell.dataField.text = [NSString stringWithFormat:@"%@", props[@"date"]];
                cell.dataField.placeholder = @"06.07.2014";
                cell.dataField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                cell.dataField.delegate = self;
            }
                break;

            default:
                cell.dataField.text = @"";
                break;
        }
    }
    return cell;
    }
    else {
        static NSString *CellIdentifier = @"UITableViewCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        cell.textLabel.text = [self defaultUser];
        return cell;

    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate protocol methods
// ---------------------------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:indexPath];
        NSString *sCurrentUser = cell.textLabel.text;

        if ([sCurrentUser isEqualToString:@"Birte"]) {
            [[NSUserDefaults standardUserDefaults]setObject:@"Jens" forKey:@"user"];

        }
        else {
            [[NSUserDefaults standardUserDefaults]setObject:@"Birte" forKey:@"user"];
        }

        [[NSUserDefaults standardUserDefaults]synchronize];

        [self.theTableView reloadData];

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

- (NSString *)defaultUser
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"user"];
}

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;

    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [self.theTableView contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self.theTableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [self.theTableView contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self.theTableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

@end
