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
	ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
	[extDelegate startWatchSession];

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

	for (NSString* name in [activityTypes reverseObjectEnumerator])
	{
		WKAlertAction* action = [WKAlertAction actionWithTitle:name style:WKAlertActionStyleCancel handler:^(void){
			[self startActivity:name];
		}];	
		[actions addObject:action];
	}

	// Add the cancel button.
	WKAlertAction* action = [WKAlertAction actionWithTitle:STR_CANCEL style:WKAlertActionStyleCancel handler:^(void){}];	
	[actions addObject:action];

	[self presentAlertControllerWithTitle:nil
								  message:MSG_SELECT_NEW
						   preferredStyle:WKAlertControllerStyleAlert
								  actions:actions];
}

#pragma method to switch to the activity view

- (void)createActivity:(NSString*)activityType
{
	const char* pActivityType = [activityType cStringUsingEncoding:NSASCIIStringEncoding];
	if (pActivityType)
	{
		CreateActivity(pActivityType);
		
		ExtensionDelegate* extDelegate = [WKExtension sharedExtension].delegate;
		[extDelegate startSensors];
		
		[self pushControllerWithName:@"WatchActivityViewController" context:nil];
	}
}

- (void)startActivity:(NSString*)activityType
{
	bool isInProgress = IsActivityInProgress();

	if (isInProgress)
	{
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
