//
//  BadQueryLeaseHelper.h
//  Island
//
//  Thin wrapper around BadQueryLease with an explicit NS_SWIFT_NAME so Swift
//  call sites do not depend on the Objective-C importer's automatic method
//  name transformation.
//

#import <Foundation/Foundation.h>
#import "BadQueryBridge.h"

NS_ASSUME_NONNULL_BEGIN

@interface BadQueryLeaseHelper : NSObject

+ (nullable BadQueryLease *)acquireLeaseForPath:(NSString *)path
                                    errorMessage:(NSString * _Nullable * _Nullable)errorMessage
    NS_SWIFT_NAME(acquireLease(path:errorMessage:));

@end

NS_ASSUME_NONNULL_END
