//
//  ModelUtils.h
//  ArtStationBot
//
//  Created by jsloop on 04/08/19.
//

#import <Foundation/Foundation.h>
#import "Country.h"
#import "SampleProject.h"
#import "Skill.h"
#import "Software.h"
#import "User.h"
#import "StateData.h"
#import "SenderDetails.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ConvertType) {
    ConvertTypeBSON,
    ConvertTypeJSON
};

@interface ModelUtils : NSObject
+ (instancetype)shared;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
- (Country * _Nullable)countryFromLocation:(NSString *)location;
- (Skill *)skillFromDictionary:(NSDictionary *)dict;
- (UserFetchState *)userFetchStateFromDictionary:(NSDictionary *)dict forSkill:(Skill *)skill;
- (SenderDetails *)senderDetailsFromDictionary:(NSDictionary *)dict;
- (User *)userFromDictionary:(NSDictionary *)dict convertType:(enum ConvertType)convertType;
@end

NS_ASSUME_NONNULL_END
