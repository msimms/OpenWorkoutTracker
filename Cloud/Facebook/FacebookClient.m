// Created by Michael Simms on 9/24/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "FacebookClient.h"
#import "CloudPreferences.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

@implementation FacebookClient

- (NSString*)name
{
	return @"Facebook";
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (void)buildAcctNameList
{
	@try
	{
		ACAccountStore* accountStore = [[ACAccountStore alloc] init];
		ACAccountType* accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

		// Request access from the user to access their Facebook account.
		[accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError* error)
		 {
			 if (granted == YES)
			 {
				 NSMutableArray* acctNames = [[NSMutableArray alloc] init];
				 NSArray* arrayOfAccounts = [accountStore accountsWithAccountType:accountType];

				 for (ACAccount* account in arrayOfAccounts)
				 {
					 [acctNames addObject:[account username]];
				 }

				 [[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_FB_ACCT_LIST_UPDATED object:acctNames];
			 }
		 }];
	}
	@catch (NSException *exception)
	{
	}
	@finally
	{
	}
}

- (BOOL)showComposerView:(NSString*)initialText
{
	SLComposeViewController* fbController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
	
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
	{
        SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result)
		{
			[fbController dismissViewControllerAnimated:YES completion:nil];
			
			switch (result)
			{
				case SLComposeViewControllerResultCancelled:
					break;
				case SLComposeViewControllerResultDone:
					break;
			}
		};
		
		[fbController setInitialText:initialText];
		[fbController setCompletionHandler:completionHandler];
		
		return YES;
	}
	return NO;
}

- (BOOL)postUpdate:(NSString*)str
{
	NSDictionary* options = @{
		@"ACFacebookAppIDKey": @"123456789",
		@"ACFacebookAppVersionKey": @"1.0",
		@"ACFacebookPermissionsKey": @[@"publish_stream"],
		@"ACFacebookPermissionGroupKey": @"write"
	};

	ACAccountStore* account = [[ACAccountStore alloc] init];
	ACAccountType* accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

	// Request access from the user to access their Facebook account.
	[account requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError* error)
	{
		if (granted == YES)
		{
			// Populate array with all available Facebook accounts and select the first one.
			NSArray* arrayOfAccounts = [account accountsWithAccountType:accountType];
			NSString* preferredAcctName = [CloudPreferences preferredFacebookAcctName];
			ACAccount* preferredAcct;
		
			for (ACAccount* account in arrayOfAccounts)
			{
				if ([[account username] isEqualToString:preferredAcctName])
				{
					preferredAcct = account;
				}
			}

			if (preferredAcct)
			{
				ACAccount* acct = [arrayOfAccounts firstObject];
				NSDictionary* parameters = @{@"message": str};
				NSURL* feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
				SLRequest* feedRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
															requestMethod:SLRequestMethodPOST
																	  URL:feedURL
															   parameters:parameters];
				feedRequest.account = acct;

				[feedRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
				 {
					 // Handle response
				 }];
			}
		}
	}];
	return NO;
}

@end
