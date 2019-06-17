//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchActivityViewController.h"
#import "ActivityMgr.h"

@interface WatchActivityViewController ()

@end


@implementation WatchActivityViewController

- (instancetype)init {
	self = [super init];
	if (self)
	{
	}
	return self;
}

- (void)willActivate
{
	// This method is called when watch view controller is about to be visible to user
	[super willActivate];
}

- (void)didDeactivate
{
	// This method is called when watch view controller is no longer visible
	[super didDeactivate];
}

@end
