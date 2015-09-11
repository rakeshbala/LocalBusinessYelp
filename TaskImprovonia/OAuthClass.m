//
//  OAuthClass.m
//  TaskImprovonia
//
//  Created by Rakesh Balasubramanian on 9/11/15.
//  Copyright © 2015 Rakesh Balasubramanian. All rights reserved.
//

#import "OAuthClass.h"
#include "hmac.h"
#include "Base64Transcoder.h"
#import "OARequestParameter.h"
#import "NSMutableURLRequest+Parameters.h"

static NSString * const kAPIHost = @"api.yelp.com";
static NSString * const kBusinessPath      = @"/v2/business/";
static NSString * const kSearchPath        = @"/v2/search";

@implementation OAuthClass


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


-(NSMutableURLRequest *)createRequest{
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init] ;
    NSDictionary *params = @{
                             @"location": @"San Francisco, CA",
                             @"limit": @20
                             };
    NSURL *url = [self URLWithHost:kAPIHost path:kSearchPath queryParameters:params];

    [urlRequest setURL:url];
    [urlRequest setHTTPMethod:@"GET"];
   // [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
   // [urlRequest setValue:@"utf-8" forHTTPHeaderField:@"charset"];

    NSString *baseString = [self signatureBaseString:urlRequest];
//    baseString = [baseString stringByReplacingOccurrencesOfString:@"&" withString:@"\\u0026"];
    NSLog(@"Sent base string : %@",baseString);
    NSString *signature = [self signClearText:baseString
                                      withSecret:[NSString stringWithFormat:@"%@&%@",
                                                  [self.consumerSecret encodedURLParameterString],
                                                  self.token.secret ? [self.token.secret encodedURLParameterString] : @""]];
    
    // set OAuth headers
    NSMutableArray *chunks = [[NSMutableArray alloc] init];
    [chunks addObject:[NSString stringWithFormat:@"realm=\"%@\"", @""]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_consumer_key=\"%@\"", [self.consumerKey encodedURLParameterString]]];
    
    NSDictionary *tokenParameters = [self.token parameters];
    for (NSString *k in tokenParameters) {
        [chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", k, [[tokenParameters objectForKey:k] encodedURLParameterString]]];
    }
    
    [chunks addObject:[NSString stringWithFormat:@"oauth_signature_method=\"%@\"", [@"HMAC-SHA1" encodedURLParameterString]]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_signature=\"%@\"", [signature encodedURLParameterString]]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_timestamp=\"%@\"", self.timeStamp]];
    [chunks addObject:[NSString stringWithFormat:@"oauth_nonce=\"%@\"", self.nonce]];
    [chunks	addObject:@"oauth_version=\"1.0\""];
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth %@", [chunks componentsJoinedByString:@", "]];
    
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

@end




#include "Base64Transcoder.h"


const u_int8_t kBase64EncodeTable[64] = {
    /*  0 */ 'A',	/*  1 */ 'B',	/*  2 */ 'C',	/*  3 */ 'D',
    /*  4 */ 'E',	/*  5 */ 'F',	/*  6 */ 'G',	/*  7 */ 'H',
    /*  8 */ 'I',	/*  9 */ 'J',	/* 10 */ 'K',	/* 11 */ 'L',
    /* 12 */ 'M',	/* 13 */ 'N',	/* 14 */ 'O',	/* 15 */ 'P',
    /* 16 */ 'Q',	/* 17 */ 'R',	/* 18 */ 'S',	/* 19 */ 'T',
    /* 20 */ 'U',	/* 21 */ 'V',	/* 22 */ 'W',	/* 23 */ 'X',
    /* 24 */ 'Y',	/* 25 */ 'Z',	/* 26 */ 'a',	/* 27 */ 'b',
    /* 28 */ 'c',	/* 29 */ 'd',	/* 30 */ 'e',	/* 31 */ 'f',
    /* 32 */ 'g',	/* 33 */ 'h',	/* 34 */ 'i',	/* 35 */ 'j',
    /* 36 */ 'k',	/* 37 */ 'l',	/* 38 */ 'm',	/* 39 */ 'n',
    /* 40 */ 'o',	/* 41 */ 'p',	/* 42 */ 'q',	/* 43 */ 'r',
    /* 44 */ 's',	/* 45 */ 't',	/* 46 */ 'u',	/* 47 */ 'v',
    /* 48 */ 'w',	/* 49 */ 'x',	/* 50 */ 'y',	/* 51 */ 'z',
    /* 52 */ '0',	/* 53 */ '1',	/* 54 */ '2',	/* 55 */ '3',
    /* 56 */ '4',	/* 57 */ '5',	/* 58 */ '6',	/* 59 */ '7',
    /* 60 */ '8',	/* 61 */ '9',	/* 62 */ '+',	/* 63 */ '/'
};

/*
 -1 = Base64 end of data marker.
 -2 = White space (tabs, cr, lf, space)
 -3 = Noise (all non whitespace, non-base64 characters)
 -4 = Dangerous noise
 -5 = Illegal noise (null byte)
 */

const int8_t kBase64DecodeTable[128] = {
    /* 0x00 */ -5, 	/* 0x01 */ -3, 	/* 0x02 */ -3, 	/* 0x03 */ -3,
    /* 0x04 */ -3, 	/* 0x05 */ -3, 	/* 0x06 */ -3, 	/* 0x07 */ -3,
    /* 0x08 */ -3, 	/* 0x09 */ -2, 	/* 0x0a */ -2, 	/* 0x0b */ -2,
    /* 0x0c */ -2, 	/* 0x0d */ -2, 	/* 0x0e */ -3, 	/* 0x0f */ -3,
    /* 0x10 */ -3, 	/* 0x11 */ -3, 	/* 0x12 */ -3, 	/* 0x13 */ -3,
    /* 0x14 */ -3, 	/* 0x15 */ -3, 	/* 0x16 */ -3, 	/* 0x17 */ -3,
    /* 0x18 */ -3, 	/* 0x19 */ -3, 	/* 0x1a */ -3, 	/* 0x1b */ -3,
    /* 0x1c */ -3, 	/* 0x1d */ -3, 	/* 0x1e */ -3, 	/* 0x1f */ -3,
    /* ' ' */ -2,	/* '!' */ -3,	/* '"' */ -3,	/* '#' */ -3,
    /* '$' */ -3,	/* '%' */ -3,	/* '&' */ -3,	/* ''' */ -3,
    /* '(' */ -3,	/* ')' */ -3,	/* '*' */ -3,	/* '+' */ 62,
    /* ',' */ -3,	/* '-' */ -3,	/* '.' */ -3,	/* '/' */ 63,
    /* '0' */ 52,	/* '1' */ 53,	/* '2' */ 54,	/* '3' */ 55,
    /* '4' */ 56,	/* '5' */ 57,	/* '6' */ 58,	/* '7' */ 59,
    /* '8' */ 60,	/* '9' */ 61,	/* ':' */ -3,	/* ';' */ -3,
    /* '<' */ -3,	/* '=' */ -1,	/* '>' */ -3,	/* '?' */ -3,
    /* '@' */ -3,	/* 'A' */ 0,	/* 'B' */  1,	/* 'C' */  2,
    /* 'D' */  3,	/* 'E' */  4,	/* 'F' */  5,	/* 'G' */  6,
    /* 'H' */  7,	/* 'I' */  8,	/* 'J' */  9,	/* 'K' */ 10,
    /* 'L' */ 11,	/* 'M' */ 12,	/* 'N' */ 13,	/* 'O' */ 14,
    /* 'P' */ 15,	/* 'Q' */ 16,	/* 'R' */ 17,	/* 'S' */ 18,
    /* 'T' */ 19,	/* 'U' */ 20,	/* 'V' */ 21,	/* 'W' */ 22,
    /* 'X' */ 23,	/* 'Y' */ 24,	/* 'Z' */ 25,	/* '[' */ -3,
    /* '\' */ -3,	/* ']' */ -3,	/* '^' */ -3,	/* '_' */ -3,
    /* '`' */ -3,	/* 'a' */ 26,	/* 'b' */ 27,	/* 'c' */ 28,
    /* 'd' */ 29,	/* 'e' */ 30,	/* 'f' */ 31,	/* 'g' */ 32,
    /* 'h' */ 33,	/* 'i' */ 34,	/* 'j' */ 35,	/* 'k' */ 36,
    /* 'l' */ 37,	/* 'm' */ 38,	/* 'n' */ 39,	/* 'o' */ 40,
    /* 'p' */ 41,	/* 'q' */ 42,	/* 'r' */ 43,	/* 's' */ 44,
    /* 't' */ 45,	/* 'u' */ 46,	/* 'v' */ 47,	/* 'w' */ 48,
    /* 'x' */ 49,	/* 'y' */ 50,	/* 'z' */ 51,	/* '{' */ -3,
    /* '|' */ -3,	/* '}' */ -3,	/* '~' */ -3,	/* 0x7f */ -3
};

const u_int8_t kBits_00000011 = 0x03;
const u_int8_t kBits_00001111 = 0x0F;
const u_int8_t kBits_00110000 = 0x30;
const u_int8_t kBits_00111100 = 0x3C;
const u_int8_t kBits_00111111 = 0x3F;
const u_int8_t kBits_11000000 = 0xC0;
const u_int8_t kBits_11110000 = 0xF0;
const u_int8_t kBits_11111100 = 0xFC;

size_t EstimateBas64EncodedDataSize(size_t inDataSize)
{
    size_t theEncodedDataSize = (int)ceil(inDataSize / 3.0) * 4;
    theEncodedDataSize = theEncodedDataSize / 72 * 74 + theEncodedDataSize % 72;
    return(theEncodedDataSize);
}

size_t EstimateBas64DecodedDataSize(size_t inDataSize)
{
    size_t theDecodedDataSize = (int)ceil(inDataSize / 4.0) * 3;
    //theDecodedDataSize = theDecodedDataSize / 72 * 74 + theDecodedDataSize % 72;
    return(theDecodedDataSize);
}

bool Base64EncodeData(const void *inInputData, size_t inInputDataSize, char *outOutputData, size_t *ioOutputDataSize)
{
    size_t theEncodedDataSize = EstimateBas64EncodedDataSize(inInputDataSize);
    if (*ioOutputDataSize < theEncodedDataSize)
        return(false);
    *ioOutputDataSize = theEncodedDataSize;
    const u_int8_t *theInPtr = (const u_int8_t *)inInputData;
    u_int32_t theInIndex = 0, theOutIndex = 0;
    for (; theInIndex < (inInputDataSize / 3) * 3; theInIndex += 3)
    {
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex] & kBits_11111100) >> 2];
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex] & kBits_00000011) << 4 | (theInPtr[theInIndex + 1] & kBits_11110000) >> 4];
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex + 1] & kBits_00001111) << 2 | (theInPtr[theInIndex + 2] & kBits_11000000) >> 6];
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex + 2] & kBits_00111111) >> 0];
        if (theOutIndex % 74 == 72)
        {
            outOutputData[theOutIndex++] = '\r';
            outOutputData[theOutIndex++] = '\n';
        }
    }
    const size_t theRemainingBytes = inInputDataSize - theInIndex;
    if (theRemainingBytes == 1)
    {
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex] & kBits_11111100) >> 2];
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex] & kBits_00000011) << 4 | (0 & kBits_11110000) >> 4];
        outOutputData[theOutIndex++] = '=';
        outOutputData[theOutIndex++] = '=';
        if (theOutIndex % 74 == 72)
        {
            outOutputData[theOutIndex++] = '\r';
            outOutputData[theOutIndex++] = '\n';
        }
    }
    else if (theRemainingBytes == 2)
    {
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex] & kBits_11111100) >> 2];
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex] & kBits_00000011) << 4 | (theInPtr[theInIndex + 1] & kBits_11110000) >> 4];
        outOutputData[theOutIndex++] = kBase64EncodeTable[(theInPtr[theInIndex + 1] & kBits_00001111) << 2 | (0 & kBits_11000000) >> 6];
        outOutputData[theOutIndex++] = '=';
        if (theOutIndex % 74 == 72)
        {
            outOutputData[theOutIndex++] = '\r';
            outOutputData[theOutIndex++] = '\n';
        }
    }
    return(true);
}

bool Base64DecodeData(const void *inInputData, size_t inInputDataSize, void *ioOutputData, size_t *ioOutputDataSize)
{
    memset(ioOutputData, '.', *ioOutputDataSize);
    
    size_t theDecodedDataSize = EstimateBas64DecodedDataSize(inInputDataSize);
    if (*ioOutputDataSize < theDecodedDataSize)
        return(false);
    *ioOutputDataSize = 0;
    const u_int8_t *theInPtr = (const u_int8_t *)inInputData;
    u_int8_t *theOutPtr = (u_int8_t *)ioOutputData;
    size_t theInIndex = 0, theOutIndex = 0;
    u_int8_t theOutputOctet = 0;
    size_t theSequence = 0;
    for (; theInIndex < inInputDataSize; )
    {
        int8_t theSextet = 0;
        
        int8_t theCurrentInputOctet = theInPtr[theInIndex];
        theSextet = kBase64DecodeTable[theCurrentInputOctet];
        if (theSextet == -1)
            break;
        while (theSextet == -2)
        {
            theCurrentInputOctet = theInPtr[++theInIndex];
            theSextet = kBase64DecodeTable[theCurrentInputOctet];
        }
        while (theSextet == -3)
        {
            theCurrentInputOctet = theInPtr[++theInIndex];
            theSextet = kBase64DecodeTable[theCurrentInputOctet];
        }
        if (theSequence == 0)
        {
            theOutputOctet = (theSextet >= 0 ? theSextet : 0) << 2 & kBits_11111100;
        }
        else if (theSequence == 1)
        {
            theOutputOctet |= (theSextet >- 0 ? theSextet : 0) >> 4 & kBits_00000011;
            theOutPtr[theOutIndex++] = theOutputOctet;
        }
        else if (theSequence == 2)
        {
            theOutputOctet = (theSextet >= 0 ? theSextet : 0) << 4 & kBits_11110000;
        }
        else if (theSequence == 3)
        {
            theOutputOctet |= (theSextet >= 0 ? theSextet : 0) >> 2 & kBits_00001111;
            theOutPtr[theOutIndex++] = theOutputOctet;
        }
        else if (theSequence == 4)
        {
            theOutputOctet = (theSextet >= 0 ? theSextet : 0) << 6 & kBits_11000000;
        }
        else if (theSequence == 5)
        {
            theOutputOctet |= (theSextet >= 0 ? theSextet : 0) >> 0 & kBits_00111111;
            theOutPtr[theOutIndex++] = theOutputOctet;
        }
        theSequence = (theSequence + 1) % 6;
        if (theSequence != 2 && theSequence != 4)
            theInIndex++;
    }
    *ioOutputDataSize = theOutIndex;
    return(true);
}


typedef struct {
    u_int32_t state[5];
    u_int32_t count[2];
    u_int8_t buffer[64];
} SHA1_CTX;

extern void SHA1Init(SHA1_CTX* context);
extern void SHA1Update(SHA1_CTX* context, u_int8_t* data, u_int32_t len);
extern void SHA1Final(u_int8_t digest[20], SHA1_CTX* context);

void hmac_sha1(const u_int8_t *inText, size_t inTextLength, u_int8_t* inKey, size_t inKeyLength, u_int8_t *outDigest)
{
#define B 64
#define L 20
    
    SHA1_CTX theSHA1Context;
    u_int8_t k_ipad[B + 1]; /* inner padding - key XORd with ipad */
    u_int8_t k_opad[B + 1]; /* outer padding - key XORd with opad */
    
    /* if key is longer than 64 bytes reset it to key=SHA1 (key) */
    if (inKeyLength > B)
    {
        SHA1Init(&theSHA1Context);
        SHA1Update(&theSHA1Context, inKey, (u_int32_t)inKeyLength);
        SHA1Final(inKey, &theSHA1Context);
        inKeyLength = L;
    }
    
    /* start out by storing key in pads */
    memset(k_ipad, 0, sizeof k_ipad);
    memset(k_opad, 0, sizeof k_opad);
    memcpy(k_ipad, inKey, inKeyLength);
    memcpy(k_opad, inKey, inKeyLength);
    
    /* XOR key with ipad and opad values */
    int i;
    for (i = 0; i < B; i++)
    {
        k_ipad[i] ^= 0x36;
        k_opad[i] ^= 0x5c;
    }
    
    /*
     * perform inner SHA1
     */
    SHA1Init(&theSHA1Context);                 /* init context for 1st pass */
    SHA1Update(&theSHA1Context, k_ipad, B);     /* start with inner pad */
    SHA1Update(&theSHA1Context, (u_int8_t *)inText, (u_int32_t)inTextLength); /* then text of datagram */
    SHA1Final((u_int8_t *)outDigest, &theSHA1Context);                /* finish up 1st pass */
    
    /*
     * perform outer SHA1
     */
    SHA1Init(&theSHA1Context);                   /* init context for 2nd
                                                  * pass */
    SHA1Update(&theSHA1Context, k_opad, B);     /* start with outer pad */
    SHA1Update(&theSHA1Context, (u_int8_t *)outDigest, L);     /* then results of 1st
                                                                * hash */
    SHA1Final((u_int8_t *)outDigest, &theSHA1Context);          /* finish up 2nd pass */
    
}


/*
 SHA-1 in C
 By Steve Reid <steve@edmweb.com>
 100% Public Domain
 
 Test Vectors (from FIPS PUB 180-1)
 "abc"
 A9993E36 4706816A BA3E2571 7850C26C 9CD0D89D
 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
 84983E44 1C3BD26E BAAE4AA1 F95129E5 E54670F1
 A million repetitions of "a"
 34AA973C D4C4DAA4 F61EEB2B DBAD2731 6534016F
 */


/* #define SHA1HANDSOFF * Copies data before messing with it. */

void SHA1Transform(u_int32_t state[5], u_int8_t buffer[64]);

#define rol(value, bits) (((value) << (bits)) | ((value) >> (32 - (bits))))

/* blk0() and blk() perform the initial expand. */
/* I got the idea of expanding during the round function from SSLeay */
#ifdef LITTLE_ENDIAN
#define blk0(i) (block->l[i] = (rol(block->l[i],24)&0xFF00FF00) \
|(rol(block->l[i],8)&0x00FF00FF))
#else
#define blk0(i) block->l[i]
#endif
#define blk(i) (block->l[i&15] = rol(block->l[(i+13)&15]^block->l[(i+8)&15] \
^block->l[(i+2)&15]^block->l[i&15],1))

/* (R0+R1), R2, R3, R4 are the different operations used in SHA1 */
#define R0(v,w,x,y,z,i) z+=((w&(x^y))^y)+blk0(i)+0x5A827999+rol(v,5);w=rol(w,30);
#define R1(v,w,x,y,z,i) z+=((w&(x^y))^y)+blk(i)+0x5A827999+rol(v,5);w=rol(w,30);
#define R2(v,w,x,y,z,i) z+=(w^x^y)+blk(i)+0x6ED9EBA1+rol(v,5);w=rol(w,30);
#define R3(v,w,x,y,z,i) z+=(((w|x)&y)|(w&x))+blk(i)+0x8F1BBCDC+rol(v,5);w=rol(w,30);
#define R4(v,w,x,y,z,i) z+=(w^x^y)+blk(i)+0xCA62C1D6+rol(v,5);w=rol(w,30);


/* Hash a single 512-bit block. This is the core of the algorithm. */

void SHA1Transform(u_int32_t state[5], u_int8_t buffer[64])
{
    u_int32_t a, b, c, d, e;
    typedef union {
        u_int8_t c[64];
        u_int32_t l[16];
    } CHAR64LONG16;
    CHAR64LONG16* block;
#ifdef SHA1HANDSOFF
    static u_int8_t workspace[64];
    block = (CHAR64LONG16*)workspace;
    memcpy(block, buffer, 64);
#else
    block = (CHAR64LONG16*)buffer;
#endif
    /* Copy context->state[] to working vars */
    a = state[0];
    b = state[1];
    c = state[2];
    d = state[3];
    e = state[4];
    /* 4 rounds of 20 operations each. Loop unrolled. */
    R0(a,b,c,d,e, 0); R0(e,a,b,c,d, 1); R0(d,e,a,b,c, 2); R0(c,d,e,a,b, 3);
    R0(b,c,d,e,a, 4); R0(a,b,c,d,e, 5); R0(e,a,b,c,d, 6); R0(d,e,a,b,c, 7);
    R0(c,d,e,a,b, 8); R0(b,c,d,e,a, 9); R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
    R0(d,e,a,b,c,12); R0(c,d,e,a,b,13); R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
    R1(e,a,b,c,d,16); R1(d,e,a,b,c,17); R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
    R2(a,b,c,d,e,20); R2(e,a,b,c,d,21); R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
    R2(b,c,d,e,a,24); R2(a,b,c,d,e,25); R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
    R2(c,d,e,a,b,28); R2(b,c,d,e,a,29); R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
    R2(d,e,a,b,c,32); R2(c,d,e,a,b,33); R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
    R2(e,a,b,c,d,36); R2(d,e,a,b,c,37); R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
    R3(a,b,c,d,e,40); R3(e,a,b,c,d,41); R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
    R3(b,c,d,e,a,44); R3(a,b,c,d,e,45); R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
    R3(c,d,e,a,b,48); R3(b,c,d,e,a,49); R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
    R3(d,e,a,b,c,52); R3(c,d,e,a,b,53); R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
    R3(e,a,b,c,d,56); R3(d,e,a,b,c,57); R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
    R4(a,b,c,d,e,60); R4(e,a,b,c,d,61); R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
    R4(b,c,d,e,a,64); R4(a,b,c,d,e,65); R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
    R4(c,d,e,a,b,68); R4(b,c,d,e,a,69); R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
    R4(d,e,a,b,c,72); R4(c,d,e,a,b,73); R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
    R4(e,a,b,c,d,76); R4(d,e,a,b,c,77); R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);
    /* Add the working vars back into context.state[] */
    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    /* Wipe variables */
    a = b = c = d = e = 0;
}


/* SHA1Init - Initialize new context */

void SHA1Init(SHA1_CTX* context)
{
    /* SHA1 initialization constants */
    context->state[0] = 0x67452301;
    context->state[1] = 0xEFCDAB89;
    context->state[2] = 0x98BADCFE;
    context->state[3] = 0x10325476;
    context->state[4] = 0xC3D2E1F0;
    context->count[0] = context->count[1] = 0;
}


/* Run your data through this. */

void SHA1Update(SHA1_CTX* context, u_int8_t* data, unsigned int len)
{
    unsigned int i, j;
    
    j = (context->count[0] >> 3) & 63;
    if ((context->count[0] += len << 3) < (len << 3)) context->count[1]++;
    context->count[1] += (len >> 29);
    if ((j + len) > 63) {
        memcpy(&context->buffer[j], data, (i = 64-j));
        SHA1Transform(context->state, context->buffer);
        for ( ; i + 63 < len; i += 64) {
            SHA1Transform(context->state, &data[i]);
        }
        j = 0;
    }
    else i = 0;
    memcpy(&context->buffer[j], &data[i], len - i);
}


/* Add padding and return the message digest. */

void SHA1Final(u_int8_t digest[20], SHA1_CTX* context)
{
    u_int32_t i, j;
    u_int8_t finalcount[8];
    
    for (i = 0; i < 8; i++) {
        finalcount[i] = (u_int8_t)((context->count[(i >= 4 ? 0 : 1)]
                                    >> ((3-(i & 3)) * 8) ) & 255);  /* Endian independent */
    }
    SHA1Update(context, (u_int8_t *)"\200", 1);
    while ((context->count[0] & 504) != 448) {
        SHA1Update(context, (u_int8_t *)"\0", 1);
    }
    SHA1Update(context, finalcount, 8);  /* Should cause a SHA1Transform() */
    for (i = 0; i < 20; i++) {
        digest[i] = (u_int8_t)
        ((context->state[i>>2] >> ((3-(i & 3)) * 8) ) & 255);
    }
    /* Wipe variables */
    i = j = 0;
    memset(context->buffer, 0, 64);
    memset(context->state, 0, 20);
    memset(context->count, 0, 8);
    memset(&finalcount, 0, 8);
#ifdef SHA1HANDSOFF  /* make SHA1Transform overwrite it's own static vars */
    SHA1Transform(context->state, context->buffer);
#endif
}


