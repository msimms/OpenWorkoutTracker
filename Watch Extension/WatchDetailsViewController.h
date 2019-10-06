//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchDetailsRowController : NSObject
{
	IBOutlet __weak WKInterfaceLabel* name;
	IBOutlet __weak WKInterfaceLabel* value;
}

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* name;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel* value;

@end

@interface WatchDetailsViewController : WKInterfaceController
{
	IBOutlet __weak WKInterfaceMap* map;
	IBOutlet __strong WKInterfaceTable* detailsTable;

	NSString* activityId;
}

@property (weak, nonatomic) IBOutlet WKInterfaceMap* map;
@property (nonatomic, retain) IBOutlet WKInterfaceTable* detailsTable;

@end
