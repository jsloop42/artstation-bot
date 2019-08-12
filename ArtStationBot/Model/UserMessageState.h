//
//  UserMessageState.h
//  ArtStationBot
//
//  Created by jsloop on 10/08/19.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "User.h"
#import "Skill.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserMessageKey : NSObject<NSCopying>
@property (nonatomic, readwrite) NSNumber *skillId;
@property (nonatomic, readwrite) NSNumber *userId;
@end

@interface UserMessageState : NSObject
@property (nonatomic, readwrite) User *user;
@property (nonatomic, readwrite) Skill *skill;
@property (nonatomic, readwrite) BOOL isMessaged;
@property (nonatomic, readwrite) NSDate *messagedAt;
@property (nonatomic, readwrite) NSWindowController *webKitWC;
@end

NS_ASSUME_NONNULL_END
