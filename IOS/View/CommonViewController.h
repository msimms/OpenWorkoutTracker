// Created by Michael Simms on 9/23/18.
// Copyright (c) 2018 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>

@interface CommonViewController : UIViewController <UIActionSheetDelegate>
{
}

- (void)showOneButtonAlert:(NSString*)title withMsg:(NSString*)msg;

@end
