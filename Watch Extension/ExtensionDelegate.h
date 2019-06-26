//  Created by Michael Simms on 6/12/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import "SensorMgr.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
{
	SensorMgr* sensorMgr;
}

- (void)stopSensors;
- (void)startSensors;

- (NSMutableArray*)getActivityTypes;
- (NSMutableArray*)getCurrentActivityAttributes;
- (NSString*)getCurrentActivityType;

@end
