// Created by Michael Simms on 12/31/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import "PacePlanEditViewController.h"
#import "AppDelegate.h"
#import "AppStrings.h"
#import "StringUtils.h"

#define TITLE NSLocalizedString(@"Edit Pace Plan", nil)
#define MSG_INVALID_DISTANCE NSLocalizedString(@"Invalid distance value.", nil)
#define MSG_INVALID_TIME NSLocalizedString(@"Invalid time value.", nil)

typedef enum PickerRows
{
	ROW_METRIC = 0,
	ROW_US_CUSTOMARY,
	NUM_PICKER_ROWS
} PickerRows;

@interface PacePlanEditViewController ()

@end

@implementation PacePlanEditViewController

@synthesize toolbar;
@synthesize nameTextField;
@synthesize distanceTextField;
@synthesize targetPaceTextField;
@synthesize splitsTextField;
@synthesize unitsPickerDistance;
@synthesize unitsPickerPace;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (void)viewDidLoad
{
	self.title = TITLE;

	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString* planName = nil;
	double targetDistance = (double)0.0;
	double targetPaceMin = (double)0.0;
	double splitsMin = (double)0.0;
	UnitSystem targetDistanceUnits = UNIT_SYSTEM_METRIC;
	UnitSystem targetPaceUnits = UNIT_SYSTEM_METRIC;

	// Retrieve the plan details from the database.
	if ([appDelegate getPacePlanDetails:self->selectedPlanId withPlanName:&planName withTargetPace:&targetPaceMin withTargetDistance:&targetDistance withSplits:&splitsMin withTargetDistanceUnits:&targetDistanceUnits withTargetPaceUnits:&targetPaceUnits])
	{
		if (planName != nil)
			nameTextField.text = planName;
		distanceTextField.text = [NSString stringWithFormat:@"%0.2f", targetDistance];
		targetPaceTextField.text = [StringUtils formatSeconds:(uint64_t)(targetPaceMin * 60.0)];
		splitsTextField.text = [StringUtils formatSeconds:(uint64_t)(splitsMin * 60.0)];
		[self.unitsPickerDistance selectRow:(NSInteger)targetDistanceUnits inComponent:0 animated:FALSE];
		[self.unitsPickerPace selectRow:(NSInteger)targetPaceUnits inComponent:0 animated:FALSE];
	}

	[super viewDidAppear:animated];
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

	UnitSystem targetDistanceUnits = (UnitSystem)[self.unitsPickerDistance selectedRowInComponent:0];
	UnitSystem targetPaceUnits = (UnitSystem)[self.unitsPickerPace selectedRowInComponent:0];

	AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

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
	if (targetPaceMin <= 0.0)
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
	if ([appDelegate updatePacePlanDetails:selectedPlanId withPlanName:nameTextField.text withTargetPace:targetPaceMin withTargetDistance:targetDistance withSplits:splitsMin withTargetDistanceUnits:targetDistanceUnits withTargetPaceUnits:targetPaceUnits])
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

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView*)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return NUM_PICKER_ROWS;
}

- (NSString*)pickerView:(nonnull UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	switch (row)
	{
	case ROW_METRIC:
		return STR_METRIC;
	case ROW_US_CUSTOMARY:
		return STR_US_CUSTOMARY;
	}
	return @"";
}

@end
