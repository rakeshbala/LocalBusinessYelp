//
//  Business.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "Business.h"


@implementation Business


- (instancetype)initWithName:(NSString *)name address:(NSArray *)addElem imageURL:(NSString *)urlString
                    andIndex:(NSIndexPath *)index
{
    self = [super init];
    if (self) {
        self.name = name;
        self.address = [addElem componentsJoinedByString:@", "];
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?",urlString]];
        self.index = index;
    }
    return self;
}

-(void)loadImageWithHandler:(void(^)(void))completionBlock{
    
//    NSLog(@"Loading object at %@",self.index);
    
    NSURLRequest *req = [NSURLRequest requestWithURL:self.imageURL];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * _Nullable response,
                                               NSData * _Nullable data,
                                               NSError * _Nullable connectionError) {

                               if(connectionError){
                                   NSLog(@"%@",connectionError.localizedDescription);
                                   self.image = [UIImage imageNamed:@"error_image_100x100.png"];
                               }else{
                                   UIImage *tempImage = [UIImage imageWithData:data];
                                   if (tempImage.size.width != 80 || tempImage.size.height != 80)
                                   {
                                       CGSize itemSize = CGSizeMake(80, 80);
                                       UIGraphicsBeginImageContextWithOptions(itemSize, NO, 0.0f);
                                       CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                                       [tempImage drawInRect:imageRect];
                                       self.image = UIGraphicsGetImageFromCurrentImageContext();
                                       UIGraphicsEndImageContext();
                                   }
                                   completionBlock();
                               }
                           }];
}



@end
