//
//  SSKeychainQuery.h
//  SSKeychain
//
//  Created by Caleb Davenport on 3/19/13.
//  Copyright (c) 2013-2014 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#if __IPHONE_7_0 || __MAC_10_9
	// Keychain synchronization available at compile time
	#define SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE 1
#endif

#if TARGET_OS_OSX && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_15)
	// Legacy Keychain Mode is only available in macOS
	#define SSKEYCHAIN_LEGACY_MODE_AVAILABLE 1
#endif

#ifdef SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE
typedef NS_ENUM(NSUInteger, SSKeychainQuerySynchronizationMode) {
	SSKeychainQuerySynchronizationModeAny,
	SSKeychainQuerySynchronizationModeNo,
	SSKeychainQuerySynchronizationModeYes
};
#endif

#if __IPHONE_4_0 || __MAC_10_9
    #define SSKEYCHAIN_ACCESSIBLE_AVAILABLE 1
#endif

#if __IPHONE_3_0 || __MAC_10_9
    #define SSKEYCHAIN_ACCESSGROUP_AVAILABLE 1
#endif


/**
 Simple interface for querying or modifying keychain items.
 */
@interface SSKeychainQuery : NSObject

/** kSecAttrAccount */
@property (nonatomic, copy) NSString *account;

/** kSecAttrService */
@property (nonatomic, copy) NSString *service;

/** kSecAttrLabel */
@property (nonatomic, copy) NSString *label;

/** kSecAttrComment **/
@property (nonatomic, copy) NSString *comment;

#ifdef SSKEYCHAIN_ACCESSIBLE_AVAILABLE
/** 
 kSecAttrAccessible
 Sets the accessibility type for an individual item. If set, this overrides +[SSKeychain accessibilityType].
 */
@property (nonatomic, copy) __attribute__((NSObject)) CFTypeRef accessibilityType;
#endif

#if SSKEYCHAIN_ACCESSGROUP_AVAILABLE
/** kSecAttrAccessGroup */
@property (nonatomic, copy) NSString *accessGroup;
#endif

#ifdef SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE
/** kSecAttrSynchronizable */
@property (nonatomic) SSKeychainQuerySynchronizationMode synchronizationMode;
#endif

/** Root storage for password information */
@property (nonatomic, copy) NSData *passwordData;

/**
 Convenience accessor for setting and getting a password string. Passes through
 to `passwordData` using UTF-8 string encoding.
 */
@property (nonatomic, copy) NSString *password;

/**
 When disabled, the Legacy macOS Filesystem-based Keychain will be used.
 This is useful if you have existing data in the legacy keychain
 and need to access it on newer systems.
 */
@property (nonatomic, assign) BOOL useModernKeychain;


///------------------------
/// @name Saving & Deleting
///------------------------

/**
 Save the receiver's attributes as a keychain item. Existing items with the
 given account, service, and access group will first be deleted.

 @param error Populated should an error occur.

 @return `YES` if saving was successful, `NO` otherwise.
 */
- (BOOL)save:(NSError **)error;

/**
 Delete keychain items that match the given account, service, and access group.

 @param error Populated should an error occur.

 @return `YES` if saving was successful, `NO` otherwise.
 */
- (BOOL)deleteItem:(NSError **)error;


///---------------
/// @name Fetching
///---------------

/**
 Fetch all keychain items that match the given account, service, and access
 group. The values of `password` and `passwordData` are ignored when fetching.

 @param error Populated should an error occur.

 @return An array of dictionaries that represent all matching keychain items or
 `nil` should an error occur.
 The order of the items is not determined.
 */
- (NSArray *)fetchAll:(NSError **)error;

/**
 Fetch the keychain item that matches the given account, service, and access
 group. The `password` and `passwordData` properties will be populated unless
 an error occurs. The values of `password` and `passwordData` are ignored when
 fetching.

 @param error Populated should an error occur.

 @return `YES` if fetching was successful, `NO` otherwise.
 */
- (BOOL)fetch:(NSError **)error;


///-----------------------------
/// @name Synchronization Status
///-----------------------------

#ifdef SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE
/**
 Returns a boolean indicating if keychain synchronization is available on the device at runtime. The #define 
 SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE is only for compile time. If you are checking for the presence of synchronization,
 you should use this method.
 
 @return A value indicating if keychain synchronization is available
 */
+ (BOOL)isSynchronizationAvailable;
#endif


/**
 Indicates if the Legacy Keychain Mode is available
 */
+ (BOOL)isLegacyModeAvailable;

@end
