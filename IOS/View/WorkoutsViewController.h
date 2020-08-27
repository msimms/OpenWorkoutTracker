// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface WorkoutsViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITableView* workoutsView;
	IBOutlet UIBarButtonItem* generateButton;
	
	NSString* selectedPlanId;
	NSMutableArray* planNamesAndIds;
}

- (IBAction)onGenerateWorkouts:(id)sender;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* workoutsView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* generateButton;

@end
