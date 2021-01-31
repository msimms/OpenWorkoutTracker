// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import "PacePlansViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "PacePlanEditViewController.h"
#import "Segues.h"

#define TITLE                     NSLocalizedString(@"Pace Plans", nil)

#define ADD_PACE_PLAN             NSLocalizedString(@"Add Pace Plan", nil)
#define ALERT_TITLE_NEW_PACE_PLAN NSLocalizedString(@"New Pace Plan", nil)
#define ALERT_MSG_NEW_PACE_PLAN   NSLocalizedString(@"Name this pace plan", nil)

@interface PacePlansViewController ()

@end

@implementation PacePlansViewController

@synthesize toolbar;
@synthesize planTableView;
@synthesize addPlanButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[self.addPlanButton setTitle:ADD_PACE_PLAN];
	[self updatePacePlanNames];

	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self updatePacePlanNames];
	[self.planTableView reloadData];

	[super viewDidAppear:animated];
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

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	NSString* segueId = [segue identifier];

	if ([segueId isEqualToString:@SEGUE_TO_PACE_PLAN_EDIT_VIEW])
	{
		PacePlanEditViewController* editVC = (PacePlanEditViewController*)[segue destinationViewController];
		if (editVC)
		{
			[editVC setPlanId:self->selectedPlanId];
		}
	}
}

#pragma mark miscellaneous methods

- (void)updatePacePlanNames
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->planNamesAndIds = [appDelegate getPacePlanNamesAndIds];
}

#pragma mark button handlers

- (IBAction)onAddPacePlan:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ALERT_MSG_NEW_PACE_PLAN
																	  preferredStyle:UIAlertControllerStyleAlert];

	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
	}];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		NSString* pacePlanName = [alertController.textFields.firstObject text];
		NSString* pacePlanId = [[NSUUID UUID] UUIDString];

		if ([appDelegate createNewPacePlan:pacePlanName withPlanId:pacePlanId])
		{
			self->selectedPlanId = pacePlanId;

			[self updatePacePlanNames];
			[self performSegueWithIdentifier:@SEGUE_TO_PACE_PLAN_EDIT_VIEW sender:self];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
		}
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return TITLE;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return [self->planNamesAndIds count];
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}

	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case 0:
			{
				NSDictionary* nameAndId = [self->planNamesAndIds objectAtIndex:row];
				cell.textLabel.text = nameAndId[@"name"];
			}
			break;
		default:
			break;
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];	
	if (section == 0)
	{
		NSDictionary* nameAndId = [self->planNamesAndIds objectAtIndex:[indexPath row]];
		self->selectedPlanId = nameAndId[@"id"];
		
		[self performSegueWithIdentifier:@SEGUE_TO_PACE_PLAN_EDIT_VIEW sender:self];
	}
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
		NSDictionary* nameAndId = [self->planNamesAndIds objectAtIndex:[indexPath row]];

		if ([appDelegate deletePacePlanWithId:nameAndId[@"id"]])
		{
			[self->planNamesAndIds removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
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
}

@end
