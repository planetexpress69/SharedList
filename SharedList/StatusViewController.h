//
//  StatusViewController.h
//  SharedList
//
//  Created by Martin Kautz on 18.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusViewController : UIViewController
// ---------------------------------------------------------------------------------------------------------------------
@property (nonatomic, weak) IBOutlet UILabel *sumTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *sumValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *us1TitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *us1ValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *us2TitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *us2ValueLabel;
@property (nonatomic, weak) IBOutlet UIImageView *tinyTriangle;
// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)handlePanGesture:(UIPanGestureRecognizer*)sender;
// ---------------------------------------------------------------------------------------------------------------------
@end
