//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchHistoryRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceImage* itemImage;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel* itemLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel* itemSubLabel;

@end

@interface WatchHistoryViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceTable* historyTable;

	BOOL isPopping; // Prevents us from redrawing if we're about to pop
}

@property (nonatomic, retain) IBOutlet WKInterfaceTable* historyTable;

@end
