//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "InterfaceController.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"

#define MSG_SELECT_NEW NSLocalizedString(@"Select the workout", nil)

@interface InterfaceController ()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context
{
	[super awakeWithContext:context];
}

- (void)willActivate
{
	[super willActivate];

	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	size_t orphanedActivityIndex = 0;
	bool isOrphaned = [extDelegate isActivityOrphaned:&orphanedActivityIndex];
	bool isInProgress = [extDelegate isActivityInProgress];

	if (isOrphaned || isInProgress)
	{
		[extDelegate recreateOrphanedActivity:orphanedActivityIndex];
		[self pushControllerWithName:@"WatchActivityViewController" context:nil];
	}
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (IBAction)onStartWorkout
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	NSMutableArray* activityTypes = [extDelegate getActivityTypes];
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	[activityTypes sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	for (NSString* name in activityTypes)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:name style:WKAlertActionStyleDefault handler:^(void){
			[self createActivity:name];
		}];	
		[actions addObject:action];
	}

	// Add the cancel button.
	WKAlertAction* action = [WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void){}];	
	[actions addObject:action];

	// Show the action sheet.
	[self presentAlertControllerWithTitle:nil message:MSG_SELECT_NEW preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

#pragma method to switch to the activity view

- (void)createActivity:(NSString*)activityType
{
	ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;

	// Create the data structures and database entries needed to start an activity.
	[extDelegate createActivity:activityType];

	// Initialize any sensors that we are going to use.
	[extDelegate startSensors];

	// Switch to the activity view.
	[self pushControllerWithName:@"WatchActivityViewController" context:nil];
}

@end
