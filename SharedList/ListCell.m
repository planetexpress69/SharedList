//
//  ListCell.m
//  SharedList
//
//  Created by Martin Kautz on 16.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "ListCell.h"

@implementation ListCell

- (void)awakeFromNib
{
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.0 alpha:.8];
        self.dateLabel.textColor = [UIColor whiteColor];
        self.itemNameLabel.textColor = [UIColor whiteColor];
        self.spenderLabel.textColor = [UIColor whiteColor];
        self.valueLabel.textColor = [UIColor whiteColor];

    } else {
        self.backgroundColor = [UIColor whiteColor];
        self.dateLabel.textColor = [UIColor blackColor];
        self.itemNameLabel.textColor = [UIColor blackColor];
        self.spenderLabel.textColor = [UIColor blackColor];
        self.valueLabel.textColor = [UIColor blackColor];
    }
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];

    if (highlighted) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.0 alpha:.8];
        self.dateLabel.textColor = [UIColor whiteColor];
        self.itemNameLabel.textColor = [UIColor whiteColor];
        self.spenderLabel.textColor = [UIColor whiteColor];
        self.valueLabel.textColor = [UIColor whiteColor];
    } else {
        self.backgroundColor = [UIColor whiteColor];
        self.dateLabel.textColor = [UIColor blackColor];
        self.itemNameLabel.textColor = [UIColor blackColor];
        self.spenderLabel.textColor = [UIColor blackColor];
        self.valueLabel.textColor = [UIColor blackColor];
    }
}

@end
