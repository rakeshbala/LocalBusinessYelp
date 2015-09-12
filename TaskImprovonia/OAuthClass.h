//
//  OAuthClass.h
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAToken.h"


@interface OAuthClass : NSObject
@property (strong,nonatomic) NSString *consumerKey;
@property (strong,nonatomic) NSString *consumerSecret;
@property (strong,nonatomic) NSString *tokenKey;
@property (strong,nonatomic) NSString *tokenSecret;
@property (strong,nonatomic) NSString *nonce;
@property (strong,nonatomic) NSString *timeStamp;
@property (strong,nonatomic) OAToken *token;
- (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret;
- (NSMutableURLRequest *)createRequestWithParams:(NSDictionary *)params;
@end
