//
//  PlacePickerViewController.h
//  coNNected
//
//  Created by Frank Mao on 2013-09-23.
//  Copyright (c) 2013 mazoic. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlacePickerDelegate <NSObject>
@required
- (void) handlePickedPlace:(CLLocation*)pickedLocation;
@end

@interface PlacePickerViewController : BaseViewController <CLLocationManagerDelegate>

@property (nonatomic, strong)  id<PlacePickerDelegate>  placePickerDelegate;

@property (nonatomic, strong) CLLocation * pickedPlace;

@property (strong, nonatomic) CLLocationManager *locationManager;
@end
