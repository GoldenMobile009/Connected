//
//  ContactSyncProgressView.m
//  GPS App
//
//  Created by Frank Mao on 2013-08-30.
//  Copyright (c) 2013 Frank Mao. All rights reserved.
//

#import "ContactSyncProgressView.h"

@implementation ContactSyncProgressView
{
    float _progress;
    UIView * _parentView;
}

@synthesize progressBar = _progressBar;
@synthesize progressBackground = _progressBackground;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"ContactSyncProgressView" owner:self options:nil];
//        [_parentView addSubview:self];
        [self addSubview:self.view];
        self.view.center = _parentView.center;
        
//        if (!self.animator) {
//            self.animator =  [NSTimer scheduledTimerWithTimeInterval:0.1
//                                                              target:self
//                                                            selector:@selector(activateAnimation:)
//                                                            userInfo:nil
//                                                             repeats:YES];
//
//        }
        
    }
    return self;
}

- (id)initWithView:(UIView *)view {
	NSAssert(view, @"View must not be nil.");
    _parentView = view;
	id me = [self initWithFrame:view.bounds];
	// We need to take care of rotation ourselfs if we're adding the HUD to a window
	if ([view isKindOfClass:[UIWindow class]]) {
//		[self setTransformForCurrentOrientation:NO];
	}
	return me;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // commenters report the next line causes infinite recursion, so removing it
    // [[NSBundle mainBundle] loadNibNamed:@"MyView" owner:self options:nil];
    [self addSubview:self.view];
    self.view.center = _parentView.center;    
 
    self.progress = 0;
    
//    self.progressBar.contentMode = UIViewContentModeRedraw;
//    self.finishedCountLbl.contentMode = UIViewContentModeRedraw;
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 */
//- (void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
//    
//    // Drawing code
//    NSLog(@"redrawing...");
//    self.finishedCountLbl.text = [NSString stringWithFormat:@"%d", self.finishedCount];
//}

- (void)setFinishedCount:(int)finishedCount
{
    self.finishedCountLbl.text = [NSString stringWithFormat:@"%d", finishedCount];
    [self setNeedsLayout];
 
}

- (void)setTotalCount:(int)totalCount
{
    self.totalCountLbl.text = [NSString stringWithFormat:@"%d", totalCount];
 
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    self.progressBar.frame =
    CGRectMake(_progressBackground.frame.origin.x,
               _progressBackground.frame.origin.y,
               _progressBackground.frame.size.width * progress,
               _progressBackground.frame.size.height);

    [self setNeedsLayout];
    
    NSLog(@"bar width: %f", _progressBackground.frame.size.width * progress);
    
    if (progress >= 1) {
//        [self.animator invalidate];
//        self.animator = nil;
    }
    
}
- (void)hide:(BOOL)animated {
    [self.view removeFromSuperview];
}

-(void)activateAnimation:(NSTimer*)timer {
    float progressValue = _progress;
    progressValue += 0.01;
    
    [self setProgress:progressValue];
    
//    [self setNeedsDisplay];
}
@end
