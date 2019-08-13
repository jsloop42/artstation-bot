//
//  UserFetchState.h
//  ArtStationBot
//
//  Created by jsloop on 05/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserFetchState : NSObject
@property (nonatomic, readwrite) NSString *skillId;
@property (nonatomic, readwrite) NSString *skillName;
@property (nonatomic, readwrite) NSUInteger page;
@property (nonatomic, readwrite) NSUInteger totalCount;
@property (nonatomic, readwrite) NSDate *scheduledTime;
@end

NS_ASSUME_NONNULL_END
