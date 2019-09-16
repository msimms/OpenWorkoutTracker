//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "DetailsViewController.h"
#import "ExtensionDelegate.h"

@implementation DetailsRowController

@synthesize itemLabel;

@end


@interface DetailsViewController ()

@end


@implementation DetailsViewController

@synthesize detailsTable;

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

- (void)awakeWithContext:(id)context
{
}

@end
