// Created by Michael Simms on 11/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

#import "MapViewController.h"

@interface LiveMapViewController : MapViewController
{
	IBOutlet UINavigationItem* navItem;
	IBOutlet UIToolbar* toolbar;
	IBOutlet UISwipeGestureRecognizer* swipe;
	IBOutlet UIBarButtonItem* autoScaleButton;
}

- (void)drawExistingRoute;
- (void)locationUpdated:(NSNotification*)notification;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;
@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UISwipeGestureRecognizer* swipe;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* autoScaleButton;

@end
