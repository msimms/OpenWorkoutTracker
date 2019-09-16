//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

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
