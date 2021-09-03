// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"
#import "CorePlot.h"

@interface WorkoutDetailsViewController : CommonViewController<CPTBarPlotDataSource, CPTBarPlotDelegate>
{
	IBOutlet UIView* chartView;

	CPTGraphHostingView* hostingView;
	CPTGraph* graph;

	NSDictionary* workoutDetails;

	NSString* exportedFileName; // Name of the exported file
	NSString* selectedExportService; // Describes where the user wants to save the file: "Email", "iCloud", etc.

	double minX;
	double maxX;
	double minY;
	double maxY;
}

- (IBAction)onExport:(id)sender;
- (void)setWorkoutDetails:(NSMutableDictionary*)details;

@property (nonatomic, retain) IBOutlet UIView* chartView;


@end
