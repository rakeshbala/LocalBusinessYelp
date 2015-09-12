//
//  LocalBusinesses.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "LocalBusinesses.h"
#import <Accounts/ACAccountCredential.h>
#import "Constants.h"

@interface LocalBusinesses ()

@end

@implementation LocalBusinesses



-(void)viewDidLoad{
    [super viewDidLoad];
    self.title = @"Local Businesses";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSE_ID forIndexPath:indexPath];
    cell.textLabel.text = [self.listItems[indexPath.row] valueForKey:@"name"];
    return cell;
}



@end
