// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

@interface PacePlansViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITableView* planTableView;
	IBOutlet UIBarButtonItem* addPlanButton;
	
	NSString* selectedPlanId;
	NSMutableArray* planNames;
}

- (IBAction)onAddPacePlan:(id)sender;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* planTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* addPlanButton;

@end
