// Created by Michael Simms on 9/14/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface ExportingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
	NSMutableArray* fileClouds;
	NSMutableArray* dataClouds;
}

@end
