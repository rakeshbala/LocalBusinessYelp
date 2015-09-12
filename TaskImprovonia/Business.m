//
//  Business.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "Business.h"

#define img_size 80

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


/************* Load image and call the completion handler block *************/
-(void)loadImageWithHandler:(void(^)(void))completionBlock{
    
    NSURLRequest *req = [NSURLRequest requestWithURL:self.imageURL];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * _Nullable response,
                                               NSData * _Nullable data,
                                               NSError * _Nullable connectionError) {

                               if(connectionError){
                                   NSLog(@"%@",connectionError.localizedDescription);
                                   self.image = [UIImage imageNamed:@"error_image_80x80.png"];
                               }else{
                                   UIImage *tempImage = [UIImage imageWithData:data];
                                   /************* Reduce size of image if it is not 80x80 *************/
                                   if (tempImage.size.width != img_size || tempImage.size.height != img_size)
                                   {
                                       CGSize itemSize = CGSizeMake(img_size, img_size);
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
