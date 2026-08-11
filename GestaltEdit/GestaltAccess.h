//
//  GestaltAccess.h
//  GestaltEdit
//
//  High-level service that acquires a read/write sandbox extension for the
//  MobileGestalt cache directory through the ContainerManager routes
//  described in the FilzaSlop / Geod-MCM / MobileHouseArrest PoCs, then
//  reads, edits, saves and backs up com.apple.MobileGestalt.plist.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GestaltRoute) {
    GestaltRouteNone = 0,
    GestaltRouteSystemGroupClass13,   // class 13 + part 3 + read/write flags
    GestaltRouteSystemGroupLegacy,    // class 13, part 0 (older OS)
    GestaltRouteGeodTraversal         // class 12 geod + part-domain traversal
};

extern NSString * const GestaltPlistFileName;

@interface GestaltAccess : NSObject

+ (instancetype)shared;

/// Returns whether this process is running on an iOS 27 build that GestaltEdit
/// currently supports (developer beta 1 through beta 4).
+ (BOOL)isRunningSupportedOS;

/// The Darwin build identifier used by the supported-OS check, such as
/// "24A5390f". An empty string means the build identifier could not be read.
+ (NSString *)currentOSBuild;

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) GestaltRoute activeRoute;
@property (nonatomic, copy, readonly) NSString *routeDescription;
@property (nonatomic, copy, readonly) NSString *cacheDirectoryPath;
@property (nonatomic, copy, readonly) NSString *plistPath;
@property (nonatomic, copy, readonly) NSString *hostBundleIdentifier;

/// Acquires a lease and activates the sandbox extension, then verifies the
/// cache directory and plist are accessible. Idempotent.
- (BOOL)connectWithError:(NSError **)error;

/// Reads and parses the live plist. Detects the on-disk format (XML/binary).
- (nullable NSDictionary *)readGestaltWithError:(NSError **)error;
/// Reads the live plist without parsing or re-serializing it.
- (nullable NSData *)readGestaltDataWithError:(NSError **)error;
/// Returns the format (NSPropertyListXMLFormat_v1_0 / NSPropertyListBinaryFormat_v1_0)
/// detected by the last successful read.
@property (nonatomic, readonly) NSPropertyListFormat lastReadFormat;

/// Rewrites the existing plist inode and preserves its ownership, flags and
/// extended attributes.
- (BOOL)saveGestalt:(NSDictionary *)plist error:(NSError **)error;

/// Reloads the system UI by restarting backboardd without a full device reboot.
- (BOOL)respringWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
