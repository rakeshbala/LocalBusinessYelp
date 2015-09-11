//
//  LocalBusinesses.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "LocalBusinesses.h"
#import <Accounts/ACAccountCredential.h>

@interface LocalBusinesses ()

@end

@implementation LocalBusinesses



- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.listItems = [NSMutableArray arrayWithCapacity:50];
        for (int i=0; i<50; i++) {
            [self.listItems addObject:@(i)];
        }
    }
    return self;
}
    

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuse" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",self.listItems[indexPath.row]];
    return cell;
}




@end
