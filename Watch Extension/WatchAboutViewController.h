//  Created by Michael Simms on 11/23/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchAboutViewController : WKInterfaceController
{
	IBOutlet __strong WKInterfaceLabel* compileDate; // Displays the timestamp for when this version was built
}

@property (nonatomic, retain) IBOutlet WKInterfaceLabel* compileDate;

@end
