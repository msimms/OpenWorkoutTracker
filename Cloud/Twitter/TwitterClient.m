// Created by Michael Simms on 7/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "TwitterClient.h"
#import "CloudPreferences.h"

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>

@implementation TwitterClient

- (NSString*)name
{
	return @"Twitter";
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
		ACAccountType* accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

		// Request access from the user to access their Twitter account.
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

				 [[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_TWITTER_ACCT_LIST_UPDATED object:acctNames];
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

- (BOOL)postUpdate:(NSString*)str
{
	ACAccountStore* accountStore = [[ACAccountStore alloc] init];
	ACAccountType* accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

	// Request access from the user to access their Twitter account.
	[accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError* error)
	{
		if (granted == YES)
		{
			NSArray* arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
			NSString* preferredAcctName = [CloudPreferences preferredTwitterAcctName];
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
				ACAccount* twitterAccount = [arrayOfAccounts firstObject];
				NSDictionary* message = [[NSDictionary alloc] initWithObjectsAndKeys: @"status", str, nil];
				NSURL* requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
				SLRequest* postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
															requestMethod:SLRequestMethodPOST
																	  URL:requestURL
															   parameters:message];

				postRequest.account = twitterAccount;

				[postRequest performRequestWithHandler:^(NSData* responseData, NSHTTPURLResponse* urlResponse, NSError* error)
				 {
					 NSInteger code = [urlResponse statusCode];
					 code++;
				 }];
			}
		}
	}];

	return TRUE;
}

@end
