//
//  MapViewController.m
//  GPS App
//
//  Created by Frank Mao on 2013-08-28.
//  Copyright (c) 2013 Frank Mao. All rights reserved.
//

#import "MapViewController.h"
#import "MBProgressHUD.h"
#import "WebApi.h"
#import "PBKAnnotation.h"
#import "CircleAnnotation.h"

@interface MapViewController ()

@end

enum ALERT_TYPE {
    ALERT_REJECT = 1,
    ALERT_ACCEPT ,
    ALERT_TERMINATE
    };

@implementation MapViewController{
    MKPolyline *_polyLine1;
    MKPolyline *_polyLine2;
 
    NSArray * _path1;
    NSArray * _path2;
    
    BOOL _mapZoomed;
 
    
    BOOL _msgHasBeenSent;
    BOOL _invitationAccepted;
    BOOL _waitingForLocation;
    
    IBOutlet UILabel * _distanceInfoLbl;
    IBOutlet UILabel * _durationInfoLbl;
    
    IBOutlet UIButton * _drivingButton;
    IBOutlet UIButton * _transitButton;
    IBOutlet UIButton * _bicyclingButton;
    IBOutlet UIButton * _walkingButton;
    
    MBProgressHUD * _HUD;
    
    CLLocation * _meetPlace;
}



@synthesize mapView = _mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Map", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"globe_24"];
        _meetPlace = nil;

    }
    return self;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [AppDelegate sharedDelegate].currentConnectedId = nil;
    [AppDelegate sharedDelegate].meetPlace = nil;
   
}

- (void)stopLocationUpdate
{
    // note, will delay about 5 seconds after the location icon disappear from status bar.
    [[AppDelegate sharedDelegate]  stopGettingLocation];
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    
    // only do this after the other side accept invitation
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationUpdatedNotification object:nil];
    
    NSLog(@"location service stopped!!!!");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _mapZoomed = FALSE;
    self.userInfo = [NSMutableDictionary dictionary];
    self.userNameDict = [NSMutableDictionary dictionary];
    
    _distanceInfoLbl.text = @"";
    _durationInfoLbl.text = @"";
 
    _drivingButton.selected = YES;
    _invitationAccepted = NO;
    _HUD.hidden = YES;
    
    // only do this after the other side accept invitation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLocationNotification) name:kLocationUpdatedNotification object:nil];
    // Do any additional setup after loading the view from its nib.

    [[AppDelegate sharedDelegate] tryToGetLocation];
    _waitingForLocation = YES;
    
    if ([AppDelegate sharedDelegate].userLocation.coordinate.latitude == 0
        && [AppDelegate sharedDelegate].userLocation.coordinate.longitude == 0) {
        
        [self popupWaitingView:NSLocalizedString(@"Getting current location, please ensure location service is on.\n\n", nil) showSpinner:YES showCancelButton:NO];
        return;
    }
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)viewWillAppear:(BOOL)animated

{
    if (!self.meetPlace &&  !_invitationAccepted && _isCreator)
     {
         [self showWaitingAcceptSpinner];
     }
    if (self.meetPlace != nil) {
        
        [self placePinForMeetPlace];
        //[self placePinForMember];
        
    }
    self.navigationItem.hidesBackButton = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                              target:self
                                              action:@selector(cancelConnectSession)];
    

}

- (void)cancelConnectSession
{
    // TODO: ask for confirmation
    
    [self stopLocationUpdate];
    
    // popup user cancel popup on the other side screen.
    // for mutiple, show pin title as 'Cancelled'
    [[WebApi shared] terminateConnectSession:self.connectId completionBlock:^(NSError *err) {
        //
        NSLog(@"cancel current connection.");

    }];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)prepareShowRoute
{
   
    if (self.isCreator) {
        
        if (self.meetPlace) {
            [self displayRouteCore:nil];
        }
       
        for (NSString * userId in self.userIdList) {
            [[WebApi shared] getConnectResponse:self.connectId
                                         userId:userId
                                completionBlock:^(NSError *err, NSDictionary *dict) {
                                    //
                                    NSLog(@"getConnectResponse dict: %@", dict);
                                    if (dict[@"data"]) {
                                        [self handleInvitationResponse:dict[@"data"]];
                                        
                                    }
                                }];
        }

    }else{

        if (_meetPlace == nil){
            NSString * partnerName = @"partner";
            
            if (_userNameDict.count == 1) {
                partnerName = [[_userNameDict allValues] lastObject];
            }
            //[self popupWaitingView:[NSString stringWithFormat:NSLocalizedString(@"Getting %@'s location...", nil), partnerName] showSpinner:YES showCancelButton:NO];
        }
        for (NSString * userId in self.userIdList) {
            // should only do this after user accept invitation for creator
            [[WebApi shared] getUserLocation:userId completionBlock:^(NSError *err, NSDictionary *dict) {
                
                [self.userInfo setObject:dict[@"data"] forKey:userId];
                NSLog(@"the user %@ 's location: %@", userId, self.userInfo);
                    [self displayRouteCore:nil];
            }];
        }

        [self startMonitorTerminationFlag];
        
    }

}

- (void)startMonitorTerminationFlag
{
    for (NSString * userId in self.userIdList) {
        [[WebApi shared] getUserTemintatedTimeForConnectSession:self.connectId
                                                         userId:userId
                                                completionBlock:^(NSError *err, NSDictionary *dict) {
            
            if (dict[@"data"] != [NSNull null] && [dict[@"data"] doubleValue] > 0) {
                
                
                NSLog(@"%@ terminated session! at %f", _userNameDict[userId], [dict[@"data"] doubleValue] );
                
                // TODO: change message for multi connect: someone has left this connect.
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:NSLocalizedString(@"Connect session has been cancelled by partner.", nil)
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil, nil];
                alert.tag = ALERT_TERMINATE;
                [alert show];
                
                
                // remove that user's pin from map
                
                for (id annotation in _mapView.annotations) {
                    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
                        MKPointAnnotation * annot= (MKPointAnnotation *)annotation;
                        
                        if ([[annot title] isEqualToString:_userNameDict[userId] ] )
                        {
                            [_mapView removeAnnotation:annotation];
                        }
                    }
                }
                
                // TODO: if there is no user to connect. mark connect status as cancelled.
                // no the late user accept will get a connect has been cancelled status right after accepted.
            }
        }];
    }

}
- (IBAction)selectTravelMode:(id)sender{
    _drivingButton.selected = NO;
    _transitButton.selected = NO;
    _bicyclingButton.selected = NO;
    _walkingButton.selected = NO;
    
    UIButton*  selectedButton =  (UIButton*)sender;
    selectedButton.selected = YES;
    
    [self displayRouteCore:nil];
}


- (TRAVEL_MODE)getTravelMode
{
    if (_drivingButton.selected) {
        return TRAVEL_MODE_DRIVING;
    }
    if (_transitButton.selected) {
        return TRAVEL_MODE_TRANSIT;
    }
    if (_bicyclingButton.selected) {
        return TRAVEL_MODE_BICYCLING;
    }
    if (_walkingButton.selected)
    {
        return TRAVEL_MODE_WALKING;
    }
    
    return TRAVEL_MODE_DRIVING;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleLocationNotification
{
    if (_waitingForLocation) {
        
        [self performSelector:@selector(prepareShowRoute) withObject:nil afterDelay:0.1];
        _waitingForLocation = NO;
        
    }else{
        [self displayRouteCore:nil];
    }
}

- (IBAction)displayRouteCore:(id)sender
{

    if ([AppDelegate sharedDelegate].userLocation.coordinate.latitude == 0
        && [AppDelegate sharedDelegate].userLocation.coordinate.longitude == 0) {
       
        [self popupWaitingView:NSLocalizedString(@"Your location info is not available, please enable location service.",nil) showSpinner:YES showCancelButton:NO];
        return;
    }
    
  
    CLLocationCoordinate2D location2;
    
    if (self.meetPlace != nil) {
            
        location2 = self.meetPlace.coordinate;
        
        [self placePinForMeetPlace];
        [self placePinForMember];
        
    }else{

        if (_userInfo == nil) {
            assert(@"userinfo can't be nil!");
        }
        if ([_userInfo isKindOfClass:[NSNull class]]){
            NSString * partnerName = @"partner";
            
            if (_userNameDict.count == 1) {
                partnerName = [[_userNameDict allValues] lastObject];
            }
            [self popupWaitingView:[NSString stringWithFormat:@"Getting %@'s location...", partnerName] showSpinner:YES showCancelButton:NO];
            return;
            
        }else{
           
            NSString * partnerId = [[_userInfo allKeys] lastObject];
            double lat = [[_userInfo objectForKey:partnerId][@"lat"] doubleValue];
            double lon = [[_userInfo objectForKey:partnerId][@"lon"] doubleValue];
            if (lat == 0 && lon == 0) {
                NSLog(@"0/0 location, skip.");
                return;
            }
            location2 = CLLocationCoordinate2DMake( lat, lon);
            
//          [self closeWaitingView];
            [self placePinForMember];
        }
    }
    //Debug only
    //[self closeWaitingView];
    //[self zoomToFitMapAnnotations:_mapView]; // might need to only do this at first time
    //Commented for Debug purpose
    dispatch_async(dispatch_get_main_queue(), ^{
        _distanceInfoLbl.text = @"Calculating route";
        [self popupWaitingView: @"Calculating route" showSpinner:YES showCancelButton:NO];
         
    });
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // Do something...
        [self calcRoute:location2];
    });
    
    
//
    
}

- (void)calcRoute:( CLLocationCoordinate2D) location2
{
    [WebApi getRouteBetween:[AppDelegate sharedDelegate].userLocation.coordinate.latitude
                       lon1:[AppDelegate sharedDelegate].userLocation.coordinate.longitude
                       lat2:location2.latitude
                       lon2:location2.longitude
                 travelMode:[self getTravelMode]
            completionBlock:^(NSDictionary *routeInfo) {
                
                
                _path1 = routeInfo[@"direction"];

                _distanceInfoLbl.text = @"";
                _durationInfoLbl.text = @"";
                if (!_path1 || [_path1 isKindOfClass:[NSDictionary class]]) {
                    
                    NSString * errMsg = [(NSDictionary*)routeInfo objectForKey:@"status"];
                    
                    if (errMsg == nil || [errMsg isKindOfClass:[NSNull class]] || [errMsg isEqualToString:@"(null)"])
                    {
                        errMsg = @"";
                    }
                    
                    _distanceInfoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"no route info %@", nil), errMsg];
//                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self closeWaitingView];
               
//                    });
                    return;
                }
                
                _distanceInfoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"distance: %@", nil),
                                         routeInfo[@"distance"][@"text"] ];
                _durationInfoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"time: %@", nil),
                                         
                                         routeInfo[@"duration"][@"text"]];
                
                NSInteger numberOfSteps = _path1.count;
                
                CLLocationCoordinate2D coordinates[numberOfSteps];
                for (NSInteger index = 0; index < numberOfSteps; index++) {
                    CLLocation *location = [_path1 objectAtIndex:index];
                    CLLocationCoordinate2D coordinate = location.coordinate;
                    
                    coordinates[index] = coordinate;
                }
                 MKPolyline * newPloyLIne = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
               
                
                 dispatch_async(dispatch_get_main_queue(), ^{
                    [_mapView removeOverlay:_polyLine1];
                    [_mapView addOverlay:newPloyLIne];
                     _polyLine1 = newPloyLIne;
                         [self closeWaitingView];
                 
                 });
                
            }
     ];

}

- (void)zoomToFitMapAnnotations:(MKMapView *)mapView {
    NSMutableArray * allLocaitons = [NSMutableArray arrayWithArray:_path1];
//    if ([_path1 count] == 0) return;
    
    
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        [allLocaitons addObject: [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude]];
    }
    //append the self location
    CLLocation *curLocation = [[AppDelegate sharedDelegate] userLocation];
    if (curLocation.coordinate.latitude == 0
        && curLocation.coordinate.longitude == 0) {
        
        [self popupWaitingView:NSLocalizedString(@"Getting current location, please ensure location service is on.\n\n", nil) showSpinner:YES showCancelButton:NO];
        return;
    }
    else{
        [allLocaitons addObject:curLocation];
    }
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for(CLLocation * item in allLocaitons) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, item.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, item.coordinate.latitude);
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, item.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, item.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1;
    
    // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1;
    
    region = [mapView regionThatFits:region];
    [mapView setRegion:region animated:YES];
}
# pragma mark - route
/*- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    polylineView.strokeColor = [UIColor blueColor];
    polylineView.lineWidth = 6.0;
    
    return polylineView;
}*/
- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.strokeColor = [UIColor blueColor];
    renderer.lineWidth = 6.0;
    return renderer;
}


//- (MKAnnotationView *)viewForAnnotation:(id < MKAnnotation >)annotation
- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
//    MKPinAnnotationView *pinView = nil;
	if(annotation == _mapView.userLocation || [annotation isKindOfClass:[MKUserLocation class]]) return nil;
	 


        if ([annotation isKindOfClass:[PBKAnnotation class]] ) {
            // meet place
            static NSString *annotationViewIDForMeetPlace = @"annotationViewIDForMeetPlace";
            
            MKAnnotationView *annotationView = (MKAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:annotationViewIDForMeetPlace];
            
            if (annotationView == nil)
            {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationViewIDForMeetPlace]  ;
            }
            
            annotationView.image = [UIImage imageNamed:@"destination_pin.png"];
            //		pinView.pinColor = MKPinAnnotationColorRed;
            annotationView.canShowCallout = YES;
            //		annotationView.animatesDrop = YES;
            
            return annotationView;
           
            
        }
        else if([annotation isKindOfClass:[CircleAnnotation class]] )
        {
            static NSString *annotationViewIDForPeople = @"annotationViewIDForPeople";
            
            MKAnnotationView *annotationView = (MKAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:annotationViewIDForPeople];
            
            if (annotationView == nil)
            {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationViewIDForPeople]  ;
            }
            
            CircleAnnotation * annot = (CircleAnnotation*)annotation;
            int tag = annot.tag;
            
            NSString * imageName = [NSString stringWithFormat:@"point_%d.png", tag + 1];
            annotationView.image = [UIImage imageNamed:imageName];
            //		pinView.pinColor = MKPinAnnotationColorRed;
            annotationView.canShowCallout = YES;
            //		annotationView.animatesDrop = YES;
            
            return annotationView;
             
        }
        else {
            static NSString *defaultPinID = @"com.invasivecode.pin";
            MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
            
            if (annotationView == nil)
            {
                annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID]  ;
            }
            
            annotationView.pinColor = MKPinAnnotationColorPurple;
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = YES;
            
            return annotationView;

        }

}

- (void)showWaitingAcceptSpinner
{
    if (self.meetPlace) {
        return;
    }
    
    NSString * msg = [NSString stringWithFormat:NSLocalizedString(@"Waiting for %@ to accept your connect request ...\n\n", nil),
                      [[AppDelegate sharedDelegate].allUsers objectForKey:[[self.userIdList allObjects] lastObject]][@"name"]];
    [self popupWaitingView:msg showSpinner:YES showCancelButton:NO];
 

    
    
}

- (void)handleInvitationResponse:(NSDictionary*)dict
{
    if (![self.connectId isEqualToString:dict[@"connectId"]]) {
        NSLog(@"expired response");
        return;
    }
    
    if ([dict[@"response"] integerValue] == 1) {
        //accept

        _invitationAccepted = YES;
        
        if (self.userIdList.count == 1 && self.meetPlace == nil) {
            NSString * partnerName = @"partner";
            
            if (_userNameDict.count == 1) {
                partnerName = [[_userNameDict allValues] lastObject];
            }
            [self popupWaitingView:[NSString stringWithFormat:NSLocalizedString(@"Getting %@'s location...", nil), partnerName] showSpinner:YES showCancelButton:NO];
        }else{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"%@ has joined your connect.", nil), dict[@"user_name"]]
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                   otherButtonTitles:nil, nil];
            alert.tag = ALERT_ACCEPT;
            [alert show];
        }
        
        for (NSString * userId in self.userIdList) {
            // should only do this after user accept invitation for creator
            [[WebApi shared] getUserLocation:userId completionBlock:^(NSError *err, NSDictionary *dict) {
                
                
                if (dict[@"data"] && dict[@"data"][@"lat"] && dict[@"data"][@"lon"]) {
                    
                    [self.userInfo setObject:dict[@"data"] forKey:userId];
                   
                    // if it's direct connect
                    if (!self.meetPlace)
                    {

                        [self displayRouteCore:nil];
                        
                    }else{
                        [self placePinForMember];

                    }
                }
                
            }];
        }

        
        // TODO: write this connectId to both sides' history tab. if only want to do success connect in history.
        
        [self startMonitorTerminationFlag];
        
    
    }else if([dict[@"response"] integerValue] == -1)
    {
        NSLog(@"invitation rejected");
        
        if (self.meetPlace) {
            
            NSLog(@"connect request response %@", dict);
            

        }else{
            
            [self closeWaitingView];
        
 
 
        }
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"Sorry, but %@ rejected your connect invitation.", nil), dict[@"user_name"]]
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                               otherButtonTitles:nil, nil];
        alert.tag = ALERT_REJECT;
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
 
    if (_userIdList.count == 1
        && (
        
         alertView.tag == ALERT_TERMINATE
            ||
            
         alertView.tag == ALERT_REJECT
            
            )
        ){
   
        [[AppDelegate sharedDelegate] stopGettingLocation];
        
        [self.navigationController popViewControllerAnimated:YES];
        [self.mapView removeFromSuperview];

        self.userInfo = nil;
        self.meetPlace = nil;
        self.mapView.delegate = nil;
        self.mapView = nil;
        self.userIdList = nil;
//        self.connectId = nil;
        
    }
    
}
- (void)popupWaitingView:(NSString *)msg showSpinner:(BOOL)showSpinner showCancelButton:(BOOL)showCancelButton
{
    if (!_HUD) {
        _HUD =  [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    }
    
    _HUD.labelText = NSLocalizedString(@"Waiting...", nil);
    _HUD.detailsLabelText = msg;

    [_HUD show:YES];
    return;
 
}

- (void)closeWaitingView
{
    [_HUD hide:YES];
}

- (void)placePinForMeetPlace
{
 
    PBKAnnotation* annotation = [[PBKAnnotation alloc] initWithCoordinate:_meetPlace.coordinate
                                                                     name:NSLocalizedString(@"Meet Place", nil)];
    [_mapView addAnnotation:annotation];
    
}

- (void)placePinForMember
{
    //return;
    for (id annotation in _mapView.annotations) {
        if(annotation != _mapView.userLocation && ![annotation isKindOfClass:[PBKAnnotation class]])
        {
            [_mapView removeAnnotation:annotation];
            
        }
    }
    if ([_userInfo isKindOfClass:[NSNull class]]) {
        NSLog(@"no user info");
    }else{
        
        for (NSString * userId in self.userInfo.allKeys) {
            
            CLLocationCoordinate2D  location2 = CLLocationCoordinate2DMake([[_userInfo objectForKey:userId][@"lat"] doubleValue] , [[_userInfo objectForKey:userId][@"lon"] doubleValue]);
            
            CircleAnnotation *annot = [[CircleAnnotation alloc] initWithCoordinate:location2 name:_userNameDict[userId]];
       
            annot.tag = [_userNameDict.allKeys indexOfObject:userId];
            
            [_mapView addAnnotation:annot];
        }
    }
    if (!_mapZoomed){
        [self zoomToFitMapAnnotations:self.mapView];
        _mapZoomed = YES;
    }
}



@end
