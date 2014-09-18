//
//  StatusViewController.m
//  SharedList
//
//  Created by Martin Kautz on 18.09.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "StatusViewController.h"

@interface StatusViewController ()
@end

@implementation StatusViewController
// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handlePanGesture:)];

    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:panGesture];
    self.view.backgroundColor = [UIColor colorWithWhite:.8 alpha:1.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Pan gesture recognizer's callback
// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];

    CGFloat thisHeight          = self.view.frame.size.height;
    CGFloat superViewsHeight    = self.view.superview.frame.size.height;

    CGFloat yMin                = superViewsHeight - (thisHeight / 2);
    CGFloat yMax                = yMin + 88;

    // Figure out where the user is trying to drag the view.
    CGPoint newCenter = CGPointMake(self.view.bounds.size.width / 2,
                                    recognizer.view.center.y + translation.y);

    // See if the new position is in bounds.
    if ((newCenter.y >= yMin && newCenter.y <= yMax)) {
        recognizer.view.center = newCenter;
        [recognizer setTranslation:CGPointZero inView:self.view];
    }

    if (recognizer.state == UIGestureRecognizerStateCancelled ||
        recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateFailed) {
        [self snapToDefault];
    }
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Snap the view's position to collapsed or expanded - 1st attempt
// ---------------------------------------------------------------------------------------------------------------------
- (void)snapToDefault
{
    CGFloat thisHeight          = self.view.frame.size.height;
    CGFloat superViewsHeight    = self.view.superview.frame.size.height;
    CGFloat yMin                = superViewsHeight - (thisHeight / 2);
    CGFloat yMax                = yMin + thisHeight / 3 * 2;
    CGPoint currentCenter       = self.view.center;
    CGFloat currentY            = currentCenter.y;

    CGPoint neueMitte;

    CGRect posSumTitleLabel     = self.sumTitleLabel.frame;
    CGRect posSumValueLabel     = self.sumValueLabel.frame;

    CGRect posUs1TitleLabel     = self.us1TitleLabel.frame;
    CGRect posUs1ValueLabel     = self.us1ValueLabel.frame;

    CGRect posUs2TitleLabel     = self.us2TitleLabel.frame;
    CGRect posUs2ValueLabel     = self.us2ValueLabel.frame;

    if (yMax - currentY < thisHeight / 3) {
        // snap to collapsed view (down)
        neueMitte = CGPointMake(self.view.frame.size.width / 2, yMax);
        posSumTitleLabel.origin.y = posSumValueLabel.origin.y = 13;
        posUs1TitleLabel.origin.y = posUs1ValueLabel.origin.y = 55;
        posUs2TitleLabel.origin.y = posUs2ValueLabel.origin.y = 98;
    }
    else {
        // snap to expanded view (up)
        neueMitte = CGPointMake(self.view.frame.size.width / 2, yMin);
        posSumTitleLabel.origin.y = posSumValueLabel.origin.y = 98;
        posUs1TitleLabel.origin.y = posUs1ValueLabel.origin.y = 13;
        posUs2TitleLabel.origin.y = posUs2ValueLabel.origin.y = 55;
    }

    [UIView animateWithDuration:.1 animations:^{
        self.view.center = neueMitte;
    }
    completion:^(BOOL finished){
        [UIView animateWithDuration:0.1 animations:^{
            self.sumTitleLabel.frame = posSumTitleLabel;
            self.sumValueLabel.frame = posSumValueLabel;

            self.us1TitleLabel.frame = posUs1TitleLabel;
            self.us1ValueLabel.frame = posUs1ValueLabel;

            self.us2TitleLabel.frame = posUs2TitleLabel;
            self.us2ValueLabel.frame = posUs2ValueLabel;
        }
        completion:^(BOOL finished){
        }];
    }];
}


@end
