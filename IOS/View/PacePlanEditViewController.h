// Created by Michael Simms on 12/31/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

@interface PacePlanEditViewController : UIViewController
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITextField* nameTextField;
	IBOutlet UITextField* distanceTextField;
	IBOutlet UITextField* targetPaceTextField;
	IBOutlet UITextField* splitsTextField;
	
	NSString* selectedPlanId;
}

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITextField* nameTextField;
@property (nonatomic, retain) IBOutlet UITextField* distanceTextField;
@property (nonatomic, retain) IBOutlet UITextField* targetPaceTextField;
@property (nonatomic, retain) IBOutlet UITextField* splitsTextField;

@end
