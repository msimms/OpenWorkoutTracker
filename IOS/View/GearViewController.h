// Created by Michael Simms on 4/17/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import "CommonViewController.h"
#import "BikeProfileViewController.h"
#import "DateViewController.h"
#import "ShoeProfileViewController.h"

@interface GearViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UITableView*     gearTableView;
	IBOutlet UIToolbar*       toolbar;

	NSMutableArray*     bikeNames;
	NSMutableArray*     shoeNames;
	BikeProfileViewMode bikeViewMode;
	ShoeProfileViewMode shoeViewMode;
	NSString*           selectedBikeName;
	NSString*           selectedShoeName;
}

- (IBAction)onAdd:(id)sender;

@property (nonatomic, retain) IBOutlet UITableView* gearTableView;
@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;

@end
