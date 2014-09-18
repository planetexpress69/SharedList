//
//  DetailViewController.h
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

typedef NS_ENUM(NSInteger, DetailControllerMode) {
    DetailControllerModeEdt,
    DetailControllerModeAdd
};

@interface DetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView *theTableView;
@property (nonatomic, assign) DetailControllerMode mode;
@property (nonatomic, strong) CBLDocument *record;
@property (nonatomic, strong) CBLDatabase *database;


@end
