//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchActivityViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceButton* startStopButton;
	IBOutlet __strong WKInterfaceButton* intervalsButton;
	IBOutlet __strong WKInterfaceButton* pacePlanButton;
	IBOutlet __strong WKInterfaceLabel* value1;
	IBOutlet __strong WKInterfaceLabel* value2;
	IBOutlet __strong WKInterfaceLabel* value3;
	IBOutlet __strong WKInterfaceLabel* units1;
	IBOutlet __strong WKInterfaceLabel* units2;
	IBOutlet __strong WKInterfaceLabel* units3;
	IBOutlet __strong WKInterfaceGroup* group1;
	IBOutlet __strong WKInterfaceGroup* group2;
	IBOutlet __strong WKInterfaceGroup* group3;

	NSTimer*        refreshTimer;
	NSMutableArray* valueLabels;
	NSMutableArray* unitsLabels;
	NSMutableArray* groups;
	BOOL            isPopping;
}

@property (nonatomic, retain) IBOutlet WKInterfaceButton* startStopButton;
@property (nonatomic, retain) IBOutlet WKInterfaceButton* intervalsButton;
@property (nonatomic, retain) IBOutlet WKInterfaceButton* pacePlanButton;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* value1;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* value2;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* value3;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* units1;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* units2;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* units3;
@property (nonatomic, retain) IBOutlet WKInterfaceGroup* group1;
@property (nonatomic, retain) IBOutlet WKInterfaceGroup* group2;
@property (nonatomic, retain) IBOutlet WKInterfaceGroup* group3;

@end
