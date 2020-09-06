// Created by Michael Simms on 3/15/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "ChartLine.h"

@interface CorePlotViewController : UIViewController<CPTPlotDataSource, CPTAxisDelegate>
{
	IBOutlet UINavigationItem* navItem;

	CPTGraphHostingView* hostingView;
	CPTXYGraph* graph;
	ChartLine*  dataForPlot;

	NSString* xLabelStr;
	NSString* yLabelStr;

	BOOL showMinLine;
	BOOL showMaxLine;
	BOOL showAvgLine;

	double minX;
	double maxX;

	double minY;
	double maxY;
	double avgY;
}

- (void)appendChartLine:(ChartLine*)line withXLabel:(NSString*)xLabel withYLabel:(NSString*)yLabel;
- (void)setShowMinLine:(BOOL)value;
- (void)setShowMaxLine:(BOOL)value;
- (void)setShowAvgLine:(BOOL)value;

- (IBAction)onHome:(id)sender;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;

@end
