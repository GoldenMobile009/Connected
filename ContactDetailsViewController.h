//
//  MyProfileViewController.h
//  connected
//
//  Created by Frank Mao on 2013-08-29.
//  Copyright (c) 2013 mazoic. All rights reserved.
//

#import "BaseViewController.h"
#import "WebApi.h"
#import "ABContact.h"
#import <MessageUI/MFMessageComposeViewController.h>


@interface ContactDetailsViewController : BaseViewController<UIActionSheetDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate
, MFMessageComposeViewControllerDelegate
>




@property (nonatomic, strong) ABContact * contact;
@property (nonatomic, assign) BOOL isSelf;
@end
