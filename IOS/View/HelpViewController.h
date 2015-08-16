// Created by Michael Simms on 9/6/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController <UIGestureRecognizerDelegate>
{
	IBOutlet UIImageView* helpImage;
	IBOutlet UITextView* helpText;
	NSString* activityName;
}

- (void)setActivityName:(NSString*)name;

@property (nonatomic, retain) IBOutlet UIImageView* helpImage;
@property (nonatomic, retain) IBOutlet UITextView* helpText;

@end
