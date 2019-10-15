//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "InterfaceController.h"
#import "ActivityMgr.h"
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
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (IBAction)onStartWorkout
{
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	NSMutableArray* activityTypes = [extDelegate getActivityTypes];
	NSMutableArray* actions = [[NSMutableArray alloc] init];

	[activityTypes sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	for (NSString* name in activityTypes)
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:name style:WKAlertActionStyleDefault handler:^(void){
			[self startActivity:name];
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
	const char* pActivityType = [activityType cStringUsingEncoding:NSASCIIStringEncoding];
	if (pActivityType)
	{
		// Create the data structures and database entries needed to start an activity.
		CreateActivity(pActivityType);

		// Initialize any sensors that we are going to use.
		ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
		[extDelegate startSensors];

		// Switch to the activity view.
		[self pushControllerWithName:@"WatchActivityViewController" context:nil];
	}
}

- (void)startActivity:(NSString*)activityType
{
	bool isOrphaned = IsActivityOrphaned(&self->orphanedActivityIndex);
	bool isInProgress = IsActivityInProgress();

	if (isOrphaned || isInProgress)
	{
		char* orphanedType = GetHistoricalActivityType(self->orphanedActivityIndex);
		self->orphanedActivityType = [NSString stringWithFormat:@"%s", orphanedType];
		free((void*)orphanedType);

		self->newActivityType = activityType;

		NSMutableArray* actions = [[NSMutableArray alloc] init];
		WKAlertAction* action;

		// Add the "re-connect to the orphaned activity" option.
		action = [WKAlertAction actionWithTitle:STR_YES style:WKAlertActionStyleDefault handler:^(void){
			ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
			[extDelegate recreateOrphanedActivity:self->orphanedActivityIndex];
			[self pushControllerWithName:@"WatchActivityViewController" context:nil];
		}];
		[actions addObject:action];
		
		// Add the "throw it away and start over" option
		action = [WKAlertAction actionWithTitle:STR_NO style:WKAlertActionStyleDefault handler:^(void){
			ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
			[extDelegate loadHistoricalActivity:self->orphanedActivityIndex];
			[self createActivity:self->newActivityType];
		}];	
		[actions addObject:action];

		// Add the cancel button.
		action = [WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void){}];	
		[actions addObject:action];

		// Show the action sheet.
		[self presentAlertControllerWithTitle:nil message:MSG_IN_PROGRESS preferredStyle:WKAlertControllerStyleAlert actions:actions];
	}
	else if (IsActivityCreated())
	{
		DestroyCurrentActivity();
		[self createActivity:activityType];
	}
	else
	{
		[self createActivity:activityType];
	}
}

@end
