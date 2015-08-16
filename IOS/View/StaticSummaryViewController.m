// Created by Michael Simms on 9/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "StaticSummaryViewController.h"
#import "AccelerometerLine.h"
#import "ActivityAttribute.h"
#import "ActivityMgr.h"
#import "ActivityName.h"
#import "AppDelegate.h"
#import "CorePlotViewController.h"
#import "ElevationLine.h"
#import "LapTimesViewController.h"
#import "LineFactory.h"
#import "OverlayFactory.h"
#import "Pin.h"
#import "Segues.h"
#import "SplitTimesViewController.h"
#import "StringUtils.h"
#import "TagViewController.h"

#define ROW_TITLE_STARTED              NSLocalizedString(@"Started", nil)
#define ROW_TITLE_FINISHED             NSLocalizedString(@"Finished", nil)
#define ROW_TITLE_SPLIT_TIMES          NSLocalizedString(@"Split Times", nil)
#define ROW_TITLE_LAP_TIMES            NSLocalizedString(@"Lap Times", nil)

#define SECTION_TITLE_START_AND_STOP   NSLocalizedString(@"Start and Finish", nil)
#define SECTION_TITLE_LAP_AND_SPLIT    NSLocalizedString(@"Lap and Split Times", nil)
#define SECTION_TITLE_CHARTS           NSLocalizedString(@"Charts", nil)
#define SECTION_TITLE_ATTRIBUTES       NSLocalizedString(@"Summary", nil)
#define SECTION_TITLE_SUPERLATIVES     NSLocalizedString(@"Superlatives", nil)

#define ACTION_SHEET_BUTTON_GPX        NSLocalizedString(@"GPX File", nil)
#define ACTION_SHEET_BUTTON_TCX        NSLocalizedString(@"TCX File", nil)
#define ACTION_SHEET_BUTTON_CSV        NSLocalizedString(@"CSV File", nil)

#define ACTION_SHEET_TRIM_FIRST_1      NSLocalizedString(@"Delete 1st Second", nil)
#define ACTION_SHEET_TRIM_FIRST_5      NSLocalizedString(@"Delete 1st Five Seconds", nil)
#define ACTION_SHEET_TRIM_FIRST_30     NSLocalizedString(@"Delete 1st Thirty Seconds", nil)
#define ACTION_SHEET_TRIM_SECOND_1     NSLocalizedString(@"Delete Last Second", nil)
#define ACTION_SHEET_TRIM_SECOND_5     NSLocalizedString(@"Delete Last Five Seconds", nil)
#define ACTION_SHEET_TRIM_SECOND_30    NSLocalizedString(@"Delete Last Thirty Seconds", nil)
#define ACTION_SHEET_FIX_REPS          NSLocalizedString(@"Fix Repetition Count", nil)

#define ACTION_SHEET_TITLE_EXPORT      NSLocalizedString(@"Export using", nil)
#define ACTION_SHEET_TITLE_FILE_FORMAT NSLocalizedString(@"Export as", nil)
#define ACTION_SHEET_TITLE_MAP_TYPE    NSLocalizedString(@"Select the map type", nil)
#define ACTION_SHEET_TITLE_BIKE        NSLocalizedString(@"Bike", nil)
#define ACTION_SHEET_TITLE_EDIT        NSLocalizedString(@"Edit", nil)

#define ACTION_SHEET_BUTTON_CANCEL     NSLocalizedString(@"Cancel", nil)

#define START_PIN_NAME                 NSLocalizedString(@"Start", nil)
#define FINISH_PIN_NAME                NSLocalizedString(@"Finish", nil)

#define FASTEST                        NSLocalizedString(@"Fastest", nil)
#define BIGGEST                        NSLocalizedString(@"Biggest", nil)
#define TIME                           NSLocalizedString(@"Time", nil)

#define ALERT_TITLE_ERROR              NSLocalizedString(@"Error", nil)
#define ALERT_TITLE_CAUTION            NSLocalizedString(@"Caution", nil)
#define ALERT_TITLE_FIX_REPS           NSLocalizedString(@"Repetitions", nil)

#define EXPORT_FAILED                  NSLocalizedString(@"Export failed!", nil)

#define MSG_DELETE_QUESTION            NSLocalizedString(@"Are you sure you want to delete this workout?", nil)
#define MSG_FIX_REPS                   NSLocalizedString(@"Enter the correct number of repetitions", nil)
#define MSG_LOW_MEMORY                 NSLocalizedString(@"Low memory", nil)

#define BUTTON_TITLE_OK                NSLocalizedString(@"Ok", nil)
#define BUTTON_TITLE_YES               NSLocalizedString(@"Yes", nil)
#define BUTTON_TITLE_NO                NSLocalizedString(@"No", nil)

#define BUTTON_TITLE_DELETE            NSLocalizedString(@"Delete", nil)
#define BUTTON_TITLE_EXPORT            NSLocalizedString(@"Export", nil)
#define BUTTON_TITLE_EDIT              NSLocalizedString(@"Edit", nil)
#define BUTTON_TITLE_MAP               NSLocalizedString(@"Map", nil)
#define BUTTON_TITLE_BIKE              NSLocalizedString(@"Bike", nil)
#define BUTTON_TITLE_TAG               NSLocalizedString(@"Tag", nil)

#define EMAIL_TITLE                    NSLocalizedString(@"Workout Data", nil)
#define EMAIL_CONTENTS                 NSLocalizedString(@"The data file is attached.", nil)

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
	SECTION_START_AND_END_TIME = 0,
	SECTION_LAP_AND_SPLIT_TIMES,
	SECTION_CHARTS,
	SECTION_ATTRIBUTES,
	SECTION_SUPERLATIVES,
	NUM_SECTIONS
} Sections;

typedef enum ExportFileTypeButtons
{
	EXPORT_BUTTON_GPX = 0,
	EXPORT_BUTTON_TCX,
	EXPORT_BUTTON_CSV,
	EXPORT_BUTTON_CANCEL
} ExportFileTypeButtons;

@interface StaticSummaryViewController ()

@end

@implementation StaticSummaryViewController

@synthesize navItem;
@synthesize toolbar;
@synthesize summaryTableView;
@synthesize deleteButton;
@synthesize exportButton;
@synthesize editButton;
@synthesize mapButton;
@synthesize bikeButton;
@synthesize tagsButton;
@synthesize spinner;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		self->activityIndex = 0;
		self->attributeIndex = 0;

		self->activityId = 0;

		self->startTime = 0;
		self->endTime = 0;

		self->hasGpsData = false;
		self->hasAccelerometerData = false;
		self->hasHeartRateData = false;
		self->hasCadenceData = false;
		self->hasPowerData = false;

		self->mapMode = MAP_OVERVIEW_COMPLETE_ROUTE;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[self.deleteButton setTitle:BUTTON_TITLE_DELETE];
	[self.exportButton setTitle:BUTTON_TITLE_EXPORT];
	[self.editButton setTitle:BUTTON_TITLE_EDIT];
	[self.mapButton setTitle:BUTTON_TITLE_MAP];
	[self.bikeButton setTitle:BUTTON_TITLE_BIKE];
	[self.tagsButton setTitle:BUTTON_TITLE_TAG];

	self->movingToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->movingToolbar)
	{
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

		NSString* activityName = [appDelegate getHistorialActivityName:self->activityIndex];
		if (!([activityName isEqualToString:@ACTIVITY_NAME_CYCLING] ||
			  [activityName isEqualToString:@ACTIVITY_NAME_MOUNTAIN_BIKING] ||
			  [activityName isEqualToString:@ACTIVITY_NAME_STATIONARY_BIKE]))
		{
			[self->movingToolbar removeObjectIdenticalTo:self.bikeButton];
		}
		else if ([[appDelegate getBikeNames] count] == 0)
		{
			[self->movingToolbar removeObjectIdenticalTo:self.bikeButton];
		}
	}

	self->liftingToolbar = [NSMutableArray arrayWithArray:self.toolbar.items];
	if (self->liftingToolbar)
	{
		[self->liftingToolbar removeObjectIdenticalTo:self.mapButton];
		[self->liftingToolbar removeObjectIdenticalTo:self.bikeButton];
	}

	[self redraw];

	UILongPressGestureRecognizer* gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapGesture:)];
	if (gesture)
	{
		gesture.minimumPressDuration = 1.0;
		[self.mapView addGestureRecognizer:gesture];
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
	[self.toolbar setTintColor:[UIColor blackColor]];
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (void)redraw
{	
	[self.mapView setShowsUserLocation:FALSE];
	[self.spinner stopAnimating];
	
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if (appDelegate && [appDelegate loadHistoricalActivity:self->activityIndex])
	{
		self->attributeNames = [[NSMutableArray alloc] init];
		self->recordNames = [[NSMutableArray alloc] init];
		
		self->activityId = ConvertActivityIndexToActivityId(self->activityIndex);
		GetHistoricalActivityStartAndEndTime(self->activityIndex, &self->startTime, &self->endTime);
		
		self->hasGpsData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_STARTING_LATITUDE).valid;
		self->hasAccelerometerData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_X).valid;
		self->hasHeartRateData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_MAX_HEART_RATE).valid;
		self->hasCadenceData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_MAX_CADENCE).valid;
		self->hasPowerData = QueryHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_MAX_POWER).valid;
		
		self->chartTitles = [LineFactory getLineNames:self->hasGpsData withBool:self->hasAccelerometerData withBool:self->hasHeartRateData withBool:self->hasCadenceData withBool:self->hasPowerData];
		
		self->timeSection1RowNames = [[NSMutableArray alloc] init];
		if (self->timeSection1RowNames)
		{
			[self->timeSection1RowNames addObject:ROW_TITLE_STARTED];
			[self->timeSection1RowNames addObject:ROW_TITLE_FINISHED];
		}

		self->timeSection2RowNames = [[NSMutableArray alloc] init];
		if (self->hasGpsData)
		{
			[self->timeSection2RowNames addObject:ROW_TITLE_SPLIT_TIMES];
			[self->timeSection2RowNames addObject:ROW_TITLE_LAP_TIMES];
		}

		uint64_t bikeId;
		if (GetActivityBikeProfile(self->activityId, &bikeId))
		{
			char* name = NULL;
			double weightKg = (double)0.0;
			double wheelSize = (double)0.0;
			
			if (GetBikeProfileById(bikeId, &name, &weightKg, &wheelSize))
			{
				NSString* tempName = [[NSString alloc] initWithUTF8String:name];
				[self.bikeButton setTitle:tempName];
				free((void*)name);
			}
		}

		NSArray* tempAttrNames = [appDelegate getHistoricalActivityAttributes:self->activityIndex];
		for (NSString* attrName in tempAttrNames)
		{
			ActivityAttributeType attr = QueryHistoricalActivityAttribute(self->activityIndex, [attrName UTF8String]);
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
			}

			if (count > 0)
			{
				self->sectionIndexes[self->numVisibleSections++] = sectionIndex;
			}
		}
		
		self.navItem.title = NSLocalizedString([appDelegate getHistorialActivityName:self->activityIndex], nil);
		
		[self drawRoute];
	}
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
			ChartLine* line = [LineFactory createLine:self->selectedRowStr withActivityId:self->activityId];
			if (line)
			{
				[line draw];
				[plotVC appendChartLine:line withXLabel:TIME withYLabel:self->selectedRowStr];
				[plotVC setShowMinLine:TRUE];
				[plotVC setShowMaxLine:TRUE];
				[plotVC setShowAvgLine:TRUE];
				[plotVC setTitle:self->selectedRowStr];
			}
		}
	}
	else if ([segueId isEqualToString:@SEGUE_TO_MAP_OVERVIEW])
	{
		MapOverviewViewController* mapVC = (MapOverviewViewController*)[segue destinationViewController];
		if (mapVC)
		{
			if (self->mapMode == MAP_OVERVIEW_SEGMENT_VIEW)
			{
				ActivityAttributeType value = QueryHistoricalActivityAttribute(self->activityIndex, [self->selectedRowStr UTF8String]);
				[mapVC setSegment:value withSegmentName:self->selectedRowStr];
			}
			[mapVC setActivityId:self->activityId];
			[mapVC setMode:self->mapMode];
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

#pragma mark random methods

- (void)threadStartAnimating:(id)data
{
	@synchronized(self.spinner)
	{
		self.spinner.hidden = FALSE;
		[self.spinner startAnimating];
	}
}

- (BOOL)isRecordName:(NSString*)name
{
	return (([name rangeOfString:@"Fastest"].location != NSNotFound) ||
			([name rangeOfString:@"Biggest"].location != NSNotFound) ||
			([name rangeOfString:@"Min."].location != NSNotFound) ||
			([name rangeOfString:@"Max."].location != NSNotFound));
}

#pragma mark action sheet methods

- (BOOL)showFileFormatSheet
{
	if (GetNumHistoricalActivities() > 0)
	{
		UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_FILE_FORMAT
																delegate:self
													   cancelButtonTitle:nil
												  destructiveButtonTitle:nil
													   otherButtonTitles:nil];
		if (popupQuery)
		{
			popupQuery.cancelButtonIndex = 1;
			popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;

			if (GetNumHistoricalActivityLocationPoints(self->activityIndex) > 0)
			{
				[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_GPX];
				[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_TCX];
				popupQuery.cancelButtonIndex += 2;
			}
			[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_CSV];
			[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_CANCEL];

			[popupQuery showInView:self.view];

			return TRUE;
		}
	}
	else
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_ERROR
														message:MSG_LOW_MEMORY
													   delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:BUTTON_TITLE_OK, nil];
		if (alert)
		{
			[alert show];
		}
	}
	return FALSE;
}

- (BOOL)showCloudSheet
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

#pragma mark accessor methods

- (void)setActivityIndex:(NSInteger)index
{
	self->activityIndex = index;

	CreateHistoricalActivityObject(index);
	LoadHistoricalActivitySummaryData(index);
}

#pragma mark location handling methods

- (void)drawRoute
{
	const NSInteger SCREEN_HEIGHT_IPHONE5 = 568;
	const NSInteger SCREEN_TOP = 60;
	const NSInteger BAR_HEIGHT = 50;
	
	CLLocationDegrees maxLat = -90;
	CLLocationDegrees maxLon = -180;
	CLLocationDegrees minLat = 90;
	CLLocationDegrees minLon = 180;

	size_t pointIndex = 0;
	Coordinate coordinate;
	NSInteger screenHeight = [[UIScreen mainScreen] bounds].size.height;
	CLLocation* location = nil;

	while (GetHistoricalActivityPoint(self->activityIndex, pointIndex, &coordinate))
	{
		// Draw every other point.
		if (pointIndex % 2 == 0)
		{
			location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
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

	if (pointIndex > 0)
	{
		// Set the map region.
		
		MKCoordinateRegion region;
		region.center.latitude     = (maxLat + minLat) / 2;
		region.center.longitude    = (maxLon + minLon) / 2;
		region.span.latitudeDelta  = (maxLat - minLat) * 1.1;
		region.span.longitudeDelta = (maxLon - minLon) * 1.1;
		
		[self.mapView setRegion:region];
		[self.mapView setDelegate:self];
		
		// Compute the size of the table view.

		NSInteger tableHeight = (screenHeight / 2) - BAR_HEIGHT;
		NSInteger tableTop    = (screenHeight / 2);

		// Resize the table view.
		
		CGRect tvbounds = [self.summaryTableView bounds];
		
		[self.summaryTableView setBounds:CGRectMake(0, tableTop, tvbounds.size.width, tableHeight)];
		[self.summaryTableView setFrame:CGRectMake(0, tableTop, tvbounds.size.width, tableHeight)];

		// Resize and show the map view.

		CGRect mvbounds = [self.mapView bounds];

		[self.mapView setBounds:CGRectMake(0, 0, mvbounds.size.width, tableTop)];
		self.mapView.hidden = FALSE;

		// Setup the toolbar.

		[self.toolbar setItems:self->movingToolbar animated:NO];
	}
	else
	{
		// Hide the map view.

		self.mapView.hidden = TRUE;
		
		// Resize the table view.

		CGRect tvbounds = [self.summaryTableView bounds];

		NSInteger tableHeight = 370;
		if (screenHeight == SCREEN_HEIGHT_IPHONE5)
			tableHeight = 458;

		[self.summaryTableView setBounds:CGRectMake(0, SCREEN_TOP, tvbounds.size.width, tableHeight)];
		[self.summaryTableView setFrame:CGRectMake(0, SCREEN_TOP, tvbounds.size.width, tableHeight)];

		// Setup the toolbar.

		[self.toolbar setItems:self->liftingToolbar animated:NO];
	}
}

#pragma mark button handlers

- (IBAction)onDelete:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_CAUTION
													message:MSG_DELETE_QUESTION
												   delegate:self
										  cancelButtonTitle:BUTTON_TITLE_YES
										  otherButtonTitles:BUTTON_TITLE_NO, nil];
	if (alert)
	{
		[alert show];
	}
}

- (IBAction)onExport:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* fileSites = [appDelegate getEnabledFileExportServices];
	if ([fileSites count] == 1)
	{
		self->selectedExportLocation = [fileSites objectAtIndex:0];
		[self showFileFormatSheet];
	}
	else
	{
		if ([self showCloudSheet] == FALSE)
		{
			[self showFileFormatSheet];
		}			
	}
}

- (IBAction)onEdit:(id)sender
{
	UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_EDIT
															delegate:self
												   cancelButtonTitle:nil
											  destructiveButtonTitle:nil
												   otherButtonTitles:nil];
	if (popupQuery)
	{
		popupQuery.cancelButtonIndex = 6;
		popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;

		[popupQuery addButtonWithTitle:ACTION_SHEET_TRIM_FIRST_1];
		[popupQuery addButtonWithTitle:ACTION_SHEET_TRIM_FIRST_5];
		[popupQuery addButtonWithTitle:ACTION_SHEET_TRIM_FIRST_30];
		[popupQuery addButtonWithTitle:ACTION_SHEET_TRIM_SECOND_1];
		[popupQuery addButtonWithTitle:ACTION_SHEET_TRIM_SECOND_5];
		[popupQuery addButtonWithTitle:ACTION_SHEET_TRIM_SECOND_30];

		if (QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_REPS).valid)
		{
			[popupQuery addButtonWithTitle:ACTION_SHEET_FIX_REPS];
			popupQuery.cancelButtonIndex++;
		}

		[popupQuery addButtonWithTitle:ACTION_SHEET_BUTTON_CANCEL];
		[popupQuery showInView:self.view];
	}
}

- (IBAction)onTag:(id)sender
{
	[self performSegueWithIdentifier:@SEGUE_TO_TAG_VIEW sender:self];
}

- (IBAction)onBike:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSMutableArray* fileSites = [appDelegate getBikeNames];
	if ([fileSites count] > 0)
	{
		UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:ACTION_SHEET_TITLE_BIKE
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
		}
	}
}

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

#pragma mark called when the user selects a row

- (void)handleSelectedRow:(NSIndexPath*)indexPath onTable:(UITableView*)tableView
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	NSInteger row = [indexPath row];

	self->selectedRowStr = cell.textLabel.text;

	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			break;
		case SECTION_LAP_AND_SPLIT_TIMES:
			if (row == ROW_SPLIT_TIMES)
			{
				[NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
				[self performSegueWithIdentifier:@SEGUE_TO_SPLIT_TIMES_VIEW sender:self];
			}
			else if (row == ROW_LAP_TIMES)
			{
				[NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
				[self performSegueWithIdentifier:@SEGUE_TO_LAP_TIMES_VIEW sender:self];
			}
			break;
		case SECTION_CHARTS:
			{
				[NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

				if ([appDelegate isFeatureEnabled:FEATURE_CORE_PLOT_GRAPHS])
				{
					[self performSegueWithIdentifier:@SEGUE_TO_CORE_PLOT_VIEW sender:self];
				}
				else
				{
					[self performSegueWithIdentifier:@SEGUE_TO_CHART_VIEW sender:self];
				}
			}
			break;
		case SECTION_ATTRIBUTES:
			break;
		case SECTION_SUPERLATIVES:
			if ([self superlativeHasSegue:cell])
			{
				self->mapMode = MAP_OVERVIEW_SEGMENT_VIEW;
				[NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
				[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
			}
			break;
	}

	@synchronized(self.spinner)
	{
		[self.spinner stopAnimating];
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
	}
	return @"";
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)visibleSection
{
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	switch (actualSection)
	{
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
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}

	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];
	NSInteger row = [indexPath row];
	
	switch (actualSection)
	{
		case SECTION_START_AND_END_TIME:
			switch (row)
			{
				case ROW_START_TIME:
					cell.textLabel.text = ROW_TITLE_STARTED;
					if (startTime == 0)
						cell.detailTextLabel.text = @"--";
					else
						cell.detailTextLabel.text = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:startTime]];
					break;
				case ROW_END_TIME:
					cell.textLabel.text = ROW_TITLE_FINISHED;
					if (endTime == 0)
						cell.detailTextLabel.text = @"--";
					else
						cell.detailTextLabel.text = [StringUtils formatDateAndTime:[NSDate dateWithTimeIntervalSince1970:endTime]];
					break;
			}
			break;
		case SECTION_LAP_AND_SPLIT_TIMES:
			switch (row)
			{
				case ROW_SPLIT_TIMES:
					cell.textLabel.text = ROW_TITLE_SPLIT_TIMES;
					cell.detailTextLabel.text = @"";
					break;
				case ROW_LAP_TIMES:
					cell.textLabel.text = ROW_TITLE_LAP_TIMES;
					cell.detailTextLabel.text = @"";
					break;
			}
			break;
		case SECTION_CHARTS:
			cell.textLabel.text = NSLocalizedString([self->chartTitles objectAtIndex:row], nil);
			cell.detailTextLabel.text = @"";
			break;
		case SECTION_ATTRIBUTES:
			{
				NSString* attributeName = [self->attributeNames objectAtIndex:row];
				ActivityAttributeType attr = QueryHistoricalActivityAttribute(self->activityIndex, [attributeName UTF8String]);
				if (attr.valid)
				{
					NSString* valueStr = [StringUtils formatActivityViewType:attr];
					NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];

					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", valueStr, unitsStr];
					else
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", valueStr];
				}
				else
				{
					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					cell.detailTextLabel.text = @"";
				}
			}
			break;
		case SECTION_SUPERLATIVES:
			{
				NSString* attributeName = [self->recordNames objectAtIndex:row];
				ActivityAttributeType attr = QueryHistoricalActivityAttribute(self->activityIndex, [attributeName UTF8String]);
				if (attr.valid)
				{
					NSString* valueStr = [StringUtils formatActivityViewType:attr];
					NSString* unitsStr = [StringUtils formatActivityMeasureType:attr.measureType];
					
					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					if ((unitsStr != nil) && ([valueStr isEqualToString:@VALUE_NOT_SET_STR] == false))
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", valueStr, unitsStr];
					else
						cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", valueStr];
				}
				else
				{
					cell.textLabel.text = NSLocalizedString(attributeName, nil);
					cell.detailTextLabel.text = @"";
				}
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
	NSInteger visibleSection = [indexPath section];
	NSInteger actualSection = self->sectionIndexes[visibleSection];

	switch (actualSection)
	{
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
			if ([self superlativeHasSegue:cell])
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
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

- (void)displayEmailComposerSheet
{
	NSString* subjectStr = EMAIL_TITLE;
	NSString* bodyStr = EMAIL_CONTENTS;

	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
		if (mailController)
		{
			[mailController setEditing:TRUE];
			[mailController setSubject:subjectStr];
			[mailController setMessageBody:bodyStr isHTML:NO];
			[mailController setMailComposeDelegate:self];
			
			if (self->exportedFileName)
			{
				NSString* justTheFileName = [[[NSFileManager defaultManager] displayNameAtPath:self->exportedFileName] lastPathComponent];
				NSData* myData = [NSData dataWithContentsOfFile:self->exportedFileName];
				[mailController addAttachmentData:myData mimeType:@"text/xml" fileName:justTheFileName];
			}
			
			[self presentViewController:mailController animated:YES completion:nil];
		}
	}
}

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

# pragma mark UIAlertView methods

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* message = [alertView message];

	if ([message isEqualToString:MSG_DELETE_QUESTION])
	{
		if (buttonIndex == 0)	// Yes
		{
			DeleteActivity(self->activityId);
			InitializeHistoricalActivityList();
			
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
	else if ([message isEqualToString:MSG_FIX_REPS])
	{
		if (buttonIndex == 0)	// Yes
		{
			NSString* text = [[alertView textFieldAtIndex:0] text];

			ActivityAttributeType value;
			value.value.intVal = [text intValue];
			value.valueType = TYPE_INTEGER;
			value.measureType = MEASURE_COUNT;

			SetHistoricalActivityAttribute(self->activityIndex, ACTIVITY_ATTRIBUTE_REPS_CORRECTED, value);
			SaveHistoricalActivitySummaryData(self->activityIndex);
		}
	}
}

#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString* buttonName = [actionSheet buttonTitleAtIndex:buttonIndex];

	if (buttonIndex == [actionSheet cancelButtonIndex])
	{
		return;
	}

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

	NSString* title = [actionSheet title];

	if ([title isEqualToString:ACTION_SHEET_TITLE_EXPORT])
	{
		self->selectedExportLocation = [actionSheet buttonTitleAtIndex:buttonIndex];
		[self showFileFormatSheet];
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_FILE_FORMAT])
	{
		LoadAllHistoricalActivitySensorData(self->activityIndex);

		if ([buttonName isEqualToString:ACTION_SHEET_BUTTON_GPX])
		{
			self->exportedFileName = [appDelegate exportActivity:self->activityId withFileFormat:FILE_GPX to:self->selectedExportLocation];
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_BUTTON_TCX])
		{
			self->exportedFileName = [appDelegate exportActivity:self->activityId withFileFormat:FILE_TCX to:self->selectedExportLocation];
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_BUTTON_CSV])
		{
			self->exportedFileName = [appDelegate exportActivity:self->activityId withFileFormat:FILE_CSV to:self->selectedExportLocation];
		}
		else
		{
			self->exportedFileName = nil;
		}

		if (self->exportedFileName)
		{
			if ([self->selectedExportLocation isEqualToString:@"Email"])
			{
				[self displayEmailComposerSheet];
			}
		}
		else
		{
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_ERROR
															message:EXPORT_FAILED
														   delegate:self
												  cancelButtonTitle:nil
												  otherButtonTitles:BUTTON_TITLE_OK, nil];
			if (alert)
			{
				[alert show];
			}
		}
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_MAP_TYPE])
	{
		switch (buttonIndex)
		{
			case 0:
				self->mapView.mapType = MKMapTypeStandard;
				break;
			case 1:
				self->mapView.mapType = MKMapTypeSatellite;
				break;
			case 2:
				self->mapView.mapType = MKMapTypeHybrid;
				break;
		}
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_EDIT])
	{
		uint64_t newTime = 0;
		bool trimmed = false;
		
		if ([buttonName isEqualToString:ACTION_SHEET_TRIM_FIRST_1])
		{
			newTime = ((uint64_t)self->startTime + 1) * 1000;
			trimmed = TrimActivityData(self->activityId, newTime, TRUE);
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_TRIM_FIRST_5])
		{
			newTime = ((uint64_t)self->startTime + 5) * 1000;
			trimmed = TrimActivityData(self->activityId, newTime, TRUE);
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_TRIM_FIRST_30])
		{
			newTime = ((uint64_t)self->startTime + 30) * 1000;
			trimmed = TrimActivityData(self->activityId, newTime, TRUE);
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_TRIM_SECOND_1])
		{
			newTime = ((uint64_t)self->endTime - 1) * 1000;
			trimmed = TrimActivityData(self->activityId, newTime, FALSE);				
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_TRIM_SECOND_5])
		{
			newTime = ((uint64_t)self->endTime - 5) * 1000;
			trimmed = TrimActivityData(self->activityId, newTime, FALSE);
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_TRIM_SECOND_30])
		{
			newTime = ((uint64_t)self->endTime - 30) * 1000;
			trimmed = TrimActivityData(self->activityId, newTime, FALSE);
		}
		else if ([buttonName isEqualToString:ACTION_SHEET_FIX_REPS])
		{
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ALERT_TITLE_FIX_REPS message:MSG_FIX_REPS delegate:self cancelButtonTitle:BUTTON_TITLE_OK otherButtonTitles:nil];
			if (alert)
			{
				alert.alertViewStyle = UIAlertViewStylePlainTextInput;
				
				UITextField* textField = [alert textFieldAtIndex:0];
				[textField setKeyboardType:UIKeyboardTypeNumberPad];
				[textField becomeFirstResponder];
				
				ActivityAttributeType value = QueryHistoricalActivityAttribute(activityIndex, ACTIVITY_ATTRIBUTE_REPS);
				textField.placeholder = [[NSString alloc] initWithFormat:@"%llu", value.value.intVal];
				
				[alert show];
			}
		}
		
		if (trimmed)
		{
			InitializeHistoricalActivityList();

			[self redraw];
			[self.summaryTableView reloadData];
		}
	}
	else if ([title isEqualToString:ACTION_SHEET_TITLE_BIKE])
	{
		[self->bikeButton setTitle:buttonName];
		[appDelegate setBikeForActivityId:buttonName withActivityId:self->activityId];
	}
}

#pragma mark UIGestureRecognizer methods

- (void)handleMapGesture:(UIGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateBegan)
	{
		self->mapMode = MAP_OVERVIEW_COMPLETE_ROUTE;
		[self performSegueWithIdentifier:@SEGUE_TO_MAP_OVERVIEW sender:self];
	}
}

@end
