//
//  SenderDetails.h
//  ArtStationBot
//
//  Created by jsloop on 11/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SenderDetails : NSObject
@property (nonatomic, readwrite) NSString *artStationEmail;
@property (nonatomic, readwrite) NSString *password;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *contactEmail;
@property (nonatomic, readwrite) NSString *url;
@end

NS_ASSUME_NONNULL_END
