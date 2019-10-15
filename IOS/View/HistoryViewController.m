// Created by Michael Simms on 8/29/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "HistoryViewController.h"
#import "ActivityMgr.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"
#import "StaticSummaryViewController.h"
#import "StringUtils.h"

#define TITLE                       NSLocalizedString(@"History", nil)

#define ACTION_SHEET_TITLE_ACTIVITY NSLocalizedString(@"Export", nil)
#define ACTION_SHEET_TITLE_EXPORT   NSLocalizedString(@"Export using", nil)
#define BUTTON_TITLE_EXPORT         NSLocalizedString(@"Export Summary", nil)
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

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
	[self.searchBar setTintColor:[UIColor blackColor]];
	[self.spinner stopAnimating];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate initializeHistoricalActivityList];

	[self buildDictionary];
	[self.historyTableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
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

#pragma mark methods for loading and sorting activity data

- (void)buildDictionary
{
	self->historyDictionary = nil;
	self->sortedKeys = nil;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	size_t numHistoricalActivities = [appDelegate getNumHistoricalActivities];
	if (numHistoricalActivities > 0)
	{
		self->historyDictionary = [[NSMutableDictionary alloc] init];
		if (self->historyDictionary)
		{
			for (size_t i = 0; i < numHistoricalActivities; ++i)
			{
				time_t startTime = 0;
				time_t endTime = 0;
				[appDelegate getHistoricalActivityStartAndEndTime:(NSInteger)i withStartTime:&startTime withEndTime:&endTime];

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
	else if (!self->searching)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_ERROR
																				 message:MSG_NO_WORKOUTS
																		  preferredStyle:UIAlertControllerStyleAlert];           
		[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self.navigationController popViewControllerAnimated:YES];
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
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

	self.spinner.hidden = FALSE;
	self.spinner.center = self.view.center;
	[self.spinner startAnimating];
	[self performSegueWithIdentifier:@SEGUE_TO_ACTIVITY_SUMMARY sender:self];
	[self.spinner stopAnimating];
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
	NSString* activityId = [[NSString alloc] initWithFormat:@"%s", ConvertActivityIndexToActivityId(activityIndex)];
	uint64_t bikeId = 0;
	NSString* allTagsStr = @"";

	// If a bike was specified then add that tag to the list of tags.
	InitializeBikeProfileList();
	GetActivityBikeProfile([activityId UTF8String], &bikeId);
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

	// Append any other tags that were associated with this activity.
	NSMutableArray* tags = [appDelegate getTagsForActivity:activityId];
	for (NSString* tag in tags)
	{
		if ([allTagsStr length] > 0)
			allTagsStr = [allTagsStr stringByAppendingString:@", "];
		allTagsStr = [allTagsStr stringByAppendingString:tag];
	}
	
	// Get the activity name.
	NSString* name = [appDelegate getActivityName:activityId];
	if ([name length] > 0)
	{
		name = [name stringByAppendingString:@": "];
	}

	// Get the start time.
	time_t startTime = 0;
	time_t endTime = 0;
	[appDelegate getHistoricalActivityStartAndEndTime:(NSInteger)activityIndex withStartTime:&startTime withEndTime:&endTime];
	NSString* startTimeStr = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];
	if ([allTagsStr length] > 0)
	{
		startTimeStr = [startTimeStr stringByAppendingString:@"\n"];
	}

	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@%@", name, startTimeStr, allTagsStr];
	cell.detailTextLabel.numberOfLines = 0;
	cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

	cell.textLabel.text = NSLocalizedString([appDelegate getHistoricalActivityType: activityIndex], nil);

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
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

		NSNumber* activityIndex = [self getActivityIndex:indexPath];
		NSString* activityId = [[NSString alloc] initWithFormat:@"%s", ConvertActivityIndexToActivityId([activityIndex intValue])];

		[appDelegate deleteActivity:activityId];
		[appDelegate initializeHistoricalActivityList];

		[self buildDictionary];
		[self.historyTableView reloadData];
	}
}

#pragma mark action sheet methods

- (BOOL)showActivityList
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* activityTypes = [appDelegate getActivityTypes];
	if ([activityTypes count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_ACTIVITY
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		for (NSString* type in activityTypes)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:type style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->selectedExportActivity = type;
				
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
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	return FALSE;
}

- (BOOL)showFileExportSheet
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	
	NSMutableArray* fileSites = [appDelegate getEnabledFileExportServices];
	if ([fileSites count] > 0)
	{
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:ACTION_SHEET_TITLE_EXPORT
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		
		for (NSString* fileSite in fileSites)
		{
			[alertController addAction:[UIAlertAction actionWithTitle:fileSite style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				self->selectedExportService = fileSite;
				[self exportSummary];
			}]];
		}
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		}]];
		[self presentViewController:alertController animated:YES completion:nil];
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
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	self->searching = true;

	if ([searchText length] == 0)
	{
		[appDelegate initializeHistoricalActivityList];
	}
	else
	{
		[appDelegate searchForTags:searchText];
	}

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

@end
