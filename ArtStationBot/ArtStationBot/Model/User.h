//
//  User.h
//  ArtStationBot
//
//  Created by jsloop on 30/07/19.
//

#import <Foundation/Foundation.h>
#import "SampleProject.h"
#import "Skill.h"
#import "Software.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject
@property (nonatomic, readwrite) NSUInteger userId;
@property (nonatomic, readwrite) NSString *username;
@property (nonatomic, readwrite) NSString *largeAvatarURL;
@property (nonatomic, readwrite) NSString *smallCoverURL;
@property (nonatomic, readwrite) bool isStaff;
@property (nonatomic, readwrite) bool isProMember;
@property (nonatomic, readwrite) NSString *artstationProfileURL;
@property (nonatomic, readwrite) NSUInteger likesCount;
@property (nonatomic, readwrite) NSUInteger followersCount;
@property (nonatomic, readwrite) bool isAvailableFullTime;
@property (nonatomic, readwrite) bool isAvailableContract;
@property (nonatomic, readwrite) bool isAvailableFreelance;
@property (nonatomic, readwrite) NSString *location;
@property (nonatomic, readwrite) NSString *fullName;
@property (nonatomic, readwrite) NSString *headline;
@property (nonatomic, readwrite) bool isFollowed;
@property (nonatomic, readwrite) bool isFollowingBack;
@property (nonatomic, readwrite) NSMutableArray<SampleProject *> *sampleProjects;
@property (nonatomic, readwrite) NSMutableArray<Skill *> *skills;
@property (nonatomic, readwrite) NSMutableArray<Software *> *software;
@end

NS_ASSUME_NONNULL_END
