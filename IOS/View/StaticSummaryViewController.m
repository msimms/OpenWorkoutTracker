// Created by Michael Simms on 9/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "StaticSummaryViewController.h"
#import "AccelerometerLine.h"
#import "ActivityAttribute.h"
#import "ActivityType.h"
#import "AppStrings.h"
#import "AppDelegate.h"
#import "CorePlotViewController.h"
#import "Defines.h"
#import "ElevationLine.h"
#import "LapTimesViewController.h"
#import "LargeAlertController.h"
#import "LineFactory.h"
#import "Notifications.h"
#import "OverlayFactory.h"
#import "Params.h"
#import "Pin.h"
#import "Segues.h"
#import "SplitTimesViewController.h"
#import "StringUtils.h"
#import "TagViewController.h"

#define ROW_TITLE_SPLIT_TIMES             NSLocalizedString(@"Split Times", nil)
#define ROW_TITLE_LAP_TIMES               NSLocalizedString(@"Lap Times", nil)

#define SECTION_TITLE_START_AND_STOP      NSLocalizedString(@"Start and Finish", nil)
#define SECTION_TITLE_LAP_AND_SPLIT       NSLocalizedString(@"Lap and Split Times", nil)
#define SECTION_TITLE_CHARTS              NSLocalizedString(@"Charts", nil)
#define SECTION_TITLE_ATTRIBUTES          NSLocalizedString(@"Summary", nil)
#define SECTION_TITLE_SUPERLATIVES        NSLocalizedString(@"Superlatives", nil)
#define SECTION_TITLE_SYNC                NSLocalizedString(@"Synchronization", nil)
#define SECTION_TITLE_INTERNAL            NSLocalizedString(@"Internal", nil)

#define ACTION_SHEET_BUTTON_GPX           NSLocalizedString(@"GPX File", nil)
#define ACTION_SHEET_BUTTON_TCX           NSLocalizedString(@"TCX File", nil)
#define ACTION_SHEET_BUTTON_FIT           NSLocalizedString(@"FIT File", nil)
#define ACTION_SHEET_BUTTON_CSV           NSLocalizedString(@"CSV File", nil)

#define ACTION_SHEET_TRIM_FIRST_1         NSLocalizedString(@"Delete 1st Second", nil)
#define ACTION_SHEET_TRIM_FIRST_5         NSLocalizedString(@"Delete 1st Five Seconds", nil)
#define ACTION_SHEET_TRIM_FIRST_30        NSLocalizedString(@"Delete 1st Thirty Seconds", nil)
#define ACTION_SHEET_TRIM_SECOND_1        NSLocalizedString(@"Delete Last Second", nil)
#define ACTION_SHEET_TRIM_SECOND_5        NSLocalizedString(@"Delete Last Five Seconds", nil)
#define ACTION_SHEET_TRIM_SECOND_30       NSLocalizedString(@"Delete Last Thirty Seconds", nil)
#define ACTION_SHEET_FIX_REPS             NSLocalizedString(@"Fix Repetition Count", nil)
#define ACTION_SHEET_CHANGE_ACTIVITY_TYPE NSLocalizedString(@"Change Activity Type", nil)

#define ACTION_SHEET_TITLE_EXPORT         NSLocalizedString(@"Export using", nil)
#define ACTION_SHEET_TITLE_FILE_FORMAT    NSLocalizedString(@"Export as", nil)
#define ACTION_SHEET_TITLE_EDIT           NSLocalizedString(@"Edit", nil)
#define ACTION_SHEET_TITLE_ACTIVITY_TYPE  NSLocalizedString(@"Activity Type", nil)

#define START_PIN_NAME                    NSLocalizedString(@"Start", nil)
#define FINISH_PIN_NAME                   NSLocalizedString(@"Finish", nil)

#define MSG_DELETE_QUESTION               NSLocalizedString(@"Are you sure you want to delete this workout?", nil)
#define MSG_FIX_REPS                      NSLocalizedString(@"Enter the correct number of repetitions", nil)
#define MSG_EXPORT_QUESTION               NSLocalizedString(@"Do you want to export the actvity?", nil)
#define MSG_LOAD_FAILED                   NSLocalizedString(@"Failed to load the activity.", nil)
#define MSG_ENTER_A_NEW_ACTIVITY_NAME     NSLocalizedString(@"Enter a new activity name.", nil)
#define MSG_ENTER_A_NEW_ACTIVITY_DESC     NSLocalizedString(@"Enter a new activity description.", nil)

#define EMAIL_TITLE                       NSLocalizedString(@"Workout Data", nil)

typedef enum Time1Rows
{
	ROW_START_TIME = 0,
	ROW_END_TIME,
} Time1Rows;

typedef enum Time2Rows
{
	ROW_SPLIT_TIMES = 0,
	ROW_LAP_TIMES,
} Time2Rows;

typedef enum Sections
{
	SECTION_NAME = 0,
	SECTION_DESCRIPTION,
	SECTION_START_AND_END_TIME,
	SECTION_LAP_AND_SPLIT_TIMES,
	SECTION_CHARTS,
	SECTION_ATTRIBUTES,
	SECTION_SUPERLATIVES,
	SECTION_SYNC,
	SECTION_INTERNAL,
	NUM_SECTIONS
} Sections;

typedef enum NameSectionItems
{
	ROW_NAME = 0,
	NUM_NAME_SECTION_ROWS
} NameSectionItems;

typedef enum DescriptionSectionItems
{
	ROW_DESCRIPTION = 0,
	NUM_DESCRIPTION_SECTION_ROWS
} DescriptionSectionItems;

typedef enum InternalSectionItems
{
	ROW_ACTIVITY_ID = 0,
	ROW_ACTIVITY_HASH,
	NUM_INTERNAL_SECTION_ROWS
} InternalSectionItems;

typedef enum ExportFileTypeButtons
{
	EXPORT_BUTTON_GPX = 0,
	EXPORT_BUTTON_TCX,
	EXPORT_BUTTON_CSV,
	EXPORT_BUTTON_CANCEL
} ExportFileTypeButtons;

@implementation StaticSummaryViewController

@synthesize summaryTableView;
@synthesize deleteButton;
@synthesize exportButton;
@synthesize editButton;
@synthesize mapButton;
@synthesize bikeButton;
@synthesize shoeButton;
@synthesize tagsButton;
@synthesize spinner;

@synthesize tableTopConstraint;
@synthesize tableHeightConstraint;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->selectedChartIndex = 0;
		self->activityId = nil;

		self->startTime = 0;
		self->endTime = 0;

		self->hasLocationData = false;
		self->hasAccelerometerData = false;
		self->hasHeartRateData = false;
		self->hasCadenceData = false;
		self->hasPowerData = false;
		self->preferPaceOverSpeed = false;

		self->mapMode = MAP_OVERVIEW_COMPLETE_ROUTE;
	}
	return self;
}

- (void)viewDidLoad
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	[super viewDidLoad];

	self->movingToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->movingToolbar)
	{
		NSString* activityType = [appDelegate getHistoricalActivityType:self->activityId];

		// Remove the bike button if this isn't a bike activity or we don't have any bikes.
		if (!([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_STATIONARY_BIKE] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_TRIATHLON] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_DUATHLON]))
		{
			[self->movingToolbar removeObjectIdenticalTo:self.bikeButton];
		}
		else if ([[appDelegate getBikeNames] count] == 0)
		{
			[self->movingToolbar removeObjectIdenticalTo:self.bikeButton];
		}

		// Remove the bike button if this isn't a foot-based activity or we don't have any shoes.
		if (!([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_WALKING] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_TREADMILL] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_TRIATHLON] ||
			  [activityType isEqualToString:@ACTIVITY_TYPE_DUATHLON]))
		{
			[self->movingToolbar removeObjectIdenticalTo:self.shoeButton];
		}
		else if ([[appDelegate getShoeNames] count] == 0)
		{
			[self->movingToolbar removeObjectIdenticalTo:self.shoeButton];
		}
	}

	self->liftingToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->liftingToolbar)
	{
		[self->liftingToolbar removeObjectIdenticalTo:self.mapButton];
		[self->liftingToolbar removeObjectIdenticalTo:self.bikeButton];
	}

	self->syncedServices = [appDelegate retrieveSyncDestinationsForActivityId:self->activityId];
	self->notSyncedServices = [[NSMutableArray alloc] init];
	if ([self->syncedServices indexOfObject:@SYNC_DEST_WEB] == NSNotFound)
		[self->notSyncedServices addObject:@SYNC_DEST_WEB];
	if ([self->syncedServices indexOfObject:@SYNC_DEST_ICLOUD_DRIVE] == NSNotFound)
		[self->notSyncedServices addObject:@SYNC_DEST_ICLOUD_DRIVE];

	[self redraw];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityMetadataReceived:) name:@NOTIFICATION_NAME_ACTIVITY_METADATA object:nil];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate serverRequestActivityMetadata:self->activityId];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	NSString* segueId = [segue identifier];

	if ([segueId isEqualToString:@SEGUE_TO_TAG_VIEW])
	{
		TagViewController* tagVC = (TagViewController*)[segue destinationViewController];

		if (tagVC)
		{
			tagVC.title = self.navItem.title;
			[tagVC setActivityId:self->activityId];
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_CORE_PLOT_VIEW])
	{
		CorePlotViewController* plotVC = (CorePlotViewController*)[segue destinationViewController];

		if (plotVC)
		{
			NSString* chartTitle = [self->chartTitles objectAtIndex:self->selectedChartIndex];
			ChartLine* line = [LineFactory createLine:chartTitle withActivityId:self->activityId withView:plotVC];

			if (line)
			{
				[plotVC appendChartLine:line withXLabel:STR_TIME withYLabel:chartTitle];
				[plotVC setTitle:chartTitle];
			}
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_SPLIT_TIMES_VIEW])
	{
		SplitTimesViewController* splitVC = (SplitTimesViewController*)[segue destinationViewController];

		if (splitVC)
		{
			[splitVC setActivityId:self->activityId];
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_LAP_TIMES_VIEW])
	{
		LapTimesViewController* lapVC = (LapTimesViewController*)[segue destinationViewController];

		if (lapVC)
		{
			[lapVC setActivityId:self->activityId];
		}
	}
}

#pragma mark notification handlers

- (void)activityMetadataReceived:(NSNotification*)notification
{
	NSDictionary* responseData = [notification object];
	NSString* responseStr = [responseData objectForKey:@KEY_NAME_RESPONSE_DATA];
	NSError* error = nil;
	NSDictionary* activityData = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];

	// Valid JSON?
	if (activityData)
	{
		// If we were sent the activity name or description then update the view.
		NSString* activityName = [activityData objectForKey:@PARAM_ACTIVITY_NAME];
		NSString* activityDesc = [activityData objectForKey:@PARAM_ACTIVITY_DESCRIPTION];
		if (activityName || activityDesc)
		{
			[self.summaryTableView reloadData];
		}
	}
}

#pragma mark methods for configuring the initial screen view

- (void)redraw
{	
	[self.mapView setShowsUserLocation:FALSE];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if (appDelegate && [appDelegate loadHistoricalActivity:self->activityId])
	{
		self->attributeNames = [[NSMutableArray alloc] init];
		self->recordNames = [[NSMutableArray alloc] init];

		[appDelegate getHistoricalActivityStartAndEndTime:self->activityId withStartTime:&self->startTime withEndTime:&self->endTime];

		self->hasLocationData = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_STARTING_LATITUDE forActivityId:self->activityId].valid;
		self->hasAccelerometerData = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_X forActivityId:self->activityId].valid;
		self->hasHeartRateData = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_MAX_HEART_RATE forActivityId:self->activityId].valid;
		self->hasCadenceData = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_MAX_CADENCE forActivityId:self->activityId].valid;
		self->hasPowerData = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_MAX_POWER forActivityId:self->activityId].valid;
		self->preferPaceOverSpeed = [appDelegate isHistoricalActivityFootBased:self->activityId];

		self->timeSection1RowNames = [[NSMutableArray alloc] init];
		if (self->timeSection1RowNames)
		{
			[self->timeSection1RowNames addObject:STR_STARTED];
			[self->timeSection1RowNames addObject:STR_FINISHED];
		}

		self->timeSection2RowNames = [[NSMutableArray alloc] init];
		if (self->hasLocationData)
		{
			[self->timeSection2RowNames addObject:ROW_TITLE_SPLIT_TIMES];
			[self->timeSection2RowNames addObject:ROW_TITLE_LAP_TIMES];
		}

		if (self->hasLocationData || self->hasAccelerometerData)
		{
			self->chartTitles = [LineFactory getLineNames:self->hasLocationData hasAccelData:self->hasAccelerometerData hasHRData:self->hasHeartRateData hasCadenceData:self->hasCadenceData hasPowerData:self->hasPowerData willPreferPaceOverSpeed:preferPaceOverSpeed];
		}
		else
		{
			self->chartTitles = [[NSMutableArray alloc] init];
		}

		NSArray* tempAttrNames = [appDelegate getHistoricalActivityAttributes:self->activityId];
		for (NSString* attrName in tempAttrNames)
		{
			ActivityAttributeType attr = [appDelegate queryHistoricalActivityAttribute:[attrName UTF8String] forActivityId:self->activityId];
			if (attr.valid)
			{
				if ([self isRecordName:attrName])
				{
					[self->recordNames addObject:attrName];
				}
				else
				{
					[self->attributeNames addObject:attrName];
				}
			}
		}
		
		// Figure out which sections will be shown and which are empty.
		memset(self->sectionIndexes, 0, sizeof(self->sectionIndexes));
		self->numVisibleSections = 0;
		for (size_t sectionIndex = 0; sectionIndex < NUM_SECTIONS; ++sectionIndex)
		{
			NSInteger count = 0;

			switch (sectionIndex)
			{
			case SECTION_NAME:
				count = NUM_NAME_SECTION_ROWS;
				break;
			case SECTION_DESCRIPTION:
				count = NUM_DESCRIPTION_SECTION_ROWS;
				break;
			case SECTION_START_AND_END_TIME:
				count = [self->timeSection1RowNames count];
				break;
			case SECTION_LAP_AND_SPLIT_TIMES:
				count = [self->timeSection2RowNames count];
				break;
			case SECTION_CHARTS:
				count = [self->chartTitles count];
				break;
			case SECTION_ATTRIBUTES:
				count = [self->attributeNames count];
				break;
			case SECTION_SUPERLATIVES:
				count = [self->recordNames count];
				break;
			case SECTION_SYNC:
				if ([appDelegate isFeatureEnabled:FEATURE_BROADCAST])
					count = [self->syncedServices count] + [self->notSyncedServices count];
				else
					count = 0;
				break;
			case SECTION_INTERNAL:
				if ([appDelegate isFeatureEnabled:FEATURE_DEBUG])
					count = NUM_INTERNAL_SECTION_ROWS;
				else
					count = 0;
				break;
			}

			if (count > 0)
			{
				self->sectionIndexes[self->numVisibleSections++] = sectionIndex;
			}
		}
		
		self.navItem.title = NSLocalizedString([appDelegate getHistoricalActivityType:self->activityId], nil);
		
		[self drawRoute];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_LOAD_FAILED];
	}

	[self stopSpinner:self.spinner];
}

#pragma mark utility methods

- (BOOL)isRecordName:(NSString*)name
{
	return (([name rangeOfString:@"Fastest"].location != NSNotFound) ||
			([name rangeOfString:@"Biggest"].location != NSNotFound) ||
			([name rangeOfString:@"Min."].location != NSNotFound) ||
			([name rangeOfString:@"Max."].location != NSNotFound));
}

#pragma mark action sheet methods

- (void)handleFileDestinationSelection
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	if (self->exportedFileName)
	{
		// Email
		if ([self->selectedExportService isEqualToString:@SYNC_DEST_EMAIL])
		{
			[super displayEmailComposerSheet:EMAIL_TITLE withBody:STR_EMAIL_CONTENTS withFileName:self->exportedFileName withMimeType:@"text/xml" withDelegate:self];
		}

		// Web
		else if ([self->selectedExportService isEqualToString:@SYNC_DEST_WEB])
		{
			if ([appDelegate exportActivityFileToCloudService:self->exportedFileName forActivityId:self->activityId toService:CLOUD_SERVICE_WEB])
			{
				[super showOneButtonAlert:STR_EXPORT withMsg:STR_EXPORT_SUCCEEDED];
				[appDelegate markAsSynchedToWeb:self->activityId];
			}
			else
			{
				[super showOneButtonAlert:STR_ERROR withMsg:STR_EXPORT_FAILED];
			}
		}

		// iCloud Drive
		else
		{
			if ([appDelegate exportActivityFileToCloudService:self->exportedFileName forActivityId:self->activityId toServiceNamed:self->selectedExportService])
			{
				[super showOneButtonAlert:STR_EXPORT withMsg:STR_EXPORT_SUCCEEDED];
				[appDelegate markAsSynchedToICloudDrive:self->activityId];
			}
			else
			{
				[super showOneButtonAlert:STR_ERROR withMsg:STR_EXPORT_FAILED];
			}
		}
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_EXPORT_FAILED];
	}
}

- (void)exportActivityToTempFile:(NSString*)activityId withFileFormat:(FileFormat)format
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	self->exportedFileName = [appDelegate exportActivityToTempFile:self->activityId withFileFormat:format];
	if (self->exportedFileName)
	{
		[self handleFileDestinationSelection];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_EXPORT_FAILED];
	}
}

- (void)showFileFormatSheet
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_FILE_FORMAT
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	[appDelegate loadAllHistoricalActivitySensorData:self->activityId];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];

	if ([appDelegate getNumHistoricalActivityLocationPoints:self->activityId] > 0)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_GPX style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self exportActivityToTempFile:self->activityId withFileFormat:FILE_GPX];
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_TCX style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self exportActivityToTempFile:self->activityId withFileFormat:FILE_TCX];
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_FIT style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self exportActivityToTempFile:self->activityId withFileFormat:FILE_FIT];
		}]];
	}
	if ([appDelegate getNumHistoricalActivityAccelerometerReadings:self->activityId] > 0)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_CSV style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self exportActivityToTempFile:self->activityId withFileFormat:FILE_CSV];
		}]];
	}

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCloudSheet:(NSArray*)fileExportServices
{	
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_EXPORT
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];

	for (NSString* fileExportService in fileExportServices)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:fileExportService style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			self->selectedExportService = fileExportService;
			[self showFileFormatSheet];
		}]];
	}

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark accessor methods

- (void)setActivityId:(NSString*)activityId
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	self->activityId = activityId;

	[appDelegate initializeHistoricalActivityList];
	[appDelegate createHistoricalActivityObject:activityId];
	[appDelegate loadHistoricalActivitySummaryData:activityId];
}

#pragma mark location handling methods

- (void)drawRoute
{	
	CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 90;
	CLLocationDegrees minLon = 180;

	size_t pointIndex = 0;
	double latitude = (double)0.0;
	double longitude = (double)0.0;
	double altitude = (double)0.0;
	time_t timestamp = 0;
	CLLocation* location = nil;
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	while ([appDelegate getHistoricalActivityLocationPoint:self->activityId withPointIndex:pointIndex withLatitude:&latitude withLongitude:&longitude withAltitude:&altitude withTimestamp:&timestamp])
	{
		// Draw every other point.
		if (pointIndex % 2 == 0)
		{
			location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
			if (location)
			{
				if (location.coordinate.latitude > maxLat)
					maxLat = location.coordinate.latitude;
				if (location.coordinate.latitude < minLat)
					minLat = location.coordinate.latitude;
				if (location.coordinate.longitude > maxLon)
					maxLon = location.coordinate.longitude;
				if (location.coordinate.longitude < minLon)
					minLon = location.coordinate.longitude;

				[self addNewLocation:location];
			}
		}

		if (pointIndex == 0)
		{
			Pin* pin = [[Pin alloc] initWithCoordinates:location.coordinate placeName:START_PIN_NAME description:@""];
			if (pin)
			{
				[self.mapView addAnnotation:pin];
			}
		}

		++pointIndex;
	}

	if (location)
	{
		Pin* pin = [[Pin alloc] initWithCoordinates:location.coordinate placeName:FINISH_PIN_NAME description:@""];
		if (pin)
		{
			[self.mapView addAnnotation:pin];
		}
	}

	CGRect mapRect = [self.mapView frame];
	CGRect summaryTableRect = [self.summaryTableView frame];

	if (pointIndex > 0)
	{
		self.mapView.hidden = FALSE;
		[self.mapView setDelegate:self];
		self.tableTopConstraint.constant = 0;
		self.tableHeightConstraint.constant = self.view.frame.size.height - self.toolbar.frame.size.height;
		[self.summaryTableView needsUpdateConstraints];
		[self.toolbar setItems:self->movingToolbar animated:NO];
	}
	else
	{
		self.mapView.hidden = TRUE;
		self.tableTopConstraint.constant = -1 * mapRect.size.height;
		self.tableHeightConstraint.constant = self.view.frame.size.height - self.toolbar.frame.size.height;
		[self.summaryTableView needsUpdateConstraints];
		[self.toolbar setItems:self->liftingToolbar animated:NO];
	}

	[self.summaryTableView setFrame:summaryTableRect];
	[self.summaryTableView sizeToFit];
}

#pragma mark button handlers

- (IBAction)onDelete:(id)sender
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_CAUTION
																			 message:MSG_DELETE_QUESTION
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		if ([appDelegate deleteActivity:self->activityId])
		{
			[self.navigationController popViewControllerAnimated:YES];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:STR_DELETE_FAILED];
		}
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onExport:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSArray* fileExportServices = [appDelegate getEnabledFileExportServices];

	if ([fileExportServices count] == 1)
	{
		self->selectedExportService = [fileExportServices objectAtIndex:0];
		[self showFileFormatSheet];
	}
	else
	{
		[self showCloudSheet:fileExportServices];
	}
}

- (void)changeActivityType
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	// Display the list of activities from which the user may choose.
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_ACTIVITY_TYPE
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	
	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	
	for (NSString* type in [appDelegate getActivityTypes])
	{
		[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(type, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[appDelegate updateActivityType:self->activityId withName:type];
			[self redraw];
			[self.summaryTableView reloadData];
		}]];
	}
	
	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onEdit:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_EDIT
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_FIRST_1 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->startTime + 1) * 1000;
		[appDelegate trimActivityData:self->activityId withNewTime:newTime fromStart:TRUE];
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_FIRST_5 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->startTime + 5) * 1000;
		[appDelegate trimActivityData:self->activityId withNewTime:newTime fromStart:TRUE];
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_FIRST_30 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->startTime + 30) * 1000;
		[appDelegate trimActivityData:self->activityId withNewTime:newTime fromStart:TRUE];
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_SECOND_1 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->endTime - 1) * 1000;
		[appDelegate trimActivityData:self->activityId withNewTime:newTime fromStart:TRUE];
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_SECOND_5 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->endTime - 5) * 1000;
		[appDelegate trimActivityData:self->activityId withNewTime:newTime fromStart:TRUE];
		[self redraw];
		[self.summaryTableView reloadData];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_TRIM_SECOND_30 style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		uint64_t newTime = ((uint64_t)self->endTime - 30) * 1000;
		[appDelegate trimActivityData:self->activityId withNewTime:newTime fromStart:TRUE];
		[self redraw];
		[self.summaryTableView reloadData];
	}]];

	ActivityAttributeType repsValue = [appDelegate queryHistoricalActivityAttribute:ACTIVITY_ATTRIBUTE_REPS forActivityId:self->activityId];
	if (repsValue.valid)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_FIX_REPS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			UIAlertController* repsAlertController = [UIAlertController alertControllerWithTitle:STR_REPITITIONS
																					 message:MSG_FIX_REPS
																			  preferredStyle:UIAlertControllerStyleAlert];
			[repsAlertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
				textField.placeholder = [[NSString alloc] initWithFormat:@"%llu", repsValue.value.intVal];
				textField.keyboardType = UIKeyboardTypeNumberPad;
			}];
			[repsAlertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				UITextField* field = repsAlertController.textFields.firstObject;

				ActivityAttributeType value;
				value.value.intVal = [[field text] intValue];
				value.valueType = TYPE_INTEGER;
				value.measureType = MEASURE_COUNT;

				[appDelegate setHistoricalActivityAttribute:self->activityId withAttributeName:ACTIVITY_ATTRIBUTE_REPS_CORRECTED withAttributeType:value];
				[appDelegate saveHistoricalActivitySummaryData:self->activityId];
			}]];
			[self presentViewController:repsAlertController animated:YES completion:nil];
		}]];
	}

	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_CHANGE_ACTIVITY_TYPE style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self changeActivityType];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onTag:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_TAG_VIEW sender:self];
}

- (IBAction)onBike:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSArray* bikeNames = [appDelegate getBikeNames];

	if ([bikeNames count] > 0)
	{
		NSString* selectedBikeName;
		NSArray* tags = [appDelegate getTagsForActivity:self->activityId];
		
		// Find any existing selection.
		for (NSString* bikeName in bikeNames)
		{
			for (NSString* tag in tags)
			{
				if ([tag caseInsensitiveCompare:bikeName] == NSOrderedSame)
				{
					selectedBikeName = tag;
					break;
				}
			}
		}

		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:STR_BIKE
																		  preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
		}]];

		// Add an option for each bike.
		for (NSString* bikeName in bikeNames)
		{
			UIAlertAction* button = [UIAlertAction actionWithTitle:bikeName style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[appDelegate createTag:bikeName forActivityId:self->activityId];
			}];
			[alertController addAction:button];

			// Check the existing selection, if any.
			if (selectedBikeName)
			{
				if ([bikeName caseInsensitiveCompare:selectedBikeName] == NSOrderedSame)
				{
					[self checkActionSheetButton:button];
				}
			}
		}

		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onShoe:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSArray* shoeNames = [appDelegate getShoeNames];
	
	if ([shoeNames count] > 0)
	{
		NSString* selectedShoeName;
		NSArray* tags = [appDelegate getTagsForActivity:self->activityId];
		
		// Find any existing selection.
		for (NSString* shoeName in shoeNames)
		{
			for (NSString* tag in tags)
			{
				if ([tag caseInsensitiveCompare:shoeName] == NSOrderedSame)
				{
					selectedShoeName = tag;
					break;
				}
			}
		}

		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																				 message:STR_SHOES
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		
		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
		}]];
		
		// Add an option for each pair of shoes.
		for (NSString* shoeName in shoeNames)
		{
			UIAlertAction* button = [UIAlertAction actionWithTitle:shoeName style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
				[appDelegate createTag:shoeName forActivityId:self->activityId];
			}];
			[alertController addAction:button];
			
			// Check the existing selection, if any.
			if (selectedShoeName)
			{
				if ([shoeName caseInsensitiveCompare:selectedShoeName] == NSOrderedSame)
				{
					[self checkActionSheetButton:button];
				}
			}
		}
		
		// Show the action sheet.
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

#pragma mark called when renaming the activity or changing its description

- (void)getNewActivityName
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	LargeAlertController* largeAlert = [[LargeAlertController alloc] init];
	
	largeAlert->title = STR_NAME;
	largeAlert->subtitle = MSG_ENTER_A_NEW_ACTIVITY_NAME;
	largeAlert->defaultText = [appDelegate getActivityName:self->activityId];
	largeAlert->completionHandler = ^(NSString* text) {
		[appDelegate updateActivityName:self->activityId withName:text];
		[self.summaryTableView reloadData];
	};
	[self presentViewController:largeAlert animated:YES completion:nil];
}

- (void)getNewActivityDescription
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	LargeAlertController* largeAlert = [[LargeAlertController alloc] init];

	largeAlert->title = STR_DESCRIPTION;
	largeAlert->subtitle = MSG_ENTER_A_NEW_ACTIVITY_DESC;
	largeAlert->defaultText = [appDelegate getActivityDescription:self->activityId];
	largeAlert->completionHandler = ^(NSString* text) {
		[appDelegate updateActivityDescription:self->activityId withDescription:text];
		[self.summaryTableView reloadData];
	};
	[self presentViewController:largeAlert animated:YES completion:nil];
}

#pragma mark called when the user selects a row

- (void)handleSyncRequest:(NSString*)service
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:STR_EXPORT
																			 message:MSG_EXPORT_QUESTION
																	  preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_NO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		self->selectedExportService = service;

		// We always use GPX when exporting to the web. Otherwise, let the user choose their preferred file format.
		if ([self->selectedExportService isEqualToString:@SYNC_DEST_WEB])
			[self exportActivityToTempFile:self->activityId withFileFormat:FILE_GPX];
		else
			[self showFileFormatSheet];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)handleSelectedRow:(NSIndexPath*)indexPath onTable:(UITableView*)tableView
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	NSInteger row = [indexPath row];

	switch (actualSection)
	{
	case SECTION_NAME:
		[self getNewActivityName];
		break;
	case SECTION_DESCRIPTION:
		[self getNewActivityDescription];
		break;
	case SECTION_START_AND_END_TIME:
		break;
	case SECTION_LAP_AND_SPLIT_TIMES:
		if (row == ROW_SPLIT_TIMES)
		{
			[self performSegueWithIdentifier:@SEGUE_TO_SPLIT_TIMES_VIEW sender:self];
		}
		else if (row == ROW_LAP_TIMES)
		{
			[self performSegueWithIdentifier:@SEGUE_TO_LAP_TIMES_VIEW sender:self];
		}
		break;
	case SECTION_CHARTS:
		{
			self->selectedChartIndex = row;
			[self performSegueWithIdentifier:@SEGUE_TO_CORE_PLOT_VIEW sender:self];
		}
		break;
	case SECTION_ATTRIBUTES:
		break;
	case SECTION_SUPERLATIVES:
		if ([self superlativeHasSegue:cell])
		{
		}
		break;
	case SECTION_SYNC:
		if (row < [self->syncedServices count])
		{
			NSString* serviceName = [self->syncedServices objectAtIndex:row];
			[self handleSyncRequest:serviceName];
		}
		else
		{
			NSString* serviceName = [self->notSyncedServices objectAtIndex:(row - [self->syncedServices count])];
			[self handleSyncRequest:serviceName];
		}
		break;
	case SECTION_INTERNAL:
		break;
	}
}

#pragma mark UITableView methods

- (BOOL)superlativeHasSegue:(UITableViewCell*)cell
{
	return !self.mapView.hidden && [self isRecordName:cell.textLabel.text];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
	return self->numVisibleSections;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)visibleSection
{
	NSInteger actualSection = self->sectionIndexes[visibleSection];

	switch (actualSection)
	{
	case SECTION_NAME:
		return STR_NAME;
	case SECTION_DESCRIPTION:
		return STR_DESCRIPTION;
	case SECTION_START_AND_END_TIME:
		return SECTION_TITLE_START_AND_STOP;
	case SECTION_LAP_AND_SPLIT_TIMES:
		return SECTION_TITLE_LAP_AND_SPLIT;
	case SECTION_CHARTS:
		return SECTION_TITLE_CHARTS;
	case SECTION_ATTRIBUTES:
		return SECTION_TITLE_ATTRIBUTES;
	case SECTION_SUPERLATIVES:
		return SECTION_TITLE_SUPERLATIVES;
	case SECTION_SYNC:
		return SECTION_TITLE_SYNC;
	case SECTION_INTERNAL:
		return SECTION_TITLE_INTERNAL;
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)visibleSection
{
	NSInteger actualSection = self->sectionIndexes[visibleSection];

	switch (actualSection)
	{
	case SECTION_NAME:
		return NUM_NAME_SECTION_ROWS;
	case SECTION_DESCRIPTION:
		return NUM_DESCRIPTION_SECTION_ROWS;
	case SECTION_START_AND_END_TIME:
		return [self->timeSection1RowNames count];
	case SECTION_LAP_AND_SPLIT_TIMES:
		return [self->timeSection2RowNames count];
	case SECTION_CHARTS:
		return [self->chartTitles count];
	case SECTION_ATTRIBUTES:
		return [self->attributeNames count];
	case SECTION_SUPERLATIVES:
		return [self->recordNames count];
	case SECTION_SYNC:
		return [self->syncedServices count] + [self->notSyncedServices count];
	case SECTION_INTERNAL:
		return NUM_INTERNAL_SECTION_ROWS;
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	NSInteger row = [indexPath row];

	switch (actualSection)
	{
	case SECTION_NAME:
		if (row == ROW_NAME)
		{
			[content setText:[appDelegate getActivityName:self->activityId]];
			content.textProperties.numberOfLines = 0;
			content.textProperties.adjustsFontSizeToFitWidth = TRUE;
			content.textProperties.lineBreakMode = NSLineBreakByTruncatingTail;
		}
		break;
	case SECTION_DESCRIPTION:
		if (row == ROW_DESCRIPTION)
		{
			[content setText:[appDelegate getActivityDescription:self->activityId]];
			content.textProperties.numberOfLines = 0;
			content.textProperties.adjustsFontSizeToFitWidth = TRUE;
			content.textProperties.lineBreakMode = NSLineBreakByWordWrapping;
		}
		break;
	case SECTION_START_AND_END_TIME:
		switch (row)
		{
		case ROW_START_TIME:
			[content setText:STR_STARTED];
			if (startTime > 0)
				[content setSecondaryText:[StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]]];
			break;
		case ROW_END_TIME:
			[content setText:STR_FINISHED];
			if (endTime > 0)
				[content setSecondaryText:[StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:endTime]]];
			break;
		}
		break;
	case SECTION_LAP_AND_SPLIT_TIMES:
		switch (row)
		{
		case ROW_SPLIT_TIMES:
			[content setText:ROW_TITLE_SPLIT_TIMES];
			break;
		case ROW_LAP_TIMES:
			[content setText:ROW_TITLE_LAP_TIMES];
			break;
		}
		break;
	case SECTION_CHARTS:
		{
			[content setText:NSLocalizedString([self->chartTitles objectAtIndex:row], nil)];
		}
		break;
	case SECTION_ATTRIBUTES:
		{
			NSString* attributeName = [self->attributeNames objectAtIndex:row];
			ActivityAttributeType attr = [appDelegate queryHistoricalActivityAttribute:[attributeName UTF8String] forActivityId:self->activityId];

			if (attr.valid)
			{
				// Convert the units to the unit system the user prefers to use.
				[appDelegate convertToPreferredUnits:&attr];

				// Format the display strings.
				NSString* valueStr = [StringUtils formatActivityViewType:attr];
				NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];

				// Add the text to the table.
				[content setText:NSLocalizedString(attributeName, nil)];
				if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
					[content setSecondaryText:[NSString stringWithFormat:@"%@ %@", valueStr, unitsStr]];
				else
					[content setSecondaryText:[NSString stringWithFormat:@"%@", valueStr]];
			}
			else
			{
				[content setText:NSLocalizedString(attributeName, nil)];
			}
		}
		break;
	case SECTION_SUPERLATIVES:
		{
			NSString* attributeName = [self->recordNames objectAtIndex:row];
			ActivityAttributeType attr = [appDelegate queryHistoricalActivityAttribute:[attributeName UTF8String] forActivityId:self->activityId];

			if (attr.valid)
			{
				// Format the display strings.
				NSString* valueStr = [StringUtils formatActivityViewType:attr];
				NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];

				// Add the text to the table.
				[content setText:NSLocalizedString(attributeName, nil)];
				if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
					[content setSecondaryText:[NSString stringWithFormat:@"%@ %@", valueStr, unitsStr]];
				else
					[content setSecondaryText:[NSString stringWithFormat:@"%@", valueStr]];
			}
			else
			{
				[content setText:NSLocalizedString(attributeName, nil)];
			}
		}
		break;
	case SECTION_SYNC:
		{
			if (row < [self->syncedServices count])
			{
				[content setText:NSLocalizedString([self->syncedServices objectAtIndex:row], nil)];
				[content setSecondaryText:NSLocalizedString(STR_SYNCHED, nil)];
			}
			else
			{
				[content setText:NSLocalizedString([self->notSyncedServices objectAtIndex:row - [self->syncedServices count]], nil)];
				[content setSecondaryText:NSLocalizedString(STR_NOT_SYNCHED, nil)];
			}
		}
		break;
	case SECTION_INTERNAL:
		{
			switch (row)
			{
			case ROW_ACTIVITY_ID:
				[content setText:NSLocalizedString(@"Activity ID", nil)];
				[content setSecondaryText:self->activityId];
				break;
			case ROW_ACTIVITY_HASH:
				{
					NSString* hash = [appDelegate getActivityHash:self->activityId];

					[content setText:NSLocalizedString(@"Activity Hash", nil)];
					if ([hash length] > 0)
						[content setSecondaryText:hash];
				}
				break;
			}
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
	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];

	switch (actualSection)
	{
	case SECTION_NAME:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	case SECTION_DESCRIPTION:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	case SECTION_START_AND_END_TIME:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	case SECTION_LAP_AND_SPLIT_TIMES:
		cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
		break;
	case SECTION_CHARTS:
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		break;
	case SECTION_ATTRIBUTES:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	case SECTION_SUPERLATIVES:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	case SECTION_SYNC:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	case SECTION_INTERNAL:
		cell.accessoryType = UITableViewCellAccessoryNone;
		break;
	}
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedRow:indexPath onTable:tableView];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	[self handleSelectedRow:indexPath onTable:tableView];
}

#pragma mark mail composition methods

- (void)messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result
{
	[self becomeFirstResponder];
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
