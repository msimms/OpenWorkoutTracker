// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "WorkoutDetailsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"

#define ACTION_SHEET_BUTTON_ZWO NSLocalizedString(@"ZWO File", nil)

#define EMAIL_TITLE             NSLocalizedString(@"Workout Data", nil)
#define EMAIL_CONTENTS          NSLocalizedString(@"The data file is attached.", nil)

@interface WorkoutDetailsViewController ()

@end

@implementation WorkoutDetailsViewController

@synthesize chartView;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = STR_WORKOUT;
}

- (void)viewDidAppear:(BOOL)animated
{
	[self drawChart];
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
	[self->hostingView setFrame:[self.chartView bounds]];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
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
	self->maxY = (double)10.0; // maximum intensity/pace
	if (self->workoutDetails)
	{
		self->maxX = (double)([self->workoutDetails[@"distance"] doubleValue] / 100.0);
		x.title = @"Distance";

		NSDictionary* intervals = [self->workoutDetails objectForKey:@"intervals"];
		for (NSDictionary* interval in intervals)
		{
			double pace = (double)([interval[@"pace"] doubleValue]);

			if (pace > self->maxY)
				self->maxY = pace;
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
	double xHashSpacing     = spreadX / [workoutDetails[@"num intervals"] integerValue];
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

#pragma mark action sheet methods

- (void)showFileFormatSheet
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:STR_EXPORT
																	  preferredStyle:UIAlertControllerStyleActionSheet];

	// Add a cancel option. Add the cancel option to the top so that it's easy to find.
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}]];

	// Add an option to export as a ZWO file.
	[alertController addAction:[UIAlertAction actionWithTitle:ACTION_SHEET_BUTTON_ZWO style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
		self->exportedFileName = [appDelegate exportWorkoutWithId:self->workoutDetails[@"id"]];

		if (self->exportedFileName)
		{
			if ([self->selectedExportService isEqualToString:@"Email"])
			{
				[super displayEmailComposerSheet:EMAIL_TITLE withBody:EMAIL_CONTENTS withFileName:self->exportedFileName withMimeType:@"text/xml" withDelegate:self];
			}
			else
			{
				AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

				if ([appDelegate exportFileToCloudService:self->exportedFileName toServiceNamed:self->selectedExportService])
				{
					[super showOneButtonAlert:STR_EXPORT withMsg:STR_EXPORT_SUCCEEDED];
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
	}]];

	// Show the menu.
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showCloudSheet:(NSMutableArray*)fileExportServices
{	
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
																			 message:STR_EXPORT
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

#pragma mark button handlers

- (IBAction)onExport:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSMutableArray* fileExportServices = [appDelegate getEnabledFileExportServices];

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

#pragma mark accessor methods

- (void)setWorkoutDetails:(NSMutableDictionary*)details
{
	self->workoutDetails = details;
}

#pragma mark 

- (NSNumber*)paceAtDistance:(double)distanceInMeters
{
	NSDictionary* intervals = [self->workoutDetails objectForKey:@"intervals"];
	double currentDistanceInMeters = (double)0.0;

	// Which interval are we in when at the given distance?
	for (NSDictionary* interval in intervals)
	{
		NSUInteger numRepeats = (NSUInteger)([interval[@"repeat"] integerValue]);

		double intervalDistance = [interval[@"distance"] doubleValue];
		double recoveryDistance = [interval[@"recoveryDistance"] doubleValue];

		// For each time this interval is repeated.
		for (NSUInteger repeatIndex = 0; repeatIndex < numRepeats; ++repeatIndex)
		{
			// Main interval.
			currentDistanceInMeters += intervalDistance;
			if (currentDistanceInMeters >= distanceInMeters)
			{
				NSNumber* pace = interval[@"pace"];

				if ([pace doubleValue] < (double)0.1)
				{
					return [[NSNumber alloc] initWithDouble:self->maxY * 0.25];
				}
				return pace;
			}

			// Recovery interval.
			currentDistanceInMeters += recoveryDistance;
			if (currentDistanceInMeters >= distanceInMeters)
			{
				return interval[@"recovery pace"];
			}
		}
	}
	
	// Nothing found, return zero.
	return [[NSNumber alloc] initWithDouble:0.0];
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
			double distanceInMeters = (double)index * 100.0; // convert back to meters
			return [self paceAtDistance:distanceInMeters];
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
