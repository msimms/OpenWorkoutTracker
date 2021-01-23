// Created by Michael Simms on 12/31/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import "PacePlanEditViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "StringUtils.h"

#define TITLE NSLocalizedString(@"Edit Pace Plan", nil)
#define MSG_INVALID_DISTANCE NSLocalizedString(@"Invalid distance value.", nil)
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
	double targetDistance = (double)0.0;
	double targetPaceMin = (double)0.0;
	double splitsMin = (double)0.0;

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if ([appDelegate getPacePlanDetails:self->selectedPlanId withPlanName:&planName withTargetPace:&targetPaceMin withTargetDistance:&targetDistance withSplits:&splitsMin])
	{
		if (planName != nil)
			nameTextField.text = planName;
		distanceTextField.text = [NSString stringWithFormat:@"%0.2f", targetDistance];
		targetPaceTextField.text = [StringUtils formatSeconds:(uint64_t)(targetPaceMin * 60.0)];
		splitsTextField.text = [StringUtils formatSeconds:(uint64_t)(splitsMin * 60.0)];
	}
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

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	 [[self view] endEditing:YES];
}

- (IBAction)onSave:(id)sender
{
	uint16_t hours = 0;
	uint16_t minutes = 0;
	uint16_t seconds = 0;

	double targetDistance = [distanceTextField.text floatValue];
	double targetPaceMin = 0.0;
	double splitsMin = 0.0;
	
	// Validate the distance. The units will be converted later.
	if (targetDistance <= 0.0)
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_INVALID_DISTANCE];
		return;
	}

	// Parse and validate the pace data.
	if ([StringUtils parseHHMMSS:targetPaceTextField.text withHours:&hours withMinutes:&minutes withSeconds:&seconds])
	{
		targetPaceMin = ((hours * 60.0 * 60.0) + (minutes * 60.0) + seconds) / 60.0;
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_INVALID_TIME];
		return;
	}

	// Parse and validate the splits data.
	if ([StringUtils parseHHMMSS:splitsTextField.text withHours:&hours withMinutes:&minutes withSeconds:&seconds])
	{
		splitsMin = ((hours * 60.0 * 60.0) + (minutes * 60.0) + seconds) / 60.0;
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:MSG_INVALID_TIME];
		return;
	}

	// Update the data.
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	if ([appDelegate updatePacePlanDetails:selectedPlanId withPlanName:nameTextField.text withTargetPace:targetPaceMin withTargetDistance:targetDistance withSplits:splitsMin])
	{
		[self.navigationController popViewControllerAnimated:TRUE];
	}
	else
	{
		[super showOneButtonAlert:STR_ERROR withMsg:STR_INTERNAL_ERROR];
	}
}

- (void)setPlanId:(NSString*)planId
{
	self->selectedPlanId = planId;
}

@end
