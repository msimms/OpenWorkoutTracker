//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchHistoryRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* itemLabel;

@end

@interface WatchHistoryViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceTable* historyTable;
}

@property (nonatomic, retain) IBOutlet WKInterfaceTable* historyTable;

@end
