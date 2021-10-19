// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

#import <MessageUI/MFMailComposeViewController.h>

/**
* Base class for holding code common to many view controllers.
*/
@interface CommonViewController : UIViewController <UIActionSheetDelegate>
{
	IBOutlet UINavigationItem* navItem;
	IBOutlet UIToolbar*        toolbar;
	
	int spinCount;
}

- (void)initializeNavButtonColor;
- (void)startSpinner:(UIActivityIndicatorView*)spinner withDispatch:(BOOL)dispatch;
- (void)stopSpinner:(UIActivityIndicatorView*)spinner;
- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg;
- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg handler:(void (^)(UIAlertAction* action))handler;
- (void)displayEmailComposerSheet:(NSString*)subjectStr withBody:(NSString*)bodyStr withFileName:(NSString*)fileName withMimeType:(NSString*)mimeType withDelegate:(id)delegate;
- (UIImage*)activityTypeToIcon:(NSString*)activityType;
- (BOOL)isDarkModeEnabled;

@property (nonatomic, retain) IBOutlet UINavigationItem* navItem;
@property (nonatomic, retain) IBOutlet UIToolbar*        toolbar;

@end
