// Created by Michael Simms on 8/29/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "HistoryViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "Segues.h"
#import "StaticSummaryViewController.h"
#import "StringUtils.h"

#define TITLE                       NSLocalizedString(@"History", nil)

#define ACTION_SHEET_TITLE_ACTIVITY NSLocalizedString(@"Export", nil)
#define ACTION_SHEET_TITLE_EXPORT   NSLocalizedString(@"Export using", nil)
#define ACTION_SHEET_TITLE_ERROR    NSLocalizedString(@"Error", nil)
#define ACTION_SHEET_BUTTON_CANCEL  NSLocalizedString(@"Cancel", nil)
#define ACTION_SHEET_BUTTON_OK      NSLocalizedString(@"Ok", nil)

#define BUTTON_TITLE_EXPORT         NSLocalizedString(@"Export Summary", nil)

#define MSG_NO_WORKOUTS             NSLocalizedString(@"You have not done any workouts. Get moving!", nil)

#define EMAIL_TITLE                 NSLocalizedString(@"Workout Summary Data", nil)
#define EMAIL_CONTENTS              NSLocalizedString(@"The data file is attached.", nil)

@interface HistoryViewController ()

@end

@implementation HistoryViewController

@synthesize navItem;
@synthesize toolbar;

@synthesize searchBar;
@synthesize historyTableView;
@synthesize spinner;

@synthesize exportButton;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
	[self.searchBar setTintColor:[UIColor blackColor]];
	
	[self.exportButton setTitle:BUTTON_TITLE_EXPORT];

	[self.spinner stopAnimating];

	self->selectedActivityIndex = nil;
	self->searching = false;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
	[self.searchBar setTintColor:[UIColor blackColor]];

	[self.spinner stopAnimating];

	InitializeHistoricalActivityList();
	InitializeBikeProfileList();

	[self buildDictionary];
	[self.historyTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
			(interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
			(interfaceOrientation == UIInterfaceOrientationLandscapeRight));
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
	if ([[segue identifier] isEqualToString:@SEGUE_TO_ACTIVITY_SUMMARY])
	{
		StaticSummaryViewController* summaryVC = (StaticSummaryViewController*)[segue destinationViewController];
		if (summaryVC)
		{
			NSInteger activityIndex = [self->selectedActivityIndex integerValue];
			[summaryVC setActivityIndex:activityIndex];
		}
	}
}

#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark spinner control methods

- (void)threadStartAnimating:(id)data
{
	@synchronized(self.spinner)
	{
		self.spinner.hidden = FALSE;
		[self.spinner startAnimating];
	}
}

#pragma mark random methods

- (void)buildDictionary
{
	self->historyDictionary = nil;
	self->sortedKeys = nil;

	size_t numHistoricalActivities = GetNumHistoricalActivities();
	if (numHistoricalActivities > 0)
	{
		self->historyDictionary = [[NSMutableDictionary alloc] init];
		if (self->historyDictionary)
		{
			for (size_t i = 0; i < numHistoricalActivities; ++i)
			{
				time_t startTime = 0;
				time_t endTime = 0;
				GetHistoricalActivityStartAndEndTime(i, &startTime, &endTime);

				struct tm* theTime = localtime(&startTime);
				if (theTime)
				{
					NSString* key = [[NSString alloc] initWithFormat:@"%04u-%02u", theTime->tm_year + 1900, theTime->tm_mon + 1];
					if (key)
					{
						NSMutableArray* monthlyActivities = [self->historyDictionary objectForKey:key];
						if (monthlyActivities == nil)
						{
							monthlyActivities = [[NSMutableArray alloc] init];
						}
						if (monthlyActivities)
						{
							[monthlyActivities insertObject:[NSNumber numberWithLongLong:i] atIndex:0];
							[self->historyDictionary setObject:monthlyActivities forKey:key];
						}
					}
				}
			}

			self->sortedKeys = [[self->historyDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
			self->sortedKeys = [[self->sortedKeys reverseObjectEnumerator] allObjects];
		}
	}
	else
	{
		if (!self->searching)
		{
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ACTION_SHEET_TITLE_ERROR
															message:MSG_NO_WORKOUTS
														   delegate:self
												  cancelButtonTitle:ACTION_SHEET_BUTTON_OK
												  otherButtonTitles:nil];
			if (alert)
			{
				[alert show];
			}
		}
	}
}

- (NSNumber*)getActivityIndex:(NSIndexPath*)indexPath
{
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	NSString* month = [self->sortedKeys objectAtIndex:section];
	return [[self->historyDictionary objectForKey:month] objectAtIndex:row];
}

#pragma mark called when the user selects a row

- (void)handleSelectedActivity:(NSIndexPath*)indexPath
{
	self->selectedActivityIndex = [self getActivityIndex:indexPath];

	[NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];

	[self performSegueWithIdentifier:@SEGUE_TO_ACTIVITY_SUMMARY sender:self];

	@synchronized(self.spinner)
	{
		[self.spinner stopAnimating];
	}
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	if (self->sortedKeys)
	{
		return [self->sortedKeys count];
	}
	return 0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self->sortedKeys)
	{
		return [self->sortedKeys objectAtIndex:section];
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self->sortedKeys && self->historyDictionary)
	{
		NSString* secName = [self->sortedKeys objectAtIndex:section];
		if (secName)
		{
			return [[self->historyDictionary objectForKey:secName] count];
		}
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
	}

	cell.selectionStyle = UITableViewCellSelectionStyleGray;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	size_t activityIndex = [[self getActivityIndex:indexPath] intValue];
	uint64_t activityId = ConvertActivityIndexToActivityId(activityIndex);
	uint64_t bikeId = 0;
	NSString* allTagsStr = @"";
	
	GetActivityBikeProfile(activityId, &bikeId);
	if (bikeId > 0)
	{
		char* bikeName = NULL;
		double bikeWeight = (double)0.0;
		double bikeWheel = (double)0.0;

		GetBikeProfileById(bikeId, &bikeName, &bikeWeight, &bikeWheel);
		if (bikeName)
		{
			allTagsStr = [allTagsStr stringByAppendingFormat:@"%s", bikeName];
			free((void*)bikeName);
		}
	}

	NSMutableArray* tags = [appDelegate getTagsForActivity:activityId];
	for (NSString* tag in tags)
	{
		if ([allTagsStr length] > 0)
			allTagsStr = [allTagsStr stringByAppendingString:@", "];
		allTagsStr = [allTagsStr stringByAppendingString:tag];
	}

	time_t startTime = 0;
	time_t endTime = 0;
	GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime);
	NSString* startTimeStr = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];

	if ([allTagsStr length] > 0)
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", startTimeStr, allTagsStr];
	else
		cell.detailTextLabel.text = startTimeStr;
	cell.detailTextLabel.numberOfLines = 0;
	cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

	cell.textLabel.text = NSLocalizedString([appDelegate getHistorialActivityName: activityIndex], nil);

	return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedActivity:indexPath];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedActivity:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSNumber* activityIndex = [self getActivityIndex:indexPath];
		uint64_t activityId = ConvertActivityIndexToActivityId([activityIndex intValue]);

		DeleteActivity(activityId);
		InitializeHistoricalActivityList();

		[self buildDictionary];
		[self.historyTableView reloadData];
	}
}

#pragma mark action sheet methods

- (BOOL)showActivityList
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* activityNames = [appDelegate getActivityTypeNames];
	if ([activityNames count] > 0)
	{
		UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_ACTIVITY
																delegate:self
													   cancelButtonTitle:nil
												  destructiveButtonTitle:nil
													   otherButtonTitles:nil];
		if (popupQuery)
		{
			popupQuery.cancelButtonIndex = [activityNames count];
			popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;

			for (NSString* name in activityNames)
			{
				[popupQuery addButtonWithTitle:name];
			}

			[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_CANCEL];
			[popupQuery showInView:self.view];

			return TRUE;
		}
	}
	return FALSE;
}

- (BOOL)showFileExportSheet
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* fileSites = [appDelegate getEnabledFileExportServices];
	if ([fileSites count] > 0)
	{
		UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_EXPORT
																delegate:self
													   cancelButtonTitle:nil
												  destructiveButtonTitle:nil
													   otherButtonTitles:nil];
		if (popupQuery)
		{
			popupQuery.cancelButtonIndex = [fileSites count];
			popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
			
			for (NSString* fileSite in fileSites)
			{
				[popupQuery addButtonWithTitle:fileSite];
			}

			[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_CANCEL];
			[popupQuery showInView:self.view];

			return TRUE;
		}
	}
	return FALSE;
}

#pragma mark export methods

- (void)exportSummary
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	self->exportedFileName = [appDelegate exportActivitySummary:self->selectedExportActivity];
	if (self->exportedFileName)
	{
		[self displayEmailComposerSheet];
	}
}

#pragma mark UISearchBar methods

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
	self->searching = true;

	if ([searchText length] == 0)
		InitializeHistoricalActivityList();
	else
		SearchForTags([searchText UTF8String]);

	[self buildDictionary];
	[self.historyTableView reloadData];

	self->searching = false;
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
}

- (void)searchBarTextDidEndEditing:(UISearchBar*)searchBar
{
}

#pragma mark button handlers

- (IBAction)onExportSummary:(id)sender
{
	[self showActivityList];
}

#pragma mark mail composition methods

- (void)displayEmailComposerSheet
{
	NSString* subjectStr = EMAIL_TITLE;
	NSString* bodyStr = EMAIL_CONTENTS;

	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
		mailController.navigationBar.barStyle = UIBarStyleBlack;
		[mailController setEditing:TRUE];
		
		[mailController setSubject:subjectStr];
		[mailController setMessageBody:bodyStr isHTML:YES];
		[mailController setMailComposeDelegate:self];
		
		[self.parentViewController resignFirstResponder];
		[self becomeFirstResponder];
		
		if (self->exportedFileName)
		{
			NSString* justTheFileName = [[[NSFileManager defaultManager] displayNameAtPath:self->exportedFileName] lastPathComponent];
			NSData* myData = [NSData dataWithContentsOfFile:self->exportedFileName];
			[mailController addAttachmentData:myData mimeType:@"text/xml" fileName:justTheFileName];
		}
		
		[self presentViewController:mailController animated:YES completion:nil];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
			break;
		default:
			break;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate deleteFile:self->exportedFileName];

	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [actionSheet cancelButtonIndex])
	{
		return;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSString* title = [actionSheet title];

	if ([title isEqualToString:ACTION_SHEET_TITLE_ACTIVITY])
	{
		self->selectedExportActivity = [actionSheet buttonTitleAtIndex:buttonIndex];

		NSMutableArray* exportServices = [appDelegate getEnabledFileExportServices];
		if ([exportServices count] == 1)
		{
			self->selectedExportService = [exportServices objectAtIndex:0];
			[self exportSummary];
		}
		else
		{
			[self showFileExportSheet];
		}			
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_EXPORT])
	{
		self->selectedExportService = [actionSheet buttonTitleAtIndex:buttonIndex];
		[self exportSummary];
	}
}

@end
