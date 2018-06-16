// Created by Michael Simms on 8/16/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>
{
	IBOutlet UITextField* usernameTextField;
	IBOutlet UITextField* passwordTextField;
	
	IBOutlet UIBarButtonItem* loginButton;

	IBOutlet UIActivityIndicatorView* spinner;

	NSString* username;
}

@property (nonatomic, retain) IBOutlet UITextField* usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField* passwordTextField;

@property (nonatomic, retain) IBOutlet UIBarButtonItem* loginButton;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

- (IBAction)onLogin:(id)sender;

@end
