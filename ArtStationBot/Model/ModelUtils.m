//
//  ModelUtils.m
//  ArtStationBot
//
//  Created by jsloop on 04/08/19.
//

#import "ModelUtils.h"

static ModelUtils *_modelUtils;

@implementation ModelUtils

+ (void)initialize {
    if (self == [self class]) {
        if (!_modelUtils) _modelUtils = [ModelUtils new];
    }
}

+ (instancetype)shared {
    return _modelUtils;
}

- (Country * _Nullable)countryFromLocation:(NSString *)location {
    NSArray *locArr = [location componentsSeparatedByString:@", "];
    NSString *countryName;
    NSArray<Country *> *countryArr;
    Country *country;
    if ([locArr count] > 0) {
        countryName = (NSString *)[locArr lastObject];
        countryArr = [StateData.shared.countries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", countryName]];
        if ([countryArr count] >= 1) {
            country = [countryArr firstObject];
        }
    }
    return country;
}

- (Skill *)skillFromDictionary:(NSDictionary *)dict {
    Skill *skill = [Skill new];
    id val = [dict valueForKey:@"_id"];
    if (val && val != [NSNull null]) skill.skillId = (NSUInteger)[[(NSMutableDictionary *)val objectForKey:@"$numberLong"] integerValue];
    val = [dict valueForKey:@"name"];
    if (val && val != [NSNull null]) skill.name = (NSString *)val;
    val = [dict valueForKey:@"message"];
    if (val && val != [NSNull null]) skill.message = (NSString *)val;
    skill.originalMessage = skill.message;
    return skill;
}

- (UserFetchState *)userFetchStateFromDictionary:(NSDictionary *)dict forSkill:(Skill *)skill {
    UserFetchState *fetchState = [UserFetchState new];
    fetchState.skillId = [NSString stringWithFormat:@"%ld", skill.skillId];
    fetchState.skillName = skill.name;
    id val = [dict valueForKey:@"page"];
    if (val && val != [NSNull null]) fetchState.page = (NSUInteger)[[(NSMutableDictionary *)val objectForKey:@"$numberLong"] integerValue];
    val = [dict valueForKey:@"total_count"];
    if (val && val != [NSNull null]) fetchState.totalCount = (NSUInteger)[[(NSMutableDictionary *)val objectForKey:@"$numberLong"] integerValue];
    return fetchState;
}

- (SenderDetails *)senderDetailsFromDictionary:(NSDictionary *)dict {
    SenderDetails *sender = [SenderDetails new];
    id val = [dict valueForKey:@"_id"];
    if (val && val != [NSNull null]) sender.artStationEmail = (NSString *)val;
    val = [dict valueForKey:@"name"];
    if (val && val != [NSNull null]) sender.name = (NSString *)val;
    val = [dict valueForKey:@"contact_email"];
    if (val && val != [NSNull null]) sender.contactEmail = (NSString *)val;
    val = [dict valueForKey:@"url"];
    if (val && val != [NSNull null]) sender.url = (NSString *)val;
    return sender;
}

- (User *)userFromDictionary:(NSDictionary *)dict convertType:(enum ConvertType)convertType {
    User *user = [User new];
    id val;
    switch (convertType) {
        case ConvertTypeBSON:
            user.userId = (NSUInteger)[[(NSMutableDictionary *)[dict valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
            user.likesCount = (NSUInteger)[[(NSMutableDictionary *)[dict valueForKey:@"likes_count"] objectForKey:@"$numberLong"] integerValue];
            user.followersCount = (NSUInteger)[[(NSMutableDictionary *)[dict valueForKey:@"followers_count"] objectForKey:@"$numberLong"] integerValue];
            break;
        case ConvertTypeJSON:
            val = [dict valueForKey:@"id"];
            if (val && val != [NSNull null]) user.userId = (NSUInteger)[(NSNumber *)val integerValue];
            val = [dict valueForKey:@"likes_count"];
            if (val && val != [NSNull null]) user.likesCount = (NSUInteger)[(NSNumber *)val integerValue];
            val = [dict valueForKey:@"followers_count"];
            if (val && val != [NSNull null]) user.followersCount = (NSUInteger)[(NSNumber *)val integerValue];
            break;
    }
    val = (NSString *)[dict valueForKey:@"username"];
    if (val != [NSNull null]) user.username = val;
    val = (NSString *)[dict valueForKey:@"large_avatar_url"];
    if (val != [NSNull null]) user.largeAvatarURL = val;
    val = (NSString *)[dict valueForKey:@"small_cover_url"];
    if (val != [NSNull null]) user.smallCoverURL = val;
    val = [dict valueForKey:@"is_staff"];
    user.isStaff = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"pro_member"];
    user.isProMember = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = (NSString *)[dict valueForKey:@"artstation_profile_url"];
    if (val != [NSNull null]) user.artstationProfileURL = val;
    val = [dict valueForKey:@"available_full_time"];
    user.isAvailableFullTime = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"available_contract"];
    user.isAvailableContract = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"available_freelance"];
    user.isAvailableFreelance = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = (NSString *)[dict valueForKey:@"location"];
    if (val != [NSNull null]) user.location = val;
    val = (NSString *)[dict valueForKey:@"full_name"];
    if (val != [NSNull null]) user.fullName = val;
    val = (NSString *)[dict valueForKey:@"headline"];
    if (val != [NSNull null]) user.headline = val;
    val = [dict valueForKey:@"followed"];
    user.isFollowed = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    val = [dict valueForKey:@"following_back"];
    user.isFollowingBack = val ? (BOOL)CFBooleanGetValue((CFBooleanRef)val) : NO;
    NSMutableDictionary *hm;
    // Construct sample projects
    NSMutableArray *sampleProjects = (NSMutableArray *)[dict objectForKey:@"sample_projects"];
    if ([sampleProjects count] > 0) {
        SampleProject *proj;
        user.sampleProjects = [NSMutableArray new];
        for (hm in sampleProjects) {
            proj = [SampleProject new];
            if (convertType == ConvertTypeBSON) {
                proj.sampleProjectId = (NSUInteger)[[(NSMutableDictionary *)[hm valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
            }
            val = [hm valueForKey:@"smaller_square_cover_url"];
            if (val != [NSNull null]) proj.smallerSquareCoverURL = val;
            val = [hm valueForKey:@"url"];
            if (val != [NSNull null]) proj.url = val;
            val = [hm valueForKey:@"title"];
            if (val != [NSNull null]) proj.title = val;
            [user.sampleProjects addObject:proj];
        }
    }
    // Construct skills
    NSMutableArray *skillsArr = (NSMutableArray *)[dict objectForKey:@"skills"];
    if ([skillsArr count] > 0) {
        Skill *skill;
        user.skills = [NSMutableArray new];
        for (hm in skillsArr) {
            skill = [Skill new];
//            if (convertType == ConvertTypeBSON) {
//                skill.skillId = (NSUInteger)[[(NSMutableDictionary *)[hm valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
//            }
            val = [hm valueForKey:@"skill_name"];
            if (val != [NSNull null]) skill.name = val;
            [user.skills addObject:skill];
        }
    }
    // Construct software
    NSMutableArray *software = (NSMutableArray *)[dict objectForKey: convertType == ConvertTypeJSON ? @"softwares" : @"software"];
    if ([software count] > 0) {
        user.software = [NSMutableArray new];
        Software *sw;
        for (hm in software) {
            sw = [Software new];
//            if (convertType == ConvertTypeBSON) {
//                sw.softwareId = (NSUInteger)[[(NSMutableDictionary *)[hm valueForKey:@"_id"] objectForKey:@"$numberLong"] integerValue];
//            }
            val = [hm valueForKey:@"software_name"];
            if (val != [NSNull null]) sw.name = val;
            [user.software addObject:sw];
        }
    }
    return user;
}

@end
