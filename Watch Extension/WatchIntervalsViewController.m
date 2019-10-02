//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchIntervalsViewController.h"
#import "ActivityMgr.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "StringUtils.h"

@implementation WatchIntervalsRowController

@synthesize itemLabel;

@end


@interface WatchIntervalsViewController ()

@end


@implementation WatchIntervalsViewController

@synthesize intervalsTable;

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
	[super awakeWithContext:context];
	[self redraw];
}

#pragma mark table handling methods

- (void)redraw
{
}

@end
