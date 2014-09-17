//
//  ListCell.h
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListCell : UITableViewCell
// ---------------------------------------------------------------------------------------------------------------------
@property (nonatomic, weak) IBOutlet UILabel *itemNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *spenderLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
// ---------------------------------------------------------------------------------------------------------------------
@end
