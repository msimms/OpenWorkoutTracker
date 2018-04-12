// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "LayoutStyleViewController.h"
#import "ActivityPreferences.h"
#import "AppDelegate.h"

#define BUTTON_TITLE_HOME NSLocalizedString(@"Home", nil)

@interface LayoutStyleViewController ()

@end

@implementation LayoutStyleViewController

@synthesize homeButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.homeButton setTitle:BUTTON_TITLE_HOME];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

- (IBAction)onComplexActivityView:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
	if (prefs)
	{
		NSString* activityName = [appDelegate getCurrentActivityName];
		[prefs setViewType:activityName withViewType:ACTIVITY_VIEW_COMPLEX];
	}
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction)onMappedActivityView:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
	if (prefs)
	{
		NSString* activityName = [appDelegate getCurrentActivityName];
		[prefs setViewType:activityName withViewType:ACTIVITY_VIEW_MAPPED];
	}
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (IBAction)onSimpleActivityView:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	ActivityPreferences* prefs = [[ActivityPreferences alloc] init];
	if (prefs)
	{
		NSString* activityName = [appDelegate getCurrentActivityName];
		[prefs setViewType:activityName withViewType:ACTIVITY_VIEW_SIMPLE];
	}
	[self.navigationController popViewControllerAnimated:TRUE];
}

@end
