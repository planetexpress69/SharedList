//
//  AppDelegate.h
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CBLDatabase;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>
// ---------------------------------------------------------------------------------------------------------------------
@property (strong, nonatomic) UIWindow      *window;
@property (strong, nonatomic) CBLDatabase   *database;
// ---------------------------------------------------------------------------------------------------------------------
@end

