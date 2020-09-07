// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

#import "CorePlot-CocoaTouch.h"

@interface WorkoutDetailsViewController : CommonViewController<CPTBarPlotDataSource, CPTBarPlotDelegate>
{
	IBOutlet UIToolbar* toolbar;

	CPTGraphHostingView* hostingView;
	CPTGraph* graph;

	NSMutableDictionary* workoutDetails;

	double minX;
	double maxX;
	double minY;
	double maxY;
}

- (IBAction)onExport:(id)sender;
- (void)setWorkoutDetails:(NSMutableDictionary*)details;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;

@end
