//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchSettingsViewController.h"
#import "ActivityMgr.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

@interface WatchSettingsViewController ()

@end


@implementation WatchSettingsViewController

@synthesize broadcast;

- (instancetype)init
{
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (void)willActivate
{
	[super willActivate];
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (void)didAppear
{
}

- (void)awakeWithContext:(id)context
{
}

@end
