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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.theTableView.delegate = self;
    self.theTableView.dataSource = self;

    //[self.theTableView registerClass:[DataEntryCell class] forCellReuseIdentifier:@"DataEntryCell"];

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.database = appDelegate.database;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.mode == DetailControllerModeAdd ? @"Add" : @"Edt";
    self.navigationController.toolbarHidden = YES;

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"Going to leave...");
    if (self.record) {
        NSMutableDictionary *mutableProps = [self.record.properties mutableCopy];
        DataEntryCell *cell0 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        mutableProps[@"item"] = cell0.dataField.text;

        DataEntryCell *cell1 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        mutableProps[@"price"] = [f numberFromString:[cell1.dataField.text stringByReplacingOccurrencesOfString:@"." withString:@","]];

        NSError* error;
        if (![self.record putProperties:mutableProps error: &error]) {
            NSLog(@"Error! %@", error.localizedDescription);
        }
    } else {

        DataEntryCell *cell0 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        DataEntryCell *cell1 = (DataEntryCell *)[self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];

        NSDictionary *props = @{
                                @"item" : cell0.dataField.text,
                                @"price" : [f numberFromString:[cell1.dataField.text stringByReplacingOccurrencesOfString:@"." withString:@","]],
                                @"date" : @"",
                                @"user" : @"Jens",
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Beep!");
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
            }
                break;
            case 1: {
                cell.dataField.text = [NSString stringWithFormat:@"%.2f", ((NSNumber *)props[@"price"]).floatValue];
                cell.dataField.placeholder = @"1.95";
                cell.dataField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;

            }
                break;
            case 2: {
                cell.dataField.text = [NSString stringWithFormat:@"%@", props[@"date"]];
                cell.dataField.placeholder = @"06.07.2014";
                cell.dataField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;

            }
                break;

            default:
                cell.dataField.text = @"";
                break;
        }

    }



    NSAssert(cell != nil, @"Boom! Could not build cell!");

    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58.0f;
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
