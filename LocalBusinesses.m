//
//  LocalBusinesses.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/10/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import <Accounts/ACAccountCredential.h>
#import "Constants.h"
#import "Business.h"
#import "ViewController.h"
#import "LocalBusinesses.h"


@implementation LocalBusinesses

-(void)viewDidLoad{
    [super viewDidLoad];
    self.title = LOCAL_BUSINESS_STR;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listItems.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSE_ID forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"yelp_logo_100x100.png"];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.numberOfLines = 0;
    Business *bObj = self.listItems[indexPath.row];
    cell.textLabel.text = bObj.name;
    cell.detailTextLabel.text = bObj.address;
    if(bObj.image != nil){
        cell.imageView.image = bObj.image;
        cell.imageView.hidden = NO;

    }else{
        /************* Load lazily *************/
        UIView *indicator = [cell viewWithTag:20];
        indicator.hidden = NO; //remove loading text
        [bObj loadImageWithHandler:^{
            /************* Update cell after image load completes *************/
            UITableViewCell *cellLater = [tableView cellForRowAtIndexPath:bObj.index];
            cellLater.imageView.image=bObj.image;
            UIView *indicator = [cell viewWithTag:20];
            indicator.hidden = YES;
            cell.imageView.hidden = NO;
        }];
    }
    return cell;
}

-(void)viewWillDisappear:(BOOL)animated{
    ViewController *vc = self.navigationController.viewControllers[0];
    [vc.loadingView stopAnimating];
}

@end
