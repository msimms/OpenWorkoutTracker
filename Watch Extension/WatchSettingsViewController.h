//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchSettingsViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceSwitch* broadcast; // Allows the user to enable/disable the broadcast option
	IBOutlet __strong WKInterfaceSwitch* metric; // Allows the user to toggle between metric and standard units
	IBOutlet __strong WKInterfaceButton* resetButton; // Allows the user to reset the app, removing all data from the database
}

@property (nonatomic, retain) IBOutlet WKInterfaceSwitch* broadcast;
@property (nonatomic, retain) IBOutlet WKInterfaceSwitch* metric;
@property (nonatomic, retain) IBOutlet WKInterfaceButton* resetButton;

@end
