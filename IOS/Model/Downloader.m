// Created by Michael Simms on 9/3/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "Downloader.h"

@implementation Downloader

- (void)downloadFile:(NSString*)sourceFileName to:(NSString*)destinationFileName completionHandler:(void (^)(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error))completionHandler
{
	self->bytesReceived = 0;
	self->destinationFileName = destinationFileName;

	NSFileManager* fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:self->destinationFileName error:nil];

	if ([fm createFileAtPath:self->destinationFileName contents:nil attributes:nil])
	{
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:sourceFileName]];
		[request setHTTPMethod:@"GET"];

		NSURLSession* session = [NSURLSession sharedSession];
		NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
		[dataTask resume];
	}
}

- (void)downloadFile:(NSString*)sourceFileName to:(NSString*)destinationFileName
{
	[self downloadFile:sourceFileName to:destinationFileName completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
	{
		self->bytesReceived += [data length];

		if ([self->delegate respondsToSelector:@selector(didReceiveData:)])
		{
			[self->delegate didReceiveData:self];
		}

		NSFileHandle* fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self->destinationFileName];
		if (fileHandle)
		{
			[fileHandle seekToEndOfFile];
			[fileHandle writeData:data];
			[fileHandle closeFile];

			if ([self->delegate respondsToSelector:@selector(didLoadData:)])
			{
				[self->delegate didLoadData:self];
			}
		}
	}];
}

@end
