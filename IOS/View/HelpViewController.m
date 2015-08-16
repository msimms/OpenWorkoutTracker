// Created by Michael Simms on 9/6/12.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "HelpViewController.h"
#import "Segues.h"
#import "ActivityName.h"

#define HELP_PULLUP          NSLocalizedString(@"This exercise should be performed with the iPhone positioned on the bicep as shown.", nil)
#define HELP_CYCLING         NSLocalizedString(@"You can mount the iPhone on the bicycle's handlebars, though you you should pay attention to the road and obey all applicable laws.", nil)
#define HELP_PUSHUP          NSLocalizedString(@"This exercise should be performed with the iPhone positioned on the bicep as shown.", nil)
#define HELP_RUNNING         NSLocalizedString(@"This exercise should be performed with the iPhone positioned on the bicep as shown.", nil)
#define HELP_SQUAT           NSLocalizedString(@"This exercise should be performed with the iPhone positioned on the bicep as shown.", nil)
#define HELP_STATIONARY_BIKE NSLocalizedString(@"Stationary cycling requires the use of a Bluetooth wheel speed sensor.", nil)
#define HELP_TREADMILL       NSLocalizedString(@"Treadmill running requires the use of a Bluetooth foot pod.", nil)

@interface HelpViewController ()

@end

@implementation HelpViewController

@synthesize helpImage;
@synthesize helpText;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];

	UILongPressGestureRecognizer* gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
	if (gesture)
	{
		gesture.minimumPressDuration = 1.0;
		[self->helpImage addGestureRecognizer:gesture];
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];

	NSString* imgFileName;
	NSString* imgType;
	NSString* text;

	if ([self->activityName isEqualToString:@ACTIVITY_NAME_CHINUP] ||
		[self->activityName isEqualToString:@ACTIVITY_NAME_PULLUP])
	{
		imgFileName = @"iPhoneOnArm";
		imgType = @"jpg";
		text = HELP_PULLUP;
	}
	else if ([self->activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			 [self->activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING])
	{
		imgFileName = @"BikeMount";
		imgType = @"jpg";
		text = HELP_CYCLING;
	}
	else if ([self->activityName isEqualToString:@ACTIVITY_NAME_PUSHUP])
	{
		imgFileName = @"PushUp";
		imgType = @"jpg";
		text = HELP_PUSHUP;
	}
	else if ([self->activityName isEqualToString:@ACTIVITY_NAME_RUNNING])
	{
		imgFileName = @"iPhoneOnArm";
		imgType = @"jpg";
		text = HELP_RUNNING;
	}
	else if ([self->activityName isEqualToString:@ACTIVITY_NAME_SQUAT])
	{
		imgFileName = @"iPhoneOnArm";
		imgType = @"jpg";
		text = HELP_SQUAT;
	}
	else if ([self->activityName isEqualToString:@ACTIVITY_NAME_STATIONARY_BIKE])
	{
		imgFileName = @"WheelSpeedSensor";
		imgType = @"png";
		text = HELP_STATIONARY_BIKE;
	}
	else if ([self->activityName isEqualToString:@ACTIVITY_NAME_TREADMILL])
	{
		imgFileName = @"FootPod";
		imgType = @"png";
		text = HELP_TREADMILL;
	}
	
	if (imgFileName)
	{
		NSString* imgPath = [[NSBundle mainBundle] pathForResource:imgFileName ofType:imgType];
		[self->helpImage setImage:[UIImage imageWithContentsOfFile:imgPath]];
	}
	
	if (text)
	{
		[self->helpText setText:text];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark accessor methods

- (void)setActivityName:(NSString*)name
{
	self->activityName = name;
}

#pragma mark UIGestureRecognizer methods

- (void)handleTapGesture:(UIGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateBegan)
	{
		[self.navigationController popViewControllerAnimated:TRUE];
	}
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
	return YES;
}

@end
