// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import "CommonViewController.h"
#import "AppStrings.h"

@interface CommonViewController ()

@end

@implementation CommonViewController

- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg
{
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
																			 message:msg
																	  preferredStyle:UIAlertControllerStyleAlert];           
	[alertController addAction:[UIAlertAction actionWithTitle:STR_OK style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alertController animated:YES completion:nil];
}

@end
