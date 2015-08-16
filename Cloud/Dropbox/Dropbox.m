//
//  Dropbox.m
//
//  Created by Michael Simms on 6/30/12.
//  Copyright (c) 2012 Michael J. Simms. All rights reserved.
//

#import "Dropbox.h"
#import "DropboxRootViewController.h"

@implementation Dropbox

- (id)init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (BOOL)link:(NSString*)appKey :(NSString*)appSecret :(NSString*)root
{
	// Pre-iOS 4.0 won't call application:handleOpenURL; this code is only needed if you support iOS versions 3.2 or below
	NSInteger majorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
	if (majorVersion < 4)
	{
		return NO;
	}

	NSString* errorMsg = nil;

	if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound)
	{
		errorMsg = @"Make sure you pass the app key correctly to the Dropbox object.";
	}
	else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound)
	{
		errorMsg = @"Make sure you pass the app secret correctly to the Dropbox object.";
	}
	else if ([root length] == 0)
	{
		errorMsg = @"Set your root to use either App Folder or full Dropbox.";
	}
	else
	{
		NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
		NSData* plistData = [NSData dataWithContentsOfFile:plistPath];
		NSDictionary* loadedPlist = [NSPropertyListSerialization 
			propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
		NSString* scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
		NSString* expectedScheme = [NSString stringWithFormat:@"db-%@", appKey];
		if (![scheme isEqual:expectedScheme])
		{
			errorMsg = @"Set your URL scheme correctly in <App-Info>.plist";
		}
	}
	
	if (errorMsg != nil)
	{
		[[[UIAlertView alloc]
		  initWithTitle:@"Error Configuring Session"
		  message:errorMsg
		  delegate:nil
		  cancelButtonTitle:@"OK"
		  otherButtonTitles:nil]
		 show];
		return NO;
	}

//	[DBRequest setNetworkRequestDelegate:self];

//	DBSession* session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
//	if (session)
//	{
//		session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
//		[DBSession setSharedSession:session];

//		self->restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
//		if (self->restClient)
//		{
//			self->restClient.delegate = self;
//		}
//	}
		
	return YES;
}

- (BOOL)unlink
{
//	if ([[DBSession sharedSession] isLinked])
//	{
//		[[DBSession sharedSession] unlinkAll];
//		[[[UIAlertView alloc]
//		  initWithTitle:@"Account Unlinked!"
//		  message:@"Your dropbox account has been unlinked."
//		  delegate:nil
//		  cancelButtonTitle:@"OK"
//		  otherButtonTitles:nil]
//		 show];
//		return YES;
//	}
	return NO;
}

- (BOOL)isLinked
{
//	return [[DBSession sharedSession] isLinked];
	return NO;
}

#pragma mark FileSharingWebsite methods

- (NSString*)name
{
	return @"Dropbox";
}

- (BOOL)uploadFile:(NSString*)filePath
{
//	if (self->restClient)
//	{
//		[self->restClient uploadFile:filePath toPath:@"/" withParentRev:NULL fromPath:filePath];
//	}
	return NO;
}

#pragma mark DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
}

- (void)restClient:(DBRestClient*)client loadedDeltaEntries:(NSArray*)entries reset:(BOOL)shouldReset cursor:(NSString*)cursor hasMore:(BOOL)hasMore
{
}

- (void)restClient:(DBRestClient*)client loadDeltaFailedWithError:(NSError*)error
{
}

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
}

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata
{
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error
{
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
		  metadata:(DBMetadata*)metadata
{
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
		   forFile:(NSString*)destPath from:(NSString*)srcPath
{
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
}

#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId :(NSString*)userId
{
	[[[UIAlertView alloc] initWithTitle:@"Dropbox Session Ended"
								message:@"Do you want to relink?"
							   delegate:self
					  cancelButtonTitle:@"Cancel"
					  otherButtonTitles:@"Relink", nil] show];
}

#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted
{
	outstandingRequests++;
}

- (void)networkRequestStopped
{
	outstandingRequests--;
}

@end
