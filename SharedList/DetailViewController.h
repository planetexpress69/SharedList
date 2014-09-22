//
//  DetailViewController.h
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import "DataEntryCell.h"

typedef NS_ENUM(NSInteger, DetailControllerMode) {
    DetailControllerModeEdt,
    DetailControllerModeAdd
};

@interface DetailViewController : UITableViewController <UITextFieldDelegate>
// ---------------------------------------------------------------------------------------------------------------------
@property (nonatomic, assign)               DetailControllerMode    mode;
@property (nonatomic, strong)               CBLDocument             *record;
@property (nonatomic, strong)               CBLDatabase             *database;
@property (nonatomic, strong)               NSMutableDictionary     *dataStorage;
@property (nonatomic, weak)     IBOutlet    DataEntryCell           *itemTitleCell;
@property (nonatomic, weak)     IBOutlet    DataEntryCell           *itemPriceCell;
@property (nonatomic, weak)     IBOutlet    DataEntryCell           *itemDateCell;
@property (nonatomic, weak)     IBOutlet    UITableViewCell         *itemUserCell;
// ---------------------------------------------------------------------------------------------------------------------
@end
