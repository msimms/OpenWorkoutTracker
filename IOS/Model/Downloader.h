// Created by Michael Simms on 9/3/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

@protocol DownloaderDelegate;

#import <Foundation/Foundation.h>

@interface Downloader : NSObject
{
	id<DownloaderDelegate> delegate;

	NSString* strFileNameWithPath;
	NSURLConnection* connection;
	CGFloat floatTotalData;
	CGFloat floatReceivedData;
}

@property(nonatomic, retain) NSString* strFileNameWithPath;
@property(nonatomic, retain) id <DownloaderDelegate> delegate;

- (void)loadData;
- (float)getProgressInPercent;

@end

@protocol DownloaderDelegate <NSObject>

@optional
- (void)didReceiveData:(Downloader*)d;
- (void)didLoadData:(Downloader*)d;
@end
