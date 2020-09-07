// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "WorkoutDetailsViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "Segues.h"

#define TITLE NSLocalizedString(@"Workout", nil)

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

	// Axis min and max values.
	self->minX = (double)0.0;
	self->maxX = (double)[self numPointsOnXAxis]; // duration of the workout, in seconds
	self->minY = (double)0.0;
	self->maxY = (double)10.0; // maximum intensity

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

	// Axis data.
	CPTXYAxisSet* axisSet = (CPTXYAxisSet*)self->graph.axisSet;
	CPTXYAxis* x          = axisSet.xAxis;
    x.orthogonalPosition  = @(self->minY);
	x.title               = @"Duration";
	CPTXYAxis* y          = axisSet.yAxis;
    y.orthogonalPosition  = @(self->minX);
	y.title               = @"";
	y.delegate            = self;

	// Create the plot.
	CPTBarPlot* plot     = [[CPTBarPlot alloc] init];
	plot.dataSource      = self;
	plot.delegate        = self;
	plot.barWidth        = [NSNumber numberWithInteger:5];
	plot.barOffset       = [NSNumber numberWithInteger:10];
	plot.barCornerRadius = 5.0;

	[self->graph addPlot:plot];
}

- (NSUInteger)numPointsOnXAxis
{
	if (self->workoutDetails)
	{
		return (NSUInteger)([workoutDetails[@"duration"] integerValue]);
	}
	return 0;
}

#pragma mark button handlers

- (IBAction)onExport:(id)sender
{
}

#pragma mark accessor methods

- (void)setWorkoutDetails:(NSMutableDictionary*)details
{
	self->workoutDetails = details;
}

#pragma mark CPTPlotDataSource methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot*)plot
{
	return [self numPointsOnXAxis];
}

- (NSNumber*)numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	return [[NSNumber alloc] initWithInt:2];
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
