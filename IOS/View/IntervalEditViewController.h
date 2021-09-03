// Created by Michael Simms on 6/1/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"
#import "CorePlot.h"

@interface IntervalEditViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, CPTBarPlotDataSource, CPTBarPlotDelegate>
{
	IBOutlet UITableView* intervalTableView;
	IBOutlet UIView* chartView;

	CPTGraphHostingView* hostingView;
	CPTGraph* graph;

	double minX;
	double maxX;
	double minY;
	double maxY;

	NSString* workoutId;
}

- (IBAction)onAddInterval:(id)sender;

- (void)setWorkoutId:(NSString*)workoutId;

@property (nonatomic, retain) IBOutlet UITableView* intervalTableView;
@property (nonatomic, retain) IBOutlet UIView* chartView;

@end
