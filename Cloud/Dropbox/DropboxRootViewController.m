//
//  DropboxRootViewController.m
//
//  Created by Michael Simms on 8/11/12.
//  Copyright (c) 2012 Michael J. Simms. All rights reserved.
//

#import "DropboxRootViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface DropboxRootViewController () <DBRestClientDelegate>

@property (nonatomic, readonly) DBRestClient* restClient;

@end

@implementation DropboxRootViewController

@synthesize activityIndicator;
@synthesize dropbox;

- (id)initWithCoder:(NSCoder*)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		self.title = @"Link Account";
	}
	return self;
}

- (void)linkUnlink
{
	if ([[DBSession sharedSession] isLinked])
	{
		[[DBSession sharedSession] unlinkAll];
	}
	else
	{
		[[DBSession sharedSession] linkFromController:self];
	}
}

#pragma mark button handlers

- (IBAction)onLink:(id)sender
{
	[self linkUnlink];
}

- (IBAction)onHome:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:TRUE];	
}

#pragma mark UIViewController methods

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = @"Link Account";

	[self linkUnlink];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{	
	[super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		return toInterfaceOrientation == UIInterfaceOrientationPortrait;
	return YES;
}

#pragma mark DBRestClient delegate

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)srcPath
{
	[self.activityIndicator stopAnimating];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
	[self.activityIndicator stopAnimating];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
}

#pragma mark DBRestClient constructor

- (DBRestClient*)restClient
{
	if (restClient == nil)
	{
		restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		restClient.delegate = self;
	}
	return restClient;
}

@end
