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
	NSString* destinationFileName;
	NSURLConnection* connection;
	NSInteger bytesReceived;
}

- (void)downloadFile:(NSString*)sourceFileName to:(NSString*)destinationFileName completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandler;
- (void)downloadFile:(NSString*)sourceFileName to:(NSString*)destinationFileName;

@end

@protocol DownloaderDelegate <NSObject>

@optional
- (void)didReceiveData:(Downloader*)d;
- (void)didLoadData:(Downloader*)d;
@end
