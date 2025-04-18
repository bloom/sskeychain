//
//  SSKeychainQuery.m
//  SSKeychain
//
//  Created by Caleb Davenport on 3/19/13.
//  Copyright (c) 2013-2014 Sam Soffes. All rights reserved.
//

#import "SSKeychainQuery.h"
#import "SSKeychain.h"

@implementation SSKeychainQuery

@synthesize account = _account;
@synthesize service = _service;
@synthesize label = _label;
@synthesize passwordData = _passwordData;

#if SSKEYCHAIN_ACCESSGROUP_AVAILABLE
@synthesize accessGroup = _accessGroup;
#endif

#ifdef SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE
@synthesize synchronizationMode = _synchronizationMode;
#endif

- (instancetype)init {
	self = [super init];
	if (self) {
		_useModernKeychain = YES;
	}

	return self;
}

#pragma mark - Public

- (BOOL)save:(NSError *__autoreleasing *)error {
	OSStatus status = SSKeychainErrorBadArguments;
	if (!self.service || !self.account || !self.passwordData) {
		if (error) {
			*error = [[self class] errorWithCode:status];
		}
		return NO;
	}

	[self deleteItem:nil];

	NSMutableDictionary *query = [self query];
	[query setObject:self.passwordData forKey:(__bridge id)kSecValueData];
	if (self.label) {
		[query setObject:self.label forKey:(__bridge id)kSecAttrLabel];
	}
    
    if (self.comment) {
        [query setObject:self.comment forKey:(__bridge id)kSecAttrComment];
    }
    
#ifdef SSKEYCHAIN_ACCESSIBLE_AVAILABLE
	CFTypeRef accessibilityType = self.accessibilityType ?: [SSKeychain accessibilityType];
	if (accessibilityType) {
		[query setObject:(__bridge id)accessibilityType forKey:(__bridge id)kSecAttrAccessible];
	}
#endif
	status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);

	if (status != errSecSuccess && error != NULL) {
		*error = [[self class] errorWithCode:status];
	}

	return (status == errSecSuccess);
}


- (BOOL)deleteItem:(NSError *__autoreleasing *)error {
	OSStatus status = SSKeychainErrorBadArguments;
	if (!self.service || !self.account) {
		if (error) {
			*error = [[self class] errorWithCode:status];
		}
		return NO;
	}

	NSMutableDictionary *query = [self query];
#if TARGET_OS_IPHONE
	status = SecItemDelete((__bridge CFDictionaryRef)query);
#else
	CFTypeRef result = NULL;
	[query setObject:@YES forKey:(__bridge id)kSecReturnRef];
    [query setObject:@YES forKey:(__bridge id)kSecReturnAttributes];
	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        CFDictionaryRef attributes = (CFDictionaryRef) result;

        if (CFDictionaryGetValue(attributes, kSecAttrSynchronizable) != nil) {
            status = SecItemDelete((__bridge CFDictionaryRef)query);
        }
        else {
            SecKeychainItemRef keychainItem = (SecKeychainItemRef) CFDictionaryGetValue((CFDictionaryRef) result, kSecValueRef);
            status = SecKeychainItemDelete(keychainItem);
        }
		CFRelease(result);
	}
#endif

	if (status != errSecSuccess && error != NULL) {
		*error = [[self class] errorWithCode:status];
	}

	return (status == errSecSuccess);
}


- (NSArray *)fetchAll:(NSError *__autoreleasing *)error {
	OSStatus status = SSKeychainErrorBadArguments;
	NSMutableDictionary *query = [self query];
	[query setObject:@YES forKey:(__bridge id)kSecReturnAttributes];
	[query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];

	CFTypeRef result = NULL;
	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
	if (status != errSecSuccess && error != NULL) {
		*error = [[self class] errorWithCode:status];
		return nil;
	}

	return (__bridge_transfer NSArray *)result;
}


- (BOOL)fetch:(NSError *__autoreleasing *)error {
	OSStatus status = SSKeychainErrorBadArguments;
	if (!self.service || !self.account) {
		if (error) {
			*error = [[self class] errorWithCode:status];
		}
		return NO;
	}

	CFTypeRef result = NULL;
	NSMutableDictionary *query = [self query];
	[query setObject:@YES forKey:(__bridge id)kSecReturnData];
	[query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

	if (status != errSecSuccess && error != NULL) {
		*error = [[self class] errorWithCode:status];
		return NO;
	}

	self.passwordData = (__bridge_transfer NSData *)result;
	return YES;
}


#pragma mark - Accessors

- (void)setPassword:(NSString *)password {
	self.passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
}


- (NSString *)password {
	if ([self.passwordData length]) {
		return [[NSString alloc] initWithData:self.passwordData encoding:NSUTF8StringEncoding];
	}
	return nil;
}


#pragma mark - Synchronization Status

#ifdef SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE
+ (BOOL)isSynchronizationAvailable {
#if TARGET_OS_IPHONE
	// Apple suggested way to check for 7.0 at runtime
	// https://developer.apple.com/library/ios/documentation/userexperience/conceptual/transitionguide/SupportingEarlieriOS.html
	return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1;
#else
	return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber10_8_4;
#endif
}
#endif

+ (BOOL)isLegacyModeAvailable {
#if SSKEYCHAIN_LEGACY_MODE_AVAILABLE
	if (@available(macOS 10.15, *)) {
		return YES;
	}
#endif

	return NO;
}


#pragma mark - Private

- (NSMutableDictionary *)query {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

	if (self.service) {
		[dictionary setObject:self.service forKey:(__bridge id)kSecAttrService];
	}

	if (self.account) {
		[dictionary setObject:self.account forKey:(__bridge id)kSecAttrAccount];
	}

#if SSKEYCHAIN_ACCESSGROUP_AVAILABLE
	if (self.accessGroup) {
		[dictionary setObject:self.accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
	}
#endif
	
#if SSKEYCHAIN_LEGACY_MODE_AVAILABLE
	if (self.useModernKeychain) {
		[dictionary setObject:@(YES) forKey:(__bridge id)kSecUseDataProtectionKeychain];
	}
#endif

#ifdef SSKEYCHAIN_SYNCHRONIZATION_AVAILABLE
	if ([[self class] isSynchronizationAvailable]) {
		id value;

		switch (self.synchronizationMode) {
			case SSKeychainQuerySynchronizationModeNo: {
			  value = @NO;
			  break;
			}
			case SSKeychainQuerySynchronizationModeYes: {
			  value = @YES;
			  break;
			}
			case SSKeychainQuerySynchronizationModeAny: {
			  value = (__bridge id)(kSecAttrSynchronizableAny);
			  break;
			}
		}

		[dictionary setObject:value forKey:(__bridge id)(kSecAttrSynchronizable)];
	}
#endif

	return dictionary;
}


+ (NSError *)errorWithCode:(OSStatus) code {
	NSString *message = nil;
	switch (code) {
		case errSecSuccess: return nil;
        case SSKeychainErrorBadArguments:
            message = @"Unexpected arguments to keychain function";
		default:
			message = (__bridge_transfer NSString *)SecCopyErrorMessageString(code, NULL);
	}

	NSDictionary *userInfo = nil;
	if (message) {
		userInfo = @{ NSLocalizedDescriptionKey : message };
	}
	return [NSError errorWithDomain:kSSKeychainErrorDomain code:code userInfo:userInfo];
}

@end
