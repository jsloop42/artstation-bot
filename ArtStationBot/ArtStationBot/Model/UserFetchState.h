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
@property (nonatomic, readwrite) NSUInteger page;
@property (nonatomic, readwrite) NSUInteger totalCount;
@end

NS_ASSUME_NONNULL_END
