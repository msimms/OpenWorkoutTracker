// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import "CommonViewController.h"
#import "AppStrings.h"
#import "ActivityType.h"

@interface CommonViewController ()

@end

@implementation CommonViewController

@synthesize navItem;
@synthesize toolbar;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self initializeNavButtonColor];
	[self initializeToolbarButtonColor];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self->spinCount = 0;
}

- (void)initializeNavButtonColor
{
	bool isDarkModeEnabled = [self isDarkModeEnabled];

	UIColor* buttonColor = isDarkModeEnabled ? [UIColor whiteColor] : [UIColor blackColor];
	UIColor* toolbarColor = isDarkModeEnabled ? [UIColor blackColor] : [UIColor whiteColor];

	for (UIBarButtonItem* item in self->navItem.leftBarButtonItems)
		[item setTintColor:buttonColor];
	for (UIBarButtonItem* item in self->navItem.rightBarButtonItems)
		[item setTintColor:buttonColor];

	self.navigationController.navigationBar.tintColor = buttonColor;
	self.navigationController.navigationBar.backgroundColor = toolbarColor;
	self.navigationController.navigationBar.translucent = !isDarkModeEnabled;
}

- (void)initializeToolbarButtonColor
{
	bool isDarkModeEnabled = [self isDarkModeEnabled];

	UIColor* buttonColor = isDarkModeEnabled ? [UIColor whiteColor] : [UIColor blackColor];
	UIColor* toolbarColor = isDarkModeEnabled ? [UIColor blackColor] : [UIColor whiteColor];

	for (UIBarButtonItem* item in self->toolbar.items)
		[item setTintColor:buttonColor];

	self.toolbar.tintColor = toolbarColor;
	self.toolbar.barTintColor = toolbarColor;
	self.toolbar.translucent = !isDarkModeEnabled;
}

- (void)startSpinner:(UIActivityIndicatorView*)spinner withDispatch:(BOOL)dispatch
{
	if (self->spinCount == 0)
	{
		if (dispatch)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				spinner.hidden = FALSE;
				spinner.center = self.view.center;
				[spinner startAnimating];
			});
		}
		else
		{
			spinner.hidden = FALSE;
			spinner.center = self.view.center;
			[spinner startAnimating];
		}
	}
	self->spinCount++;
}

- (void)stopSpinner:(UIActivityIndicatorView*)spinner
{
	[spinner stopAnimating];
	self->spinCount--;
}

- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
																			 message:msg
																	  preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg handler:(void (^)(UIAlertAction* action))handler
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
																			 message:msg
																	  preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:handler]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)displayEmailComposerSheet:(NSString*)subjectStr withBody:(NSString*)bodyStr withFileName:(NSString*)fileName withMimeType:(NSString*)mimeType withDelegate:(id)delegate
{
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];

		if (mailController)
		{
			[mailController setEditing:TRUE];
			[mailController setSubject:subjectStr];
			[mailController setMessageBody:bodyStr isHTML:NO];
			[mailController setMailComposeDelegate:delegate];

			if (fileName)
			{
				NSString* justTheFileName = [[[NSFileManager defaultManager] displayNameAtPath:fileName] lastPathComponent];
				NSData* myData = [NSData dataWithContentsOfFile:fileName];

				[mailController addAttachmentData:myData mimeType:mimeType fileName:justTheFileName];
			}

			[self presentViewController:mailController animated:YES completion:nil];
		}
	}
	else
	{
		[self showOneButtonAlert:STR_ERROR withMsg:STR_MAIL_DISABLED];
	}
}

- (void)checkActionSheetButton:(UIAlertAction*)button
{
	[button setValue:@true forKey:@"checked"];
}

- (UIImage*)activityTypeToIcon:(NSString*)activityType
{
	UIImage* img = nil;

	if (([activityType compare:@ACTIVITY_TYPE_CHINUP] == NSOrderedSame) ||
		([activityType compare:@ACTIVITY_TYPE_SQUAT] == NSOrderedSame) ||
		([activityType compare:@ACTIVITY_TYPE_PULLUP] == NSOrderedSame) ||
		([activityType compare:@ACTIVITY_TYPE_PUSHUP] == NSOrderedSame))
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Weights" ofType:@"png"]];
	}
	else if (([activityType compare:@ACTIVITY_TYPE_CYCLING] == NSOrderedSame) ||
			 ([activityType compare:@ACTIVITY_TYPE_MOUNTAIN_BIKING] == NSOrderedSame) ||
			 ([activityType compare:@ACTIVITY_TYPE_STATIONARY_BIKE] == NSOrderedSame))
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Wheel" ofType:@"png"]];
	}
	else if ([activityType compare:@ACTIVITY_TYPE_DUATHLON] == NSOrderedSame)
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Duathlon" ofType:@"png"]];
	}
	else if ([activityType compare:@ACTIVITY_TYPE_HIKING] == NSOrderedSame)
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Hiking" ofType:@"png"]];
	}
	else if ([activityType compare:@ACTIVITY_TYPE_RUNNING] == NSOrderedSame)
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Running" ofType:@"png"]];
	}
	else if ([activityType compare:@ACTIVITY_TYPE_TREADMILL] == NSOrderedSame)
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Treadmill" ofType:@"png"]];
	}
	else if ([activityType compare:@ACTIVITY_TYPE_TRIATHLON] == NSOrderedSame)
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Triathlon" ofType:@"png"]];
	}
	else if ([activityType compare:@ACTIVITY_TYPE_WALKING] == NSOrderedSame)
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Walking" ofType:@"png"]];
	}
	else if (([activityType compare:@ACTIVITY_TYPE_OPEN_WATER_SWIMMING] == NSOrderedSame) ||
			 ([activityType compare:@ACTIVITY_TYPE_POOL_SWIMMING] == NSOrderedSame))
	{
		img = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"Swimming" ofType:@"png"]];
	}
	return img;
}

- (BOOL)isDarkModeEnabled
{
	switch (self.view.traitCollection.userInterfaceStyle)
	{
	case UIUserInterfaceStyleUnspecified:
	case UIUserInterfaceStyleLight:
		return false;
	case UIUserInterfaceStyleDark:
		return true;
	}
	return false;
}

@end
