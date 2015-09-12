//
//  OAuthClass.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "OAuthClass.h"
#include "crypto.h"
#import "OARequestParameter.h"
#import "NSMutableURLRequest+Parameters.h"

static NSString * const kAPIHost = @"api.yelp.com";
static NSString * const kBusinessPath      = @"/v2/business/";
static NSString * const kSearchPath        = @"/v2/search";

@implementation OAuthClass


-(NSMutableURLRequest *)createRequestWithParams:(NSDictionary *)params{
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init] ;
    NSURL *url = [self URLWithHost:kAPIHost path:kSearchPath queryParameters:params];
    [urlRequest setURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    NSString *baseString = [self signatureBaseString:urlRequest];
    NSString *secret = [NSString stringWithFormat:@"%@&%@",
                        [self.consumerSecret encodedURLParameterString],
                        self.token.secret ? [self.token.secret encodedURLParameterString]:@""];
    NSString *signature = [self signClearText:baseString withSecret:secret];
    
    // set OAuth headers
    NSMutableArray *chunks = [[NSMutableArray alloc] init];
    [chunks addObject:[NSString stringWithFormat:@"realm=\"%@\"", @""]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_consumer_key=\"%@\"",
                       [self.consumerKey encodedURLParameterString]]];
    NSDictionary *tokenParameters = [self.token parameters];
    for (NSString *k in tokenParameters) {
        [chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"",
                           k, [[tokenParameters objectForKey:k] encodedURLParameterString]]];
    }
    [chunks addObject:[NSString stringWithFormat:@"oauth_signature_method=\"%@\"",
                       [@"HMAC-SHA1" encodedURLParameterString]]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_signature=\"%@\"",
                       [signature encodedURLParameterString]]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_timestamp=\"%@\"", self.timeStamp]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_nonce=\"%@\"", self.nonce]];
    [chunks	addObject:@"oauth_version=\"1.0\""];
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth %@",
                             [chunks componentsJoinedByString:@", "]];
    [urlRequest setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
    return urlRequest;
}

- (NSURL *)URLWithHost:(NSString *)host path:(NSString *)path queryParameters:(NSDictionary *)queryParameters {
    NSMutableArray *queryParts = [[NSMutableArray alloc] init];
    for (NSString *key in [queryParameters allKeys]) {
        NSString *queryPart = [NSString stringWithFormat:@"%@=%@", key, queryParameters[key]];
        [queryParts addObject:queryPart];
    }
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"http";
    components.host = host;
    components.path = path;
    components.query = [queryParts componentsJoinedByString:@"&"];
    return [components URL];
}

- (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret {
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
    hmac_sha1((unsigned char *)[clearTextData bytes], [clearTextData length], (unsigned char *)[secretData bytes], [secretData length], result);
    
    //Base64 Encoding
    char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeData(result, 20, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
    
    NSString *base64EncodedResult = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    return base64EncodedResult;
}




- (NSString *)signatureBaseString:(NSMutableURLRequest *)request {
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSDictionary *tokenParameters = [self.token parameters];
    // 6 being the number of OAuth params in the Signature Base String
    NSArray *parameters = [request parameters];
    NSMutableArray *parameterPairs = [[NSMutableArray alloc] initWithCapacity:(5 + [parameters count] + [tokenParameters count])];
    
    OARequestParameter *parameter;
    parameter = [[OARequestParameter alloc] initWithName:@"oauth_consumer_key" value:self.consumerKey];
    
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    parameter = [[OARequestParameter alloc] initWithName:@"oauth_signature_method" value:@"HMAC-SHA1"];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    parameter = [[OARequestParameter alloc] initWithName:@"oauth_timestamp" value:self.timeStamp];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    parameter = [[OARequestParameter alloc] initWithName:@"oauth_nonce" value:self.nonce];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    parameter = [[OARequestParameter alloc] initWithName:@"oauth_version" value:@"1.0"] ;
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
    
    for(NSString *k in tokenParameters) {
        [parameterPairs addObject:[[OARequestParameter requestParameter:k value:[tokenParameters objectForKey:k]] URLEncodedNameValuePair]];
    }
    
    if (![[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
        for (OARequestParameter *param in parameters) {
            [parameterPairs addObject:[param URLEncodedNameValuePair]];
        }
    }
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    //	NSLog(@"Normalized: %@", normalizedRequestParameters);
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    return [NSString stringWithFormat:@"%@&%@&%@",
            [request HTTPMethod],
            [[[request URL] URLStringWithoutQuery] encodedURLParameterString],
            [normalizedRequestParameters encodedURLString]];
}


- (NSString *)generateNonce {
    NSString *nonce = @"";
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    
    nonce = (NSString *)CFBridgingRelease(string);
    return nonce;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.consumerKey = @"smhmWLy4TyUDBO95eQVwdw";
        self.consumerSecret = @"uopG7MF_ExGMGfHKj3dYC4cMPm0";
        self.tokenKey = @"PV1ARBgfOLyZNOXLvzzUfn-ODMqYJsvQ";
        self.tokenSecret = @"LGzfmxn3Btiep_f7W6Mz99BgyI8";
        self.token = [[OAToken alloc]initWithKey:self.tokenKey secret:self.tokenSecret];
        self.timeStamp = [[NSString alloc]initWithFormat:@"%ld", time(NULL)];
        self.nonce = [self generateNonce];
    }
    return self;
}
@end


