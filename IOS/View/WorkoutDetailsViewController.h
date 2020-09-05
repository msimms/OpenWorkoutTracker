// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface WorkoutDetailsViewController : CommonViewController
{
	IBOutlet UIToolbar* toolbar;
	IBOutlet UITableView* workoutsView;
	
	NSString* selectedWorkoutId;
}

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* workoutsView;

@end
