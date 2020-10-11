// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "WorkoutDetailsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"

#define TITLE NSLocalizedString(@"Workout", nil)
#define ACTION_SHEET_BUTTON_ZWO NSLocalizedString(@"ZWO File", nil)

#define EMAIL_TITLE             NSLocalizedString(@"Workout Data", nil)
#define EMAIL_CONTENTS          NSLocalizedString(@"The data file is attached.", nil)

@interface WorkoutDetailsViewController ()

@end

@implementation WorkoutDetailsViewController

@synthesize toolbar;
@synthesize chartView;

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
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	[self drawChart];
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
	[self->hostingView setFrame:[self.chartView bounds]];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
}

- (void)drawChart
{	
	// Create the host view.
	self->hostingView = [[CPTGraphHostingView alloc] initWithFrame:self.chartView.bounds];
	[self->hostingView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	[self.chartView addSubview:self->hostingView];

	// Create the graph from a custom theme.
	self->graph = [[CPTXYGraph alloc] initWithFrame:self->hostingView.bounds];
	[self->hostingView setHostedGraph:self->graph];

	// Set graph padding and theme.
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
	self->maxX = (double)1.0;
	self->minY = (double)0.0; // minimum intensity
	self->maxY = (double)10.0; // maximum intensity
	if (self->workoutDetails)
	{
		self->maxX = (double)([workoutDetails[@"duration"] doubleValue]);

		if (self->maxX == 0) // Duration not specified, use distance instead.
		{
			self->maxX = (double)([workoutDetails[@"distance"] doubleValue] / 100.0);
			x.title = @"Distance";
		}
		else
		{
			x.title = @"Duration";
		}
		
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
	axisTitleStyle.color                = [CPTColor blackColor];
	axisTitleStyle.fontName             = @"Helvetica-Bold";
	axisTitleStyle.fontSize             = 12.0f;

	// Axis line style.
	CPTMutableLineStyle* axisLineStyle = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth            = 1.0f;
	axisLineStyle.lineColor            = [[CPTColor blackColor] colorWithAlphaComponent:1];

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
			[super displayEmailComposerSheet:EMAIL_TITLE withBody:EMAIL_CONTENTS withFileName:self->exportedFileName withMimeType:@"text/xml" withDelegate:self];
		}
		else
		{
			[super showOneButtonAlert:STR_ERROR withMsg:MSG_EXPORT_FAILED];
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
	
	for (NSString* fileExportService in fileExportServices)
	{
		[alertController addAction:[UIAlertAction actionWithTitle:fileExportService style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			self->selectedExportLocation = fileExportService;
			[self showFileFormatSheet];
		}]];
	}
	[alertController addAction:[UIAlertAction actionWithTitle:STR_CANCEL style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
	}]];

	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark button handlers

- (IBAction)onExport:(id)sender
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSMutableArray* fileExportServices = [appDelegate getEnabledFileExportServices];

	if ([fileExportServices count] == 1)
	{
		self->selectedExportLocation = [fileExportServices objectAtIndex:0];
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

#pragma mark CPTPlotDataSource methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot*)plot
{
	NSUInteger numPaceBlocks = 0;
	NSDictionary* intervals = [self->workoutDetails objectForKey:@"intervals"];

	// Sum up the total number of intervals as well as their corresponding recoveries
	// to get the total number of pace blocks.
	for (NSDictionary* interval in intervals)
	{
		NSUInteger numRepeats = (NSUInteger)([interval[@"repeat"] integerValue]);
		numPaceBlocks += numRepeats;

		if ([interval[@"recovery pace"] doubleValue] > (double)0.1)
			numPaceBlocks += numRepeats;
	}
	return numPaceBlocks;
}

- (NSNumber*)numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	if (fieldEnum == CPTScatterPlotFieldX)
	{
		return [[NSNumber alloc] initWithInt:(int)index];
	}
	else if (fieldEnum == CPTScatterPlotFieldY)
	{
		NSDictionary* intervals = [self->workoutDetails objectForKey:@"intervals"];
		NSUInteger paceBlockIndex = 0;

		for (NSDictionary* interval in intervals)
		{
			if (index == paceBlockIndex++)
				return interval[@"pace"];
			if ([interval[@"recovery pace"] doubleValue] > (double)0.1)
			{
				if (index == paceBlockIndex++)
					return interval[@"recovery pace"] ;
			}
		}
	}
	return 0;
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
