// Created by Michael Simms on 7/13/13.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

typedef enum OverlayListMode
{
	OVERLAY_LIST_FOR_PREVIEW = 0,
	OVERLAY_LIST_FOR_SELECTION
} OverlayListMode;

@interface OverlayListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	IBOutlet UIToolbar*       toolbar;
	IBOutlet UITableView*     overlayTableView;
	IBOutlet UIBarButtonItem* importButton;

	NSMutableArray* overlayNames;
	NSInteger       selectedSection;
	NSInteger       selectedRow;
	OverlayListMode mode;
}

- (void)setMode:(OverlayListMode)newMode;

- (IBAction)onImport:(id)sender;

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;
@property (nonatomic, retain) IBOutlet UITableView* overlayTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* importButton;

@end
