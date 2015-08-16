//
//  DropboxRootViewController.h
//
//  Created by Michael Simms on 8/11/12.
//  Copyright (c) 2012 Michael J. Simms. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DropboxSDK.h"
#import "Dropbox.h"

@class DBRestClient;

@interface DropboxRootViewController : UIViewController
{
    UIActivityIndicatorView* activityIndicator;
	DBRestClient*            restClient;
	Dropbox*                 dropbox;
}

- (void)linkUnlink;

- (IBAction)onLink:(id)sender;
- (IBAction)onHome:(id)sender;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic, retain) Dropbox* dropbox;

@end
