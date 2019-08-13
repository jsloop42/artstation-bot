//
//  KeychainAccount.h
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeychainAccount : NSObject
@property (nonatomic, readwrite) NSString *serviceName;
@property (nonatomic, readwrite) NSString *accountName;
@property (nonatomic, readwrite) NSString *password;
@end

NS_ASSUME_NONNULL_END
