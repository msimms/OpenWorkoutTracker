//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface WatchSessionManager : NSObject<WCSessionDelegate>
{
	WCSession* watchSession; // Handles communication between the watch and the phone
	time_t lastPhoneSync; // Timestamp of the last time we synchronized with the phone
}

- (void)startWatchSession;
- (void)sendActivity:(NSString*)activityId withHash:(NSString*)activityHash;

@end
