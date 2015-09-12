//
//  LocalBusinesses.h
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocalBusinesses : UITableViewController
@property (strong) NSJSONSerialization *businessJSON;
@property (strong) NSMutableArray *listItems;
@end
