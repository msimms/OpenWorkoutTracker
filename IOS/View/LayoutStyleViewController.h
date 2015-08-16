// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface LayoutStyleViewController : UIViewController
{
	IBOutlet UIBarButtonItem* homeButton;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem* homeButton;

- (IBAction)onHome:(id)sender;

- (IBAction)onComplexActivityView:(id)sender;
- (IBAction)onMappedActivityView:(id)sender;
- (IBAction)onSimpleActivityView:(id)sender;

@end
