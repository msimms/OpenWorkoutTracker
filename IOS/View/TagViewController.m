// Created by Michael Simms on 10/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "TagViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"

@interface TagViewController ()

@end

@implementation TagViewController

@synthesize toolbar;
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

	[self.tagButton setTitle:STR_NEW_TAG];

	self->selectedSection = 0;
	self->selectedRow = 0;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->tags = [appDelegate getTagsForActivity:self->activityId];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.tagTableView setEditing:YES animated: YES];
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
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
	[self->tags insertObject:STR_NEW_TAG atIndex:0];

	NSArray* newData = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], nil];
	[self.tagTableView insertRowsAtIndexPaths:newData withRowAnimation:UITableViewRowAnimationNone];
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
		return [self->tags count];
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case 0:
			if (row < [self->tags count])
			{
				UITextField* txtField = [[UITextField alloc] initWithFrame:CGRectMake(40, 12, 320, 39)];
				if (txtField)
				{
					txtField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
					txtField.autoresizesSubviews = YES;
					txtField.keyboardType = UIKeyboardTypeDefault;
					txtField.returnKeyType = UIReturnKeyDone;
					txtField.delegate = self;

					[txtField setPlaceholder: [self->tags objectAtIndex:row]];
					[cell addSubview:txtField];
				}
			}
			break;
		default:
			break;
	}

	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	self->selectedSection = [indexPath section];
	self->selectedRow = [indexPath row];
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
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			[appDelegate serverDeleteTag:tag forActivity:self->activityId];
		}
	}
}

- (BOOL)tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath
{
	return NO;
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField
{
}

- (void)textFieldDidEndEditing:(UITextField*)textField
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* tag = [textField text];

	if ([appDelegate createTag:tag forActivityId:self->activityId])
	{
		[appDelegate serverCreateTag:tag forActivity:self->activityId];
	}
}

@end
