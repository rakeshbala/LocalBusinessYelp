//
//  Business.h
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Business : NSObject 
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSIndexPath * index;

-(void)loadImageWithHandler:(void(^)(void))completionBlock;
- (instancetype)initWithName:(NSString *)name address:(NSArray *)addElem imageURL:(NSURL *)url
                    andIndex:(NSIndexPath *)index;
@end
