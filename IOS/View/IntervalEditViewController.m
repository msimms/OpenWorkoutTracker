// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "IntervalEditViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "UnitConversionFactors.h"

#define TITLE                                    NSLocalizedString(@"Interval Workout", nil)

#define ALERT_TITLE_DISTANCE_INTERVAL            NSLocalizedString(@"New Distance Interval", nil)
#define ALERT_MSG_DISTANCE_INTERVAL              NSLocalizedString(@"Enter the distance", nil)
#define ALERT_TITLE_TIME_INTERVAL                NSLocalizedString(@"New Time Interval", nil)
#define ALERT_MSG_TIME_INTERVAL                  NSLocalizedString(@"Enter the time (in seconds)", nil)
#define ALERT_TITLE_SET_INTERVAL                 NSLocalizedString(@"New Set Interval", nil)
#define ALERT_MSG_SET_INTERVAL                   NSLocalizedString(@"Enter the number of sets", nil)
#define ALERT_TITLE_REP_INTERVAL                 NSLocalizedString(@"New Ret Interval", nil)
#define ALERT_MSG_REP_INTERVAL                   NSLocalizedString(@"Enter the number of reps", nil)

#define ACTION_SHEET_TITLE_ADD_INTERVAL          NSLocalizedString(@"Add a New Interval", nil)
#define ACTION_SHEET_TITLE_SELECT_DISTANCE_UNITS NSLocalizedString(@"Measure distance in which units?", nil)

#define UNSPECIFIED_INTERVAL                     NSLocalizedString(@"Wait for screen touch", nil)
#define DISTANCE_INTERVAL                        NSLocalizedString(@"Distance Interval", nil)
#define TIME_INTERVAL                            NSLocalizedString(@"Time Interval", nil)
#define SET_INTERVAL                             NSLocalizedString(@"Set Interval", nil)
#define REP_INTERVAL                             NSLocalizedString(@"Rep Interval", nil)

@interface IntervalEditViewController ()

@end

@implementation IntervalEditViewController

@synthesize intervalTableView;
@synthesize chartView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = TITLE;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self drawChart];
	[super viewDidAppear:animated];
	[self->intervalTableView reloadData];
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

#pragma mark chart drawing methods

- (void)drawChart
{
	// Check for dark mode.
	bool darkModeEnabled = [self isDarkModeEnabled];

	// Create the host view.
	self->hostingView = [[CPTGraphHostingView alloc] initWithFrame:self.chartView.bounds];
	[self->hostingView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	[self.chartView addSubview:self->hostingView];

	// Create the graph from a custom theme.
	self->graph = [[CPTXYGraph alloc] initWithFrame:self->hostingView.bounds];
	[self->hostingView setHostedGraph:self->graph];

	// Set graph padding.
	self->graph.plotAreaFrame.paddingTop    = 20.0f;
	self->graph.plotAreaFrame.paddingRight  = 20.0f;
	self->graph.plotAreaFrame.paddingBottom = 20.0f;
	self->graph.plotAreaFrame.paddingLeft   = 20.0f;

	// Axis set.
	CPTXYAxisSet* axisSet = (CPTXYAxisSet*)self->graph.axisSet;
	CPTXYAxis* x          = axisSet.xAxis;
	CPTXYAxis* y          = axisSet.yAxis;

	// Axis min and max values.
	self->minX = (double)0.0;
	self->maxX = (double)1.0; // distance, in 100s of meters
	self->minY = (double)0.0; // minimum intensity/pace
	self->maxY = (double)1.0; // maximum intensity/pace
	IntervalWorkoutSegment segment;

	size_t segmentIndex = 0;
	while (GetIntervalWorkoutSegment([self->workoutId UTF8String], segmentIndex++, &segment))
	{
		switch (segment.units)
		{
		case INTERVAL_UNIT_SECONDS:
			break;
		case INTERVAL_UNIT_METERS:
			self->maxX += segment.distance / 100.0;
			break;
		case INTERVAL_UNIT_KILOMETERS:
			self->maxX += segment.distance * 10.0;
			break;
		case INTERVAL_UNIT_FEET:
			self->maxX += segment.distance * 0.003048;
			break;
		case INTERVAL_UNIT_YARDS:
			self->maxX += segment.distance * 0.009144;
			break;
		case INTERVAL_UNIT_MILES:
			self->maxX += segment.distance * 16.09344;
			break;
		}

		if (segment.pace > self->maxY)
		{
			self->maxY = segment.pace;
		}
		if (segment.power > self->maxY)
		{
			self->maxY = segment.power;
		}
	}

	// Setup plot space.
	CPTXYPlotSpace* plotSpace       = (CPTXYPlotSpace*)self->graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = NO;
	plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:@(self->minX) length:@(self->maxX)];
	plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:@(self->minY) length:@(self->maxY)];
	
	// Axis title style.
	CPTMutableTextStyle* axisTitleStyle = [CPTMutableTextStyle textStyle];
	axisTitleStyle.color                = darkModeEnabled ? [CPTColor whiteColor] : [CPTColor blackColor];
	axisTitleStyle.fontName             = @"Helvetica-Bold";
	axisTitleStyle.fontSize             = 12.0f;

	// Axis line style.
	CPTMutableLineStyle* axisLineStyle = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth            = 1.0f;
	axisLineStyle.lineColor            = darkModeEnabled ? [[CPTColor whiteColor] colorWithAlphaComponent:1] : [[CPTColor blackColor] colorWithAlphaComponent:1];

	// Axis configuration.
	double spreadX          = self->maxX - self->minX;
	double xHashSpacing     = spreadX / segmentIndex;
	x.orthogonalPosition    = @(self->minY);
	x.majorIntervalLength   = @(xHashSpacing);
	x.minorTicksPerInterval = 0;
	x.labelingPolicy        = CPTAxisLabelingPolicyNone;
	x.titleTextStyle        = axisTitleStyle;
	x.titleOffset           = 5.0f;
	y.orthogonalPosition    = @(self->minX);
	y.title                 = @"Pace";
	y.delegate              = self;
	y.labelingPolicy        = CPTAxisLabelingPolicyNone;
	y.titleTextStyle        = axisTitleStyle;
	y.titleOffset           = 5.0f;

	// Create the plot.
	CPTBarPlot* plot     = [[CPTBarPlot alloc] init];
	plot.dataSource      = self;
	plot.delegate        = self;
	plot.barWidth        = [NSNumber numberWithInteger:xHashSpacing];
	plot.barOffset       = [NSNumber numberWithInteger:0];
	plot.barCornerRadius = 5.0;

	[self->graph addPlot:plot];
}

#pragma mark helper methods

- (void)promptForDistance:(IntervalUnit)unit withSegment:(IntervalWorkoutSegment)segment
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:ALERT_TITLE_DISTANCE_INTERVAL message:ALERT_MSG_DISTANCE_INTERVAL preferredStyle:UIAlertControllerStyleAlert];

	[alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		IntervalWorkoutSegment segment2 = segment;
		uint32_t valueFromUser = [[alertController.textFields.firstObject text] intValue];

		switch (unit)
		{
		case INTERVAL_UNIT_SECONDS:
			segment2.duration = valueFromUser;
			segment2.units = INTERVAL_UNIT_SECONDS;
			break;
		case INTERVAL_UNIT_METERS:
		case INTERVAL_UNIT_KILOMETERS:
		case INTERVAL_UNIT_FEET:
		case INTERVAL_UNIT_YARDS:
		case INTERVAL_UNIT_MILES:
			segment2.distance = valueFromUser;
			segment2.units = unit;
			break;
		}

		if (CreateNewIntervalWorkoutSegment([self->workoutId UTF8String], segment2))
		{
			[self reload];
		}
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark button handlers

- (IBAction)onAddInterval:(id)sender
{
	__block IntervalWorkoutSegment segment;
	segment.segmentId = 0;  // Database identifier for this segment
	segment.sets = 0;       // Number of sets
	segment.reps = 0;       // Number of reps
	segment.duration = 0;   // Duration, if applicable, in seconds
	segment.distance = 0.0; // Distance, if applicable, in meters
	segment.pace = 0.0;     // Pace, if applicable, in meters/second
	segment.power = 0.0;    // Power, if applicable, in percentage of FTP

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:ACTION_SHEET_TITLE_ADD_INTERVAL
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];
	[alertController addAction:[UIAlertAction actionWithTitle:DISTANCE_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:nil
																				  message:ACTION_SHEET_TITLE_SELECT_DISTANCE_UNITS
																		   preferredStyle:UIAlertControllerStyleActionSheet];

		// Add a cancel option. Add the cancel option to the top so that it's easy to find.
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_METERS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self promptForDistance:INTERVAL_UNIT_METERS withSegment:segment];
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_KILOMETERS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self promptForDistance:INTERVAL_UNIT_KILOMETERS withSegment:segment];
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_FEET style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self promptForDistance:INTERVAL_UNIT_FEET withSegment:segment];
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_YARDS style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self promptForDistance:INTERVAL_UNIT_YARDS withSegment:segment];
		}]];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_MILES style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			[self promptForDistance:INTERVAL_UNIT_MILES withSegment:segment];
		}]];

		// Show the action sheet.
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:TIME_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{		
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_TIME_INTERVAL
																				  message:ALERT_MSG_TIME_INTERVAL
																		   preferredStyle:UIAlertControllerStyleAlert];

		[alertController2 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			segment.duration = [[alertController2.textFields.firstObject text] intValue];
			if (CreateNewIntervalWorkoutSegment([self->workoutId UTF8String], segment))
			{
				[self reload];			
			}
		}]];

		// Show the action sheet.
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:SET_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_SET_INTERVAL
																				  message:ALERT_MSG_SET_INTERVAL
																		   preferredStyle:UIAlertControllerStyleAlert];

		[alertController2 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			segment.sets = [[alertController2.textFields.firstObject text] intValue];
			if (CreateNewIntervalWorkoutSegment([self->workoutId UTF8String], segment))
			{
				[self reload];			
			}
		}]];

		// Show the action sheet.
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:REP_INTERVAL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UIAlertController* alertController2 = [UIAlertController alertControllerWithTitle:ALERT_TITLE_REP_INTERVAL
																				  message:ALERT_MSG_REP_INTERVAL
																		   preferredStyle:UIAlertControllerStyleAlert];

		[alertController2 addTextFieldWithConfigurationHandler:^(UITextField* textField) { textField.keyboardType = UIKeyboardTypeNumberPad; }];
		[alertController2 addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
		{
			segment.reps = [[alertController2.textFields.firstObject text] intValue];
			if (CreateNewIntervalWorkoutSegment([self->workoutId UTF8String], segment))
			{
				[self reload];
			}
		}]];

		// Show the action sheet.
		[self presentViewController:alertController2 animated:YES completion:nil];
	}]];

	// Show the action sheet.
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark accessor methods

- (void)setWorkoutId:(NSString*)workoutId
{
	self->workoutId = workoutId;
}

#pragma mark random methods

- (void)reload
{
	InitializeIntervalWorkoutList();
	[self->intervalTableView reloadData];	
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
			return GetNumSegmentsForIntervalWorkout([self->workoutId UTF8String]);
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
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}

	UIListContentConfiguration* content = [cell defaultContentConfiguration];
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	switch (section)
	{
		case 0:
			{
				IntervalWorkoutSegment segment;

				if (GetIntervalWorkoutSegment([self->workoutId UTF8String], row, &segment))
				{
					switch (segment.units)
					{
					case INTERVAL_UNIT_SECONDS:
						[content setText:[NSString stringWithFormat:@"%zd. %u second(s)", row + 1, segment.duration]];
						break;
					case INTERVAL_UNIT_METERS:
						[content setText:[NSString stringWithFormat:@"%zd. %0.2f meter(s)", row + 1, segment.distance]];
						break;
					case INTERVAL_UNIT_KILOMETERS:
						[content setText:[NSString stringWithFormat:@"%zd. %0.2f kilometer(s)", row + 1, segment.distance]];
						break;
					case INTERVAL_UNIT_FEET:
						[content setText:[NSString stringWithFormat:@"%zd. %0.2f feet", row + 1, segment.distance]];
						break;
					case INTERVAL_UNIT_YARDS:
						[content setText:[NSString stringWithFormat:@"%zd. %0.2f yard(s)", row + 1, segment.distance]];
						break;
					case INTERVAL_UNIT_MILES:
						 [content setText:[NSString stringWithFormat:@"%zd. %0.2f mile(s)", row + 1, segment.distance]];
						break;
					}
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
	cell.accessoryType = UITableViewCellAccessoryNone;
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
		if (DeleteIntervalWorkoutSegment([self->workoutId UTF8String], [indexPath row]))
		{
			InitializeIntervalWorkoutList();
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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

#pragma mark CPTPlotDataSource methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot*)plot
{
	return self->maxX;
}

- (NSNumber*)numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	switch (fieldEnum)
	{
		case CPTScatterPlotFieldX:
			return [[NSNumber alloc] initWithInt:(int)index];
		case CPTScatterPlotFieldY:
			{
				IntervalWorkoutSegment segment;

				if (GetIntervalWorkoutSegment([self->workoutId UTF8String], (size_t)index, &segment))
				{
				}
				return [[NSNumber alloc] initWithInt:(int)1.0];
			}
		default:
			break;
	}
	return nil;
}

#pragma mark CPTAxisDelegate methods

- (BOOL)axisShouldRelabel:(CPTAxis*)axis
{
	return YES;
}

- (void)axisDidRelabel:(CPTAxis*)axis
{
}

- (BOOL)axis:(CPTAxis*)axis shouldUpdateAxisLabelsAtLocations:(NSSet*)locations
{
	return YES;
}

- (BOOL)axis:(CPTAxis*)axis shouldUpdateMinorAxisLabelsAtLocations:(NSSet*)locations
{
	return NO;
}

@end
