//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchIntervalsRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* itemLabel;

@end

@interface WatchIntervalsViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceTable* intervalsTable;
}

@property (nonatomic, retain) IBOutlet WKInterfaceTable* intervalsTable;

@end
