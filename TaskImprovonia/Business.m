//
//  Business.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "Business.h"

@implementation Business

-(void)loadImageWithHandler:(void(^)(void))completionBlock{
    
    
    completionBlock();
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    self.image = [UIImage imageNamed:@"error_image_100x100.png"];
}
@end
