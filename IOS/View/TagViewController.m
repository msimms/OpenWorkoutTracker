// Created by Michael Simms on 10/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "TagViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"

@implementation TagViewController

@synthesize tagTableView;
@synthesize tagButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityId = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = STR_TAGS;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->tags = [appDelegate getTagsForActivity:self->activityId];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

#pragma mark TagViewController methods

- (void)setActivityId:(NSString*)activityIdent
{
	self->activityId = activityIdent;
}

#pragma mark button handlers

- (IBAction)onNewTag:(id)sender
{
	[self getNewTagName];
}

#pragma mark called when editing a tag name

- (void)getNewTagName
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_TAG
																			 message:STR_NEW_TAG
																	  preferredStyle:UIAlertControllerStyleAlert];

	// Default text.
	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		UITextField* field = alertController.textFields.firstObject;

		if (![appDelegate createTag:[field text] forActivityId:self->activityId])
		{
			[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
		}
		self->tags = [appDelegate getTagsForActivity:self->activityId];
		[self.tagTableView reloadData];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self->tags)
	{
		return [self->tags count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	NSString* cellIdentifier = [NSString stringWithFormat:@"S%1ldR%1ld", (long)section, (long)row]; 
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];

	switch (section)
	{
	case 0:
		if (row < [self->tags count])
		{
			[content setText: [self->tags objectAtIndex:row]];
		}
		break;
	default:
		break;
	}

	[cell setContentConfiguration:content];
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		NSString* tag = [self->tags objectAtIndex:indexPath.row];

		if ([appDelegate deleteTag:tag forActivityId:self->activityId])
		{
			[self->tags removeObjectAtIndex:indexPath.row];
			[self.tagTableView reloadData];
		}
	}
}

- (BOOL)tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath
{
	return NO;
}

@end
