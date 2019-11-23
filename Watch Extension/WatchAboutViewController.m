//  Created by Michael Simms on 11/23/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import "WatchAboutViewController.h"
#import "Version.h"

@implementation WatchAboutViewController

@synthesize compileDate;

- (instancetype)init
{
	self = [super init];
	return self;
}

- (void)willActivate
{
	[super willActivate];
	
	Version* vers = [[Version alloc] init];
	[self->compileDate setText:[[NSString alloc] initWithFormat:@"Built on: %@", [vers compileTime]]];
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
}

@end
