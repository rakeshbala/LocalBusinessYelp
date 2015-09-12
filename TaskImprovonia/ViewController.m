//
//  ViewController.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//
#import "ViewController.h"
#import "OAuthClass.h"
#import "Constants.h"
#import "LocalBusinesses.h"
#import "AppDelegate.h"
#import "Business.h"

@interface ViewController ()
@property (strong, nonatomic) NSURLConnection *conn;
@property (strong, nonatomic) CLLocation *location;
@property (strong,nonatomic) NSJSONSerialization *bJSON;
@end

@implementation ViewController

@dynamic clManager;

-(CLLocationManager *)clManager{
    if(_clMangager == nil){
        _clMangager = [[CLLocationManager alloc]init];
        [_clMangager requestWhenInUseAuthorization];
    }
    return _clMangager;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    /****** Setup data container , connection and location manager ****/
    self.container = [NSMutableData data];
    self.clManager.delegate = self;
    self.clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.clManager.distanceFilter = 30;
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if(self.bJSON != nil){
        LocalBusinesses *lTVC = [segue destinationViewController];
        NSMutableArray *bussinessList = [NSMutableArray array];
        NSMutableArray *tempList =[self.bJSON valueForKey:BUSINESSES_KEY];
        for (int i=0; i< tempList.count; i++) {
            NSDictionary *bDict = tempList[i];
            NSArray *address = bDict[@"location"][@"display_address"];
            NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:0];
            Business *bObj = [[Business alloc]initWithName:bDict[@"name"]
                                                   address:address
                                                  imageURL:bDict[@"image_url"]
                                                  andIndex:ind];
            [bussinessList addObject:bObj];
        }
        lTVC.listItems = bussinessList;
    }
}


- (IBAction)startLocationAndAskYelp:(id)sender {
    
    if (self.bJSON != nil) {
        [self performSegueWithIdentifier:SEGUE_DETAIL sender:sender];
    }
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
        [self.clManager startUpdatingLocation];
    }else{

        [[[UIAlertView alloc]initWithTitle:NOT_AUTHORIZED
                                   message:NO_PERMISSIONS_DESC
                                  delegate:nil
                         cancelButtonTitle:OK_BUTTON_TITLE
                         otherButtonTitles:nil] show];
    }
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    [self.clManager stopUpdatingLocation];
    NSLog(@"Recorded location: %@",locations);
    self.location = [locations firstObject];
    [self.loadingView startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    OAuthClass *oCl = [[OAuthClass alloc]init];
    NSString *locationString = [NSString stringWithFormat:@"%f,%f",
                                self.location.coordinate.latitude,self.location.coordinate.longitude];
    NSDictionary *params = @{
                             @"ll": locationString,
                             @"limit": @20
                             };
    NSMutableURLRequest *req = [oCl createRequestWithParams:params];
    self.conn = [[NSURLConnection alloc]initWithRequest:req delegate:self startImmediately:NO];
    [self.conn start];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.container appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
//    NSString *fullResponse = [[NSString alloc]initWithData:self.container encoding:NSUTF8StringEncoding];
//    NSLog(@"%@",fullResponse);
    NSError *error;
    self.bJSON = [NSJSONSerialization JSONObjectWithData:self.container
                                                                options:NSJSONReadingMutableContainers error:&error];
//    NSLog(@"%@",self.bJSON);
    
    [self performSegueWithIdentifier:SEGUE_DETAIL sender:nil];
    [self.loadingView stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

}


//Stub
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"%@",error.localizedDescription);
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    //    NSLog(@"%@",response);
}
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@",error.localizedDescription);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
