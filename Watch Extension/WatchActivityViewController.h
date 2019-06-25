//  Created by Michael Simms on 6/17/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchActivityViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceLabel* activityName;
	IBOutlet __strong WKInterfaceLabel* value1;
	IBOutlet __strong WKInterfaceLabel* value2;
	IBOutlet __strong WKInterfaceLabel* value3;
	IBOutlet __strong WKInterfaceLabel* units1;
	IBOutlet __strong WKInterfaceLabel* units2;
	IBOutlet __strong WKInterfaceLabel* units3;

	NSTimer*        refreshTimer;
	NSMutableArray* valueLabels;
	NSMutableArray* unitsLabels;
}

@property (nonatomic, retain) IBOutlet WKInterfaceLabel* activityName;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* value1;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* value2;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* value3;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* units1;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* units2;
@property (nonatomic, retain) IBOutlet WKInterfaceLabel* units3;

@end
