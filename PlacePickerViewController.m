//
//  PlacePickerViewController.m
//  coNNected
//
//  Created by Frank Mao on 2013-09-23.
//  Copyright (c) 2013 mazoic. All rights reserved.
//

#import "PlacePickerViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PBKAnnotation.h"

@interface PlacePickerViewController ()

@end

@implementation PlacePickerViewController{
    IBOutlet MKMapView *mapView;
    IBOutlet UIBarButtonItem *titleBarButton;
 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [titleBarButton setTitle: NSLocalizedString(@"Long tap to pick a place", nil)];
    
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
                                                                                          action:@selector(cancelLocationPicking)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
                                                                                           action:@selector(doneLocationPicking)];
    [self zoomToUserLocation];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //user needs to press for n seconds
    [mapView addGestureRecognizer:lpgr];
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [mapView setShowsUserLocation:YES];
//    [mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
}
-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [mapView setShowsUserLocation:NO];
}


- (void)cancelLocationPicking
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneLocationPicking
{
    if ((mapView.annotations.count == 1)) { //user location
        return ;
    }
 
    for (id annotation in mapView.annotations) {
        if ([annotation isKindOfClass:[PBKAnnotation class]]) {
            PBKAnnotation * ann = (PBKAnnotation*)annotation;
            
            self.pickedPlace = [[CLLocation alloc] initWithLatitude:ann.coordinate.latitude longitude:ann.coordinate.longitude];
            
            [self dismissViewControllerAnimated:NO completion:^{
                [self.placePickerDelegate handlePickedPlace:self.pickedPlace];
            }];
        }
    }
  
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)zoomToUserLocation
{
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 250; //50; //kCLDistanceFilterNone;//100;//kCLDistanceFilterNone; //kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined &&
            [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        if ([CLLocationManager locationServicesEnabled]){
            [self.locationManager startUpdatingLocation];
        }else{
            [AppDelegate showMessage:@"Location service not enabled."];
        }
    }
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    
    
    for (id annotation in mapView.annotations) {
        if (annotation == mapView.userLocation) {
            continue;
        }
        [mapView removeAnnotation:annotation];
    }
    
//    MKPointAnnotation *annot = [[MKPointAnnotation alloc] init];
//    annot.title = @"Place to Meet";
//    annot.coordinate = touchMapCoordinate;
    
    PBKAnnotation* annotation = [[PBKAnnotation alloc] initWithCoordinate:touchMapCoordinate
                                                                     name:NSLocalizedString(@"Meet Place", nil)];
    
    self.pickedPlace = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    [mapView addAnnotation:annotation];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation

//- (MKAnnotationView *)viewForAnnotation:(id < MKAnnotation >)annotation
{
    MKPinAnnotationView *pinView = nil;
	if(annotation != mapView.userLocation)
	{
        static NSString *AnnotationViewID = @"annotationViewID";
        
        MKAnnotationView *annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
        
        if (annotationView == nil)
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID]  ;
        }
        
        annotationView.image = [UIImage imageNamed:@"destination_pin.png"];
//		pinView.pinColor = MKPinAnnotationColorRed;
		annotationView.canShowCallout = YES;
        annotationView.draggable = YES;
//		annotationView.animatesDrop = YES;
        
        return annotationView;
    }
	else {
		//[mapView.userLocation setTitle:@"I am here"];
        return nil;
	}
	return pinView;
}
# pragma mark - locatoin

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationInfoFailureNotification object:nil];
    NSLog(@"location didFailWithError: %@", [error localizedDescription]);
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{

    CLLocation * userloc = [locations lastObject];

    MKCoordinateRegion region = MKCoordinateRegionMake(userloc.coordinate, MKCoordinateSpanMake(kMapDeltaMedium,kMapDeltaMedium));
    [mapView setRegion:region animated:YES];
//    [mapView setCenterCoordinate:userloc.coordinate animated:YES];
//    mapView.showsUserLocation = YES;
//    [mapView setCenterCoordinate:mapView.userLocation.location.coordinate animated:YES];
    
    if (self.pickedPlace.coordinate.longitude == 0 && self.pickedPlace.coordinate.latitude == 0) {
        
    }else{
        PBKAnnotation *annot = [[PBKAnnotation alloc] init];
        annot.coordinate = self.pickedPlace.coordinate;
        
        [mapView addAnnotation:annot];
    }
    [self.locationManager stopUpdatingLocation];
}


@end
