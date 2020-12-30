// Created by Michael Simms on 12/25/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

#import "CommonViewController.h"
#import "CrumbPath.h"
#import "CrumbPathRenderer.h"

@interface MapViewController : CommonViewController <MKMapViewDelegate, UIActionSheetDelegate>
{
	IBOutlet MKMapView*       mapView;
	IBOutlet UIBarButtonItem* mapTypeButton;
	IBOutlet UIBarButtonItem* homeButton;

    CrumbPath*         crumbs;
    CrumbPathRenderer* crumbRenderer;

	NSMutableArray*    lines;
	NSString*          overlayFileName;
}

- (void)showOverlay;
- (void)setOverlayFile:(NSString*)kmlFileName;
- (void)showRoute:(CLLocationCoordinate2D*)points withPointCount:(size_t)pointCount withColor:(UIColor*)color withWidth:(CGFloat)width;
- (void)addNewLocation:(CLLocation*)newLocation;
- (void)addPin:(CLLocationCoordinate2D)coordinate withPlaceName:(NSString*)placeName withDescription:(NSString*)description;

- (IBAction)onAutoScale:(id)sender;
- (IBAction)onMapType:(id)sender;

@property (nonatomic, retain) IBOutlet MKMapView* mapView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* mapTypeButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* homeButton;

@end
