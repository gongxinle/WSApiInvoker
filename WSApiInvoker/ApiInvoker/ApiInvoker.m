//
//  WS
//
//  Created by yuhanle on 15/5/8.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//


#import "ApiInvoker.h"
#import "JSONKit.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#import "WSMacros.h"

#define API_BASE_URL(url) ([NSURL URLWithString:url])


@interface ApiInvoker () <AFWSApiInvokerDelegate>
@property (nonatomic, strong) AFWSApiInvoker *apiInvoker;
@property (nonatomic, strong) AFWSApiInvoker *apiHttpsInvoker;
@end

@implementation ApiInvoker {

}

@synthesize apiBaseUrl = _apiBaseUrl;
@synthesize apiHttpsBaseUrl = _apiHttpsBaseUrl;
@synthesize timeoutInSeconds = _timeoutInSeconds;

- (id)init {
    self = [super init];
    if (self) {
        self.timeoutInSeconds = 30;
    }

    return self;
}

- (void)postApi:(NSString *)api andRequest:(ApiRequest *)apiRequest callback:(API_CALLBACK)callback {
	[self requestApi:api withMethod:@"POST" andRequest:apiRequest callback:callback];
}
- (void)requestApi:(NSString *)api withMethod:(NSString *)httpMethod andRequest:(ApiRequest *)apiRequest callback:(API_CALLBACK)callback {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	//通过encodeApiRequest_iOS6: 得到请求的请求体 （参数排序、拼接成请求字符串）
    NSString *body = ([self encodeApiRequest_iOS6:apiRequest]);
    NSString *completeApiUrl = nil;
	//判断是get还是post请求 拼接成完整的请求url
    if ([self isGet:httpMethod] || [self isDelete:httpMethod]) {
        //get 和 delete方法的body放在queryString
        completeApiUrl = [NSString stringWithFormat:@"%@?%@", api, body];
    } else {
        completeApiUrl = api;
    }
    
    NSURL *url = [NSURL URLWithString:completeApiUrl relativeToURL:API_BASE_URL(apiRequest.isHttps ? self.apiHttpsBaseUrl : self.apiBaseUrl)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    //设置超时时间:10秒
    [request setTimeoutInterval:self.timeoutInSeconds];

	//设置请求方式为传递的请求参数的方
    [request setHTTPMethod:httpMethod];
    NSDictionary * params = [self encodeJSONApiRequest_iOS6:apiRequest];
    if ([self isPost:httpMethod] || [self isPut:httpMethod]) {
        [request setValue:@"application/json" forHTTPHeaderField:@"content-type"]; //请求头
        [request setHTTPBody:[params JSONData]];
    }
    
    if (apiRequest.isHttps) {
        [self.apiHttpsInvoker request:request apiRequest:apiRequest callback:callback];
    }else {
        [self.apiInvoker request:request apiRequest:apiRequest callback:callback];
    }
    NSLog(@"OK, request %@ data is %@", request, params);
}
-(NSDictionary *)encodeJSONApiRequest_iOS6:(ApiRequest *)request {
    @autoreleasepool {
        NSMutableDictionary * JSONBody = [[NSMutableDictionary alloc]init];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:request.bizDataDict];
        NSString *token = @"你的token";
        if (NOT_NULL(token) && request.hasToken)
        {
            [dict setObject:token forKey:@"token"];
        }
        
        NSArray *keys = [dict allKeys];
        
        NSComparator comparator =  ^(id obj1, id obj2){
            NSString *key1 = obj1;
            NSString *key2 = obj2;
            return [key1 compare:key2];
        };
        NSArray *sortedKeys = [keys sortedArrayUsingComparator:comparator];
        
        for (NSString * key in sortedKeys) {
            NSString *value = [dict objectForKey:key];
            [JSONBody setValue:value forKey:key];
        }
        
        return JSONBody.copy;
    }
}
- (NSString *)encodeApiRequest_iOS6:(ApiRequest *)request {
	@autoreleasepool {
		//在这个方法内对参数进行排列 然后按顺序拼接成请求的URL
		//ENT CS 参数算法
		NSMutableArray *namedValuePair = [[NSMutableArray alloc] init];

		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:request.bizDataDict];
		NSString *token = @"你的token";
		if (NOT_NULL(token) && request.hasToken)
		{
			[dict setObject:token forKey:@"token"];
		}
		NSArray *keys = [dict allKeys];

		NSComparator comparator =  ^(id obj1, id obj2){
			NSString *key1 = obj1;
			NSString *key2 = obj2;
			return [key1 compare:key2];
		};
		NSArray *sortedKeys = [keys sortedArrayUsingComparator:comparator];
		
		NSMutableArray *values = [[NSMutableArray alloc] init];
		for(NSString *key in sortedKeys){
			NSString *value = [dict objectForKey:key];
			[values addObject:value];
			[namedValuePair addObject:[NSString stringWithFormat:@"%@=%@",key,value]];
		}
        
		NSString *returnString = [namedValuePair componentsJoinedByString:@"&"];
		return returnString;
	}
}
- (NSString *)md5:(NSString *) input
{
	const char *cStr = [input UTF8String];
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call

	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", digest[i]];

	return  output;
}
//统一处理错误
- (void)handleError:(NSInteger)statusCode response:(ApiResponse *)apiResponse {
    
}

-(void)handleError:(NSInteger)statusCode apiRequest:(ApiRequest *)apiRequest response:(ApiResponse *)apiResponse {
    
}

- (BOOL)isGet:(NSString *)httpMethod {
    return [[httpMethod lowercaseString] isEqualToString:@"get"];
}

- (BOOL)isPut:(NSString *)httpMethod {
    return [[httpMethod lowercaseString] isEqualToString:@"put"];
}

- (BOOL)isDelete:(NSString *)httpMethod {
    return [[httpMethod lowercaseString] isEqualToString:@"delete"];
}

- (BOOL)isPost:(NSString *)httpMethod {
    return [[httpMethod lowercaseString] isEqualToString:@"post"];
}

- (void)setApiBaseUrl:(NSString *)apiBaseUrl {
	_apiBaseUrl = apiBaseUrl;
	self.apiInvoker = [AFWSApiInvoker apiInvokerWithBaseUrl:self.apiBaseUrl];
	self.apiInvoker.delegate = self;
}

- (void)setApiHttpsBaseUrl:(NSString *)apiHttpsBaseUrl {
    _apiHttpsBaseUrl = apiHttpsBaseUrl;
    self.apiHttpsInvoker = [AFWSApiInvoker apiHttpsInvokerWithBaseUrl:self.apiHttpsBaseUrl];
    self.apiHttpsInvoker.delegate = self;
}

-(void)addRequest:(ApiRequest *)apiRequest {
    [self.apiInvoker addRequest:apiRequest];
}

-(void)removeAllRequest {
    [self.apiInvoker removeAllRequest];
}

-(void)removeRequest:(ApiRequest *)apiRequest {
    [self.apiInvoker removeRequest:apiRequest normal:NO];
}

-(void)cancellAllRequest {
    [self.apiInvoker cancellAllRequest];
}

-(void)cancellAllRequestExcept:(ApiRequest *)apiRequest {
    [self.apiInvoker cancellAllRequestExcept:apiRequest];
}

-(void)reRequest:(ApiRequest *)apiRequest {
#warning 添加你的请求信息...
    NSString * token = @"your token";
    if (NOT_NULL(token)) {
        if (apiRequest.hasToken) {
            self.token = token;
            NSMutableDictionary * dataDict = apiRequest.bizDataDict.mutableCopy;
            [dataDict setObject:self.token forKey:@"token"];
            apiRequest.bizDataDict = dataDict.copy;
        }
        
        [self postApi:apiRequest.api andRequest:apiRequest callback:apiRequest.callback];
    }else {
        [self removeRequest:apiRequest];
    }
}

-(void)reRequestAllRequest {
    NSMutableArray * apiRequestArray = [self.apiInvoker apiRequestArray];
    for (NSInteger i = 0; i < [apiRequestArray count]; i++) {
        ApiRequest * apiRequest = [apiRequestArray objectAtIndex:i];
        if ([apiRequest.api isEqualToString:@"app/xxx"]
            || [apiRequest.api isEqualToString:@"app/xxx"]
            || apiRequest.api == nil) {
            // 验证token的接口不用重新请求
            NSLog(@"重复请求无效api...");
            [self removeRequest:apiRequest];
        }else {
            [self reRequest:apiRequest];
        }
    }
}

@end