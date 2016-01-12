//
//  ApiResponse.m
//  WS
//
//  Created by yuhanle on 15/5/8.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import "ApiResponse.h"
#import "WSMacros.h"

@implementation ApiResponse
@synthesize errCode = _errCode;
@synthesize errDesc = _errDesc;
@synthesize data = _data;

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (!self) {
        self = [[ApiResponse alloc] init];
    }
    
	if([[dictionary allKeys] containsObject:@"errCode"]){
		NSString *errCode = [dictionary objectForKey:@"errCode"];
		if(errCode != (id) [NSNull null]){
			self.errCode = [errCode integerValue];
		}

        if (self.errCode == 0) {
            self.success = YES;
        }else {
            self.success = NO;
        }
	}

	if ([[dictionary allKeys] containsObject:@"errDesc"]) {
		self.errDesc = [dictionary objectForKey:@"errDesc"];
	}

	if ([[dictionary allKeys] containsObject:@"data"]) {
		self.data = [dictionary objectForKey:@"data"];
	}
    
    if ([[dictionary allKeys] containsObject:@"custDesc"]) {
        self.custDesc = [dictionary objectForKey:@"custDesc"];
    }
    
    if ([[dictionary allKeys] containsObject:@"total"]) {
        self.total = [[dictionary objectForKey:@"total"] integerValue];
    }
    
    if ([[dictionary allKeys] containsObject:@"subtotal"]) {
        self.subtotal = [[dictionary objectForKey:@"subtotal"] integerValue];
    }
    
	return self;
}

- (NSString *)errDesc {
	if(_errDesc == (id) [NSNull null]){
		return nil;
	}
    
	return _errDesc;
}

-(NSString *)custDesc {
    if(_custDesc == (id) [NSNull null]){
        return nil;
    }
    
    return _custDesc;
}

@end
