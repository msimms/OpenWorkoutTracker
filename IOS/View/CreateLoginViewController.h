// Created by Michael Simms on 8/16/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface CreateLoginViewController : UIViewController <UITextFieldDelegate>
{
	IBOutlet UITextField* usernameTextField;
	IBOutlet UITextField* passwordTextField;
	IBOutlet UITextField* confirmPasswordTextField;
	IBOutlet UITextField* realNameTextField;
	IBOutlet UIActivityIndicatorView* spinner;
	
	NSString* username;
}

- (IBAction)onCreate:(id)sender;

@property (nonatomic, retain) IBOutlet UITextField* usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField* passwordTextField;
@property (nonatomic, retain) IBOutlet UITextField* confirmPasswordTextField;
@property (nonatomic, retain) IBOutlet UITextField* realNameTextField;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

@end
