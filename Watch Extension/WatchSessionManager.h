//  Created by Michael Simms on 7/28/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface WatchSessionManager : NSObject<WCSessionDelegate>
{
	WCSession* watchSession;
}

- (void)startWatchSession;

@end
