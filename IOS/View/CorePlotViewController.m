// Created by Michael Simms on 3/15/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "CorePlotViewController.h"
#import "ChartPoint.h"

#define PLOT_ID_MAIN "Main Line"
#define PLOT_ID_MIN  "Min Line"
#define PLOT_ID_MAX  "Max Line"
#define PLOT_ID_AVG  "Avg Line"

@interface CorePlotViewController ()

@end

@implementation CorePlotViewController

@synthesize navItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	const NSInteger  BAR_HEIGHT = 100;
	const NSUInteger NUM_X_HASH_MARKS = 5;
	const NSUInteger NUM_Y_HASH_MARKS = 5;

	NSUInteger numPoints = [self numPointsToDraw];
	
	// Create graph from a custom theme
	self->graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];

	CGRect parentRect = self.view.bounds;
	parentRect = CGRectMake((parentRect.origin.x),
							(parentRect.origin.y + BAR_HEIGHT),
							(parentRect.size.width),
							(parentRect.size.height - BAR_HEIGHT));

	CPTGraphHostingView* hostingView = [(CPTGraphHostingView*)[CPTGraphHostingView alloc] initWithFrame:parentRect];
	hostingView.collapsesLayers      = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
	hostingView.hostedGraph          = self->graph;

	[self.view addSubview:hostingView];

	self->graph.paddingLeft   = 40.0;
	self->graph.paddingTop    = 10.0;
	self->graph.paddingRight  = 15.0;
	self->graph.paddingBottom = 40.0;

	self->minX = (double)0.0;
	self->maxX = (double)numPoints;

	self->minY = (double)0.0;
	self->maxY = (double)0.0;
	self->avgY = (double)0.0;

	// Find the extremes and the average.
	for (ChartPoint* point in self->dataForPlot->points)
	{
		double y = [point->y doubleValue];
		if (y > self->maxY)
			self->maxY = y;
		self->avgY += y;
	}
	self->avgY /= [self->dataForPlot->points count];

	// Setup plot space.
	CPTXYPlotSpace* plotSpace       = (CPTXYPlotSpace*)self->graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;
	plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:@(self->minX) length:@(self->maxX)];
	plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:@(self->minY) length:@(self->maxY)];
    
	// Axis title style.
	CPTMutableTextStyle* axisTitleStyle = [CPTMutableTextStyle textStyle];
	axisTitleStyle.color                = [CPTColor blackColor];
	axisTitleStyle.fontName             = @"Helvetica-Bold";
	axisTitleStyle.fontSize             = 12.0f;

	// Axis line style.
	CPTMutableLineStyle* axisLineStyle  = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth             = 2.0f;
	axisLineStyle.lineColor             = [[CPTColor blackColor] colorWithAlphaComponent:1];

	// Line style for the overlay lines.
	CPTMutableLineStyle* otherLineStyle = [CPTMutableLineStyle lineStyle];
	otherLineStyle.miterLimit           = 1.0f;
	otherLineStyle.lineWidth            = 1.0f;
	otherLineStyle.lineColor            = [[CPTColor redColor] colorWithAlphaComponent:1];

	// Line style for the main line.
	CPTMutableLineStyle* lineStyle  = [CPTMutableLineStyle lineStyle];
	lineStyle.miterLimit            = 1.0f;
	lineStyle.lineWidth             = 1.0f;
	lineStyle.lineColor             = [CPTColor blackColor];

	NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[numberFormatter setMaximumFractionDigits:1];

	// Setup the x axis.
	double spreadX                  = self->maxX - self->minX;
	double xHashSpacing             = spreadX / NUM_X_HASH_MARKS;
	CPTXYAxisSet* axisSet           = (CPTXYAxisSet*)self->graph.axisSet;
	CPTXYAxis* x                    = axisSet.xAxis;
	x.majorIntervalLength           = @(xHashSpacing);
    x.orthogonalPosition            = @(self->minY);
	x.minorTicksPerInterval         = 0;
	x.labelingPolicy                = CPTAxisLabelingPolicyNone;
	x.axisLineStyle                 = axisLineStyle;
	x.majorTickLength               = 10.0f;
	x.minorTickLength               = 3.0f;
	x.tickDirection                 = CPTSignNegative;
	x.title                         = self->xLabelStr;
	x.titleTextStyle                = axisTitleStyle;
	x.titleOffset                   = 10.0f;

	// Setup the y axis.
	double spreadY                  = self->maxY - self->minY;
	double yHashSpacing             = spreadY / NUM_Y_HASH_MARKS;
	CPTXYAxis* y                    = axisSet.yAxis;
	y.majorIntervalLength           = @(yHashSpacing);
	y.minorTicksPerInterval         = 1;
    y.orthogonalPosition            = @(self->minX);
	y.labelingPolicy                = CPTAxisLabelingPolicyNone;
	y.preferredNumberOfMajorTicks   = NUM_Y_HASH_MARKS;
	y.axisLineStyle                 = axisLineStyle;
	y.majorTickLength               = 10.0f;
	y.minorTickLength               = 3.0f;
	y.labelFormatter                = numberFormatter;
	CPTMutableTextStyle* newStyle   = [y.labelTextStyle mutableCopy];
	newStyle.color                  = [CPTColor redColor];
	y.labelTextStyle                = newStyle;
    NSArray* exclusionRanges        = @[[CPTPlotRange plotRangeWithLocation:@(1.99) length:@(0.02)],
                                      [CPTPlotRange plotRangeWithLocation:@(0.99) length:@(0.02)],
                                      [CPTPlotRange plotRangeWithLocation:@(3.99) length:@(0.02)]];
    y.labelExclusionRanges          = exclusionRanges;
	y.tickDirection                 = CPTSignNegative;
	y.title                         = self->yLabelStr;
	y.titleTextStyle                = axisTitleStyle;
	y.titleOffset                   = 10.0f;
	y.delegate                      = self;

	// Create a plot area.
	CPTScatterPlot* boundLinePlot   = [[CPTScatterPlot alloc] init];
	boundLinePlot.dataLineStyle     = lineStyle;
	boundLinePlot.identifier        = @PLOT_ID_MAIN;
	boundLinePlot.dataSource        = self;
	[self->graph addPlot:boundLinePlot];

	// Do a gradient.
	CPTColor* areaColor1            = [CPTColor colorWithComponentRed:0.3 green:0.3 blue:0.3 alpha:0.8];
	CPTGradient* areaGradient1      = [CPTGradient gradientWithBeginningColor:areaColor1 endingColor:[CPTColor clearColor]];
	areaGradient1.angle             = -90.0;
	CPTFill* areaGradientFill       = [CPTFill fillWithGradient:areaGradient1];
	boundLinePlot.areaFill          = areaGradientFill;
	boundLinePlot.areaBaseValue     = @(0.0);

	// Add hash marks to the x axis.
	NSMutableSet* xLabels    = [NSMutableSet setWithCapacity:NUM_X_HASH_MARKS];
	NSMutableSet* xLocations = [NSMutableSet setWithCapacity:NUM_X_HASH_MARKS];
	for (NSUInteger i = 1; i < NUM_X_HASH_MARKS; ++i)
	{
		double xValue        = self->minX + ((double)i * xHashSpacing);
		NSString* labelStr   = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)xValue];
		CPTAxisLabel* label  = [[CPTAxisLabel alloc] initWithText:labelStr textStyle:x.labelTextStyle];

		CGFloat location     = xValue + 1;
		label.tickLocation   = @(location);
		label.offset         = x.majorTickLength;

		[xLabels addObject:label];
		[xLocations addObject:[NSNumber numberWithFloat:location]];
	}
	//x.axisLabels = xLabels;
	x.majorTickLocations = xLocations;

	// Add hash marks to the y axis
	NSMutableSet* yLabels    = [NSMutableSet setWithCapacity:NUM_Y_HASH_MARKS];
	NSMutableSet* yLocations = [NSMutableSet setWithCapacity:NUM_Y_HASH_MARKS];
	for (NSUInteger i = 1; i < NUM_Y_HASH_MARKS; ++i)
	{
		double yValue        = self->minY + ((double)i * yHashSpacing);
		NSString* labelStr   = [[NSString alloc] initWithFormat:@"%.1f", yValue];
		CPTAxisLabel* label  = [[CPTAxisLabel alloc] initWithText:labelStr textStyle:y.labelTextStyle];

		CGFloat location     = yValue;
		label.tickLocation   = @(location);
		label.offset         = y.majorTickLength;

		[yLabels addObject:label];
		[yLocations addObject:[NSNumber numberWithFloat:location]];
	}
	y.axisLabels = yLabels;
	y.majorTickLocations = yLocations;

	// Average line.
	if (self->showAvgLine)
	{
		CPTScatterPlot* dataSourceLinePlot = [[CPTScatterPlot alloc] init];
		dataSourceLinePlot.dataLineStyle   = otherLineStyle;
		dataSourceLinePlot.identifier      = @PLOT_ID_AVG;
		dataSourceLinePlot.dataSource      = self;
		[self->graph addPlot:dataSourceLinePlot];
	}

	// Minimum line.
	if (self->showMinLine)
	{
		CPTScatterPlot* dataSourceLinePlot = [[CPTScatterPlot alloc] init];
		dataSourceLinePlot.dataLineStyle   = otherLineStyle;
		dataSourceLinePlot.identifier      = @PLOT_ID_MIN;
		dataSourceLinePlot.dataSource      = self;
		[self->graph addPlot:dataSourceLinePlot];
	}

	// Maximum line.
	if (self->showMaxLine)
	{
		CPTScatterPlot* dataSourceLinePlot = [[CPTScatterPlot alloc] init];
		dataSourceLinePlot.dataLineStyle   = otherLineStyle;
		dataSourceLinePlot.identifier      = @PLOT_ID_MAX;
		dataSourceLinePlot.dataSource      = self;
		[self->graph addPlot:dataSourceLinePlot];
	}

	self->graph.plotAreaFrame.masksToBorder = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (NSUInteger)numPointsToDraw
{
	if (self->dataForPlot)
	{
		return ([self->dataForPlot->points count]);
	}
	return 0;
}

#pragma mark CPTPlotDataSource methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot*)plot
{
	return [self numPointsToDraw];
}

- (NSNumber*)numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	if ([plot.identifier isEqual:@PLOT_ID_MAIN])
	{
		if (self->dataForPlot)
		{
			NSString* key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
			return [[self->dataForPlot->points objectAtIndex:(index)] valueForKey:key];
		}
	}
	else if ([plot.identifier isEqual:@PLOT_ID_MIN])
	{
        if (fieldEnum == CPTScatterPlotFieldX)
        {
			return (NSDecimalNumber*)[NSDecimalNumber numberWithDouble:index];
        }
        else
        {
			return [[NSNumber alloc] initWithDouble:self->minY];
        }
	}
	else if ([plot.identifier isEqual:@PLOT_ID_MAX])
	{
        if (fieldEnum == CPTScatterPlotFieldX)
        {
			return (NSDecimalNumber*)[NSDecimalNumber numberWithDouble:index];
        }
        else
        {
			return [[NSNumber alloc] initWithDouble:self->maxY];
        }
	}
	else if ([plot.identifier isEqual:@PLOT_ID_AVG])
	{
        if (fieldEnum == CPTScatterPlotFieldX)
        {
			return (NSDecimalNumber*)[NSDecimalNumber numberWithDouble:index];
        }
        else
        {
			return [[NSNumber alloc] initWithDouble:self->avgY];
        }
	}
	return [[NSNumber alloc] initWithInt:0];
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

#pragma mark accessor methods

- (void)appendChartLine:(ChartLine*)line withXLabel:(NSString*)xLabel withYLabel:(NSString*)yLabel;
{
	self->dataForPlot = line;
	self->xLabelStr = xLabel;
	self->yLabelStr = yLabel;
}

- (void)setShowMinLine:(BOOL)value
{
	self->showMinLine = value;
}

- (void)setShowMaxLine:(BOOL)value
{
	self->showMaxLine = value;
}

- (void)setShowAvgLine:(BOOL)value
{
	self->showAvgLine = value;
}

#pragma mark button handlers

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

@end
