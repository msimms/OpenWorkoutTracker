//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface DetailsRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* itemLabel;

@end

@interface DetailsViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceTable* detailsTable;
}

@property (nonatomic, retain) IBOutlet WKInterfaceTable* detailsTable;

@end
