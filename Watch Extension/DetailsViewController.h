//  Created by Michael Simms on 9/16/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

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
