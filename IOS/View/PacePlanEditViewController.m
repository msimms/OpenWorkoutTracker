// Created by Michael Simms on 12/31/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import "PacePlanEditViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "StringUtils.h"

#define TITLE NSLocalizedString(@"Edit Pace Plan", nil)
#define MSG_INVALID_TIME NSLocalizedString(@"Invalid time value.", nil)

@interface PacePlanEditViewController ()

@end

@implementation PacePlanEditViewController

@synthesize toolbar;
@synthesize nameTextField;
@synthesize distanceTextField;
@synthesize targetPaceTextField;
@synthesize splitsTextField;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[super viewDidLoad];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	[self.toolbar setTintColor:[UIColor blackColor]];

	NSString* planName = nil;
	double targetPace = (double)0.0;
	double targetDistance = (double)0.0;
	double splits = (double)0.0;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if ([appDelegate retrievePacePlanDetails:self->selectedPlanId withPlanName:&planName withTargetPace:&targetPace withTargetDistance:&targetDistance withSplits:&splits])
	{
		if (planName != nil)
			nameTextField.text = planName;
		distanceTextField.text = [NSString stringWithFormat:@"%0.2f", targetDistance];
		targetPaceTextField.text = [StringUtils formatSeconds:(uint64_t)targetPace];
		splitsTextField.text = [StringUtils formatSeconds:(uint64_t)splits];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
}

- (IBAction)onSave:(id)sender
{
	uint16_t hours = 0;
	uint16_t minutes = 0;
	uint16_t seconds = 0;

	double targetPace = 0.0;
	double splits = 0.0;
	
	if ([StringUtils parseHHMMSS:targetPaceTextField.text withHours:&hours withMinutes:&minutes withSeconds:&seconds])
	{
		targetPace = (hours * 60 * 60) + (minutes * 60) + seconds;
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_INVALID_TIME];
		return;
	}

	if ([StringUtils parseHHMMSS:splitsTextField.text withHours:&hours withMinutes:&minutes withSeconds:&seconds])
	{
		splits = (hours * 60 * 60) + (minutes * 60) + seconds;
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_INVALID_TIME];
		return;
	}
}

- (void)setPlanId:(NSString*)planId
{
	self->selectedPlanId = planId;
}

@end
