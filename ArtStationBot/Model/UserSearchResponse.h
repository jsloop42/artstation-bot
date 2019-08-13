//
//  UserSearchResponse.h
//  ArtStationBot
//
//  Created by jsloop on 04/08/19.
//

#import <Foundation/Foundation.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserSearchResponse : NSObject
@property (nonatomic, readwrite) NSUInteger totalCount;
@property (nonatomic, readwrite) NSMutableArray<User *> *usersList;
@property (nonatomic, readwrite) NSUInteger page;
@property (nonatomic, readwrite) NSString *skillId;
@property (nonatomic, readwrite) BOOL status;
@end

NS_ASSUME_NONNULL_END
