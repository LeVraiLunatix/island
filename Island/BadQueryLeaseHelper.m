//
//  BadQueryLeaseHelper.m
//  Island
//

#import "BadQueryLeaseHelper.h"

@implementation BadQueryLeaseHelper

+ (nullable BadQueryLease *)acquireLeaseForPath:(NSString *)path
                                    errorMessage:(NSString * _Nullable * _Nullable)errorMessage
{
    return [BadQueryLease leaseForPath:path error:errorMessage];
}

@end
