//
//  ContactSyncProgressView.h
//  GPS App
//
//  Created by Frank Mao on 2013-08-30.
//  Copyright (c) 2013 Frank Mao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactSyncProgressView : UIView

@property (nonatomic, strong) NSTimer * animator;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) int finishedCount;
@property (nonatomic, assign) int totalCount;
@property (nonatomic, retain) IBOutlet UIView *view;
@property (nonatomic, retain) IBOutlet UILabel *finishedCountLbl;
@property (nonatomic, retain) IBOutlet UILabel *totalCountLbl;

@property (nonatomic, retain) IBOutlet UIImageView * progressBar;
@property (nonatomic, retain) IBOutlet UIImageView * progressBackground;

- (id)initWithView:(UIView *)view;
- (void)hide:(BOOL)animated ;
@end
