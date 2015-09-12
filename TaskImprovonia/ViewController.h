
//
//  ViewController.h
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <NSURLConnectionDelegate,NSURLConnectionDataDelegate,CLLocationManagerDelegate>{
    CLLocationManager *_clMangager;
}

@property (strong,nonatomic) NSMutableData *container;
@property (strong,nonatomic,readonly) CLLocationManager *clManager;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@end

