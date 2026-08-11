//
//  MCMBridge.h
//  GestaltEdit
//
//  Ported from FilzaSlop (github.com/0xjohnnydev/FilzaSlop), MCMBridge.h/m.
//  Thin wrapper around the private MobileContainerManager C API
//  (libsystem_containermanager.dylib). A container "lease" holds a query,
//  copies the container object, requests its sandbox extension token and
//  activates it so normal file APIs can read/write inside the container.
//

#import <Foundation/Foundation.h>

// Based on the MobileHouseArrest / ContainerManager PoC by 0xJohnny:
// https://x.com/0xjohnny
// https://github.com/0xjohnnydev/FilzaSlop

NS_ASSUME_NONNULL_BEGIN

@interface MCMLease : NSObject
@property(nonatomic, readonly) uint64_t containerClass;
@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, copy, readonly) NSString *rootPath;
@property(nonatomic, readonly) BOOL groupIdentifier;
@property(nonatomic, readonly) BOOL tokenPresent;
@property(nonatomic, readonly) BOOL activated;

+ (nullable instancetype)leaseForClass:(uint64_t)containerClass
                             identifier:(NSString *)identifier
                                  group:(BOOL)group
                                   part:(uint64_t)part
                                  flags:(uint64_t)flags
                                  error:(NSString * _Nullable * _Nullable)error;
+ (nullable instancetype)leaseForClass:(uint64_t)containerClass
                             identifier:(NSString *)identifier
                                  group:(BOOL)group
                                   part:(uint64_t)part
                             partDomain:(nullable NSString *)partDomain
                                  flags:(uint64_t)flags
                                  error:(NSString * _Nullable * _Nullable)error;
- (BOOL)activate:(NSString * _Nullable * _Nullable)error;
- (void)invalidate;
@end

FOUNDATION_EXPORT BOOL MCMBridgeAvailable(void);
FOUNDATION_EXPORT NSArray<NSString *> *MCMEnumerateIdentifiersForClass(
    uint64_t containerClass, NSUInteger limit,
    NSString * _Nullable * _Nullable error);

NS_ASSUME_NONNULL_END
