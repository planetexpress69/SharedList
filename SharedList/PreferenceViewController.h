//
//  PreferenceViewController.h
//  SharedList
//
//  Created by Martin Kautz on 23.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBLDatabase;

@interface PreferenceViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate>
// ---------------------------------------------------------------------------------------------------------------------
@property (nonatomic, weak)     IBOutlet    UITextField     *theEndpointTextField;
@property (strong, nonatomic)               CBLDatabase     *database;
// ---------------------------------------------------------------------------------------------------------------------
@end
