//
//  MyProfileViewController.m
//  connected
//
//  Created by Frank Mao on 2013-08-29.
//  Copyright (c) 2013 mazoic. All rights reserved.
//

#import "ContactDetailsViewController.h"
#import "WebApi.h"
#import <Firebase/Firebase.h>
//#import "StackMob.h"

#import "ChatConversationViewController.h"
#import "UIImage+ResizeAdditions.h"
#import "ABContact.h"
#import "AGMedallionView.h"

@interface ContactDetailsViewController ()

@property (nonatomic, strong)     IBOutlet UITableView * tableView;
@end


@implementation ContactDetailsViewController
{
 
    IBOutlet UILabel * nameLabel;
    IBOutlet UIImageView * profileImageView;
 
    IBOutlet UIBarButtonItem * headerBarButtonItem;
    IBOutlet AGMedallionView * medallionView;
 
 
}

@synthesize isSelf = _isSelf;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    medallionView.borderWidth = 0;
    
    self.title = self.contact.contactName;
//    [headerBarButtonItem setTitleTextAttributes:@{UITextAttributeFont: [UIFont fontWithName:kCustomTitleBarFont size:20.0]} forState:UIControlStateNormal];
    headerBarButtonItem.title = NSLocalizedString(@"Contact Info", nil);
    
    [self layoutButtonsForUser];
    [self loadUserProfileImage];
    
   

}



- (void)layoutButtonsForUser
{
 
    nameLabel.text = self.contact.contactName;
 
 
   

}
- (void)loadUserProfileImage
{
   
    UIImage * profileImage = self.contact.image;
    
 
 
    if (profileImage) {
        //UIImageOrientationUpMirrored
        UIImage * profileImage1 = [UIImage imageWithCGImage:profileImage.CGImage
                            scale:profileImage.scale
                                     orientation:UIImageOrientationDownMirrored];
    
        medallionView.image = profileImage1;
//        NSLog(@"imageOrientation: %d", [profileImage imageOrientation]);
//        NSLog(@"profileImage1 imageOrientation: %d", [profileImage1 imageOrientation]);
    }else{
        
        medallionView.image = [UIImage imageNamed:@"Profile_icon_big"];

    }
    
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendSMS:(id)sender
{
    UIView * currentView = (UIView*)sender;
    UIView * parentView;
    while ( ![parentView isKindOfClass:[UITableViewCell class]]) {
        parentView = [currentView superview];
        currentView = parentView;
    }
    
    UITableViewCell * cell = (UITableViewCell*)parentView;
    NSString * cellNumber  = cell.textLabel.text;
    
    
//    NSString * cellNumber = self.contact.possibleCellNumber;
    //    [self.delegate closeModalView:cellNumber];
    
    if (cellNumber != nil && cellNumber.length > 0) {
        
        NSLog(@"sending sms to %@", cellNumber);
//        [WebApi sendSMS:cellNumber text:[NSString stringWithFormat:@"%@ zu coNNected einladen http://connect.com",
//                                         [AppDelegate  currentLoggedUserName]]];
        
 

        
        //        [self dismissViewControllerAnimated:YES completion:^{
        
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init] ;
        NSLog(@"%@", controller);
        if([MFMessageComposeViewController canSendText])
        {
 

            
            controller.body = [NSString stringWithFormat:NSLocalizedString(@"%@ invite you to connect %@", nil),
                               [AppDelegate  currentLoggedUserName], kAppStoreURL];
            controller.recipients = @[cellNumber];
            controller.messageComposeDelegate = self;
          
            [self.navigationController presentViewController:controller animated:YES completion:nil];
        }
        
    }
    
    
    return;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
 
    [[AppDelegate sharedDelegate] customizeTheme];
    
    NSLog(@"MessageComposeResult: %d", result);
    [self dismissViewControllerAnimated:YES completion:nil];
    

 
}


# pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.contact.phoneArray.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1; //self.contact.phoneArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *phoneLabel = (__bridge NSString*) ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)(self.contact.phoneLabels[section]));

    return phoneLabel;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * cellIdentifier = @"cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton * inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
        [inviteButton setBackgroundImage:[[UIImage imageNamed:@"button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
        [inviteButton setTitle:NSLocalizedString(@"Invite", nil) forState:UIControlStateNormal];
        
        
        [inviteButton addTarget:self
                         action:@selector(sendSMS:) forControlEvents:UIControlEventTouchUpInside];
        
        inviteButton.tag = 5;
        
        cell.accessoryView = inviteButton;
        
    }
    
    cell.textLabel.text = self.contact.phoneArray[indexPath.section];
    

    
    

    return cell;
}


# pragma mark - UITableViewDelegate


@end
