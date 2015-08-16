// Created by Michael Simms on 12/21/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface Pin : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D coordinate;
	NSString* title;
	NSString* subtitle;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString* title;
@property (nonatomic, readonly, copy) NSString* subTitle;

- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:(NSString*)placeName description:(NSString*)description;

@end
