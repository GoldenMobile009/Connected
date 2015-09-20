//
//  MapViewController.h
//  GPS App
//
//  Created by Frank Mao on 2013-08-28.
//  Copyright (c) 2013 Frank Mao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "BaseViewController.h"

@interface MapViewController : BaseViewController


@property (nonatomic, weak) IBOutlet MKMapView * mapView;

@property (nonatomic, strong) NSMutableDictionary * userInfo;

@property (nonatomic, assign) BOOL waitingForAccept;

@property (nonatomic, strong) NSString * connectId;
@property (nonatomic, assign) BOOL isCreator;
@property (nonatomic, strong) CLLocation * meetPlace;
@property (nonatomic, strong) NSSet * userIdList; // only for multiple connect. should include creator itself
@property (nonatomic, strong) NSMutableDictionary * userNameDict;

- (void)handleLocationNotification;
@end
