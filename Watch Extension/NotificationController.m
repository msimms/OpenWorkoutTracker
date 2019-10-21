//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NotificationController.h"


@interface NotificationController ()

@end


@implementation NotificationController

- (instancetype)init
{
	self = [super init];
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

- (void)didReceiveNotification:(UNNotification*)notification
{
	// This method is called when a notification needs to be presented.
	// Implement it if you use a dynamic notification interface.
	// Populate your dynamic notification interface as quickly as possible.
}

@end
