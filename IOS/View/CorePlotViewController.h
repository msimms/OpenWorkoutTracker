// Created by Michael Simms on 3/15/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"
#import "CorePlot.h"
#import "ChartLine.h"

@interface CorePlotViewController : CommonViewController <CPTPlotDataSource, CPTAxisDelegate>
{
	IBOutlet UINavigationItem* navItem;
	IBOutlet UIView* chartView;
	IBOutlet UIBarButtonItem* homeButton;

	CPTGraphHostingView* hostingView;
	CPTXYGraph* graph;
	ChartLine*  dataForPlot;

	NSString* xLabelStr;
	NSString* yLabelStr;

	BOOL showMinLine;
	BOOL showMaxLine;
	BOOL showAvgLine;
	CPTColor* lineColor;

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
- (void)setLineColor:(CPTColor*)color;

- (IBAction)onHome:(id)sender;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;
@property (nonatomic, retain) IBOutlet UIView* chartView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* homeButton;

@end
