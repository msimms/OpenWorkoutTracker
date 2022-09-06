// Created by Michael Simms on 9/5/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface LargeAlertController : CommonViewController<UITextViewDelegate>
{
@public
	NSString* title;
	NSString* subtitle;
	NSString* defaultText;
	UITextView* textView;
	void (^completionHandler)(NSString* text);
}

@end
