// Created by Michael Simms on 9/22/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "MapOverviewViewController.h"
#import "MapViewController.h"

@interface StaticSummaryViewController : MapViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
	IBOutlet UINavigationItem* navItem;
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITableView* summaryTableView;
	IBOutlet UIBarButtonItem* deleteButton;
	IBOutlet UIBarButtonItem* exportButton;
	IBOutlet UIBarButtonItem* editButton;
	IBOutlet UIBarButtonItem* mapButton;
	IBOutlet UIBarButtonItem* bikeButton;
	IBOutlet UIBarButtonItem* tagsButton;
	IBOutlet UIActivityIndicatorView* spinner;

	NSMutableArray* movingToolbar;
	NSMutableArray* liftingToolbar;

	NSMutableArray* attributeNames;
	NSMutableArray* recordNames;
	NSMutableArray* timeSection1RowNames;
	NSMutableArray* timeSection2RowNames;
	NSArray* chartTitles;

	NSInteger attributeIndex;

	NSString* exportedFileName;
	NSString* selectedExportLocation;
	NSString* selectedRowStr;

	NSString* activityId;

	time_t startTime;
	time_t endTime;

	uint8_t sectionIndexes[8];
	uint8_t numVisibleSections;

	bool hasLocationData;
	bool hasAccelerometerData;
	bool hasHeartRateData;
	bool hasCadenceData;
	bool hasPowerData;
	bool preferPaceOverSpeed;

	MapOverviewMode mapMode;
}

- (IBAction)onDelete:(id)sender;
- (IBAction)onExport:(id)sender;
- (IBAction)onEdit:(id)sender;
- (IBAction)onTag:(id)sender;
- (IBAction)onBike:(id)sender;
- (IBAction)onHome:(id)sender;

- (void)setActivityId:(NSString*)activityId;
- (void)drawRoute;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;
@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* summaryTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* deleteButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* exportButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* editButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* mapButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* bikeButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* tagsButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* tableTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* tableHeightConstraint;

@end
