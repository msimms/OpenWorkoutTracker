// Created by Michael Simms on 9/7/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "ActivityViewController.h"
#import "CrumbPath.h"
#import "CrumbPathRenderer.h"

@interface MappedActivityViewController : ActivityViewController <MKMapViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UIBarButtonItem* mapButton;

	IBOutlet UISwipeGestureRecognizer* leftSwipe;

	IBOutlet MKMapView* mapView;
	
	IBOutlet UILabel* value_Large;
	IBOutlet UILabel* title_Large;
	IBOutlet UILabel* units_Large;
	
	IBOutlet UILabel* value1;
	IBOutlet UILabel* title1;
	IBOutlet UILabel* units1;

	IBOutlet UILabel* value2;
	IBOutlet UILabel* title2;
	IBOutlet UILabel* units2;
	
	IBOutlet UILabel* value3;
	IBOutlet UILabel* title3;
	IBOutlet UILabel* units3;
	
	IBOutlet UILabel* value4;
	IBOutlet UILabel* title4;
	IBOutlet UILabel* units4;

	NSMutableArray* routePoints;
	MKPolyline* route;

    CrumbPath* crumbs;
    CrumbPathRenderer* crumbRenderer;
}

- (void)setUIForStartedActivity;
- (void)setUIForStoppedActivity;
- (void)setUIForPausedActivity;
- (void)setUIForResumedActivity;

- (void)locationUpdated:(NSNotification*)notification;
- (void)addNewLocation:(CLLocation*)newLocation;

- (void)onRefreshTimer:(NSTimer*)timer;

- (IBAction)onMap:(id)sender;

@property (nonatomic, retain) IBOutlet UIBarButtonItem* mapButton;

@property (nonatomic, retain) IBOutlet UISwipeGestureRecognizer* leftSwipe;

@property (nonatomic, retain) IBOutlet MKMapView* mapView;

@property (nonatomic, retain) IBOutlet UILabel* value_Large;
@property (nonatomic, retain) IBOutlet UILabel* title_Large;
@property (nonatomic, retain) IBOutlet UILabel* units_Large;

@property (nonatomic, retain) IBOutlet UILabel* value1;
@property (nonatomic, retain) IBOutlet UILabel* title1;
@property (nonatomic, retain) IBOutlet UILabel* units1;

@property (nonatomic, retain) IBOutlet UILabel* value2;
@property (nonatomic, retain) IBOutlet UILabel* title2;
@property (nonatomic, retain) IBOutlet UILabel* units2;

@property (nonatomic, retain) IBOutlet UILabel* value3;
@property (nonatomic, retain) IBOutlet UILabel* title3;
@property (nonatomic, retain) IBOutlet UILabel* units3;

@property (nonatomic, retain) IBOutlet UILabel* value4;
@property (nonatomic, retain) IBOutlet UILabel* title4;
@property (nonatomic, retain) IBOutlet UILabel* units4;

@end
