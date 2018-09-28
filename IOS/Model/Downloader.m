// Created by Michael Simms on 9/3/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "Downloader.h"

@implementation Downloader

@synthesize strFileNameWithPath;
@synthesize delegate;

- (void)loadData
{
	self->floatTotalData     = 100;
	self->floatReceivedData  = 0;

	NSArray*  paths          = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* docDir         = [paths objectAtIndex: 0];
	self.strFileNameWithPath = [docDir stringByAppendingPathComponent:@"Workouts.sqlite"];

	[[NSFileManager defaultManager] createFileAtPath:self.strFileNameWithPath contents:nil attributes:nil];

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://mikesimms.net/Workouts.sqlite"]];
	[request setHTTPMethod:@"GET"];

	NSURLSession* session = [NSURLSession sharedSession];
	NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
												completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
									  {
										  self->floatReceivedData += [data length];
										  
										  NSFileHandle* fileHandle = [NSFileHandle fileHandleForUpdatingAtPath: self.strFileNameWithPath];
										  [fileHandle seekToEndOfFile];
										  [fileHandle writeData: data];
										  [fileHandle closeFile];
										  
										  if ([self.delegate respondsToSelector:@selector(didReceiveData:)])
											  [self.delegate didReceiveData:self];
										  if ([self.delegate respondsToSelector:@selector(didLoadData:)])
											  [self.delegate didLoadData:self];
									  }];
	[dataTask resume];
}

@end
