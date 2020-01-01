// Created by Michael Simms on 12/31/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

@interface PacePlanEditViewController : UIViewController
{
	IBOutlet UIToolbar* toolbar;
	
	NSString* selectedPlanId;
}

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;

@end
