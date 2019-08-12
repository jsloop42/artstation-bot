//
//  FoundationDBService.h
//  ArtStationBot
//
//  Created by jsloop on 23/07/19.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "Filters.h"
#import "User.h"
#import "StateData.h"
#import "ModelUtils.h"
#import "UserFetchState.h"
#import "CrawlerState.h"
#import "SenderDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface FoundationDBService : NSObject
+ (FoundationDBService *)shared;
@property (nonatomic, readwrite) NSString *configPath;
- (bool)initDocLayer;
- (void)getUsersWithOffset:(NSUInteger)userId limit:(NSUInteger)limit callback:(void (^) (NSArray<User *> *users))callback;
- (void)getUsersForSkill:(NSString *)skillName limit:(NSUInteger)limit isMessaged:(BOOL)isMessaged callback:(void (^) (NSArray<User *> *users))callback;
- (void)getSkills:(void (^)(void))callback;
- (void)getCrawlerState:(void(^)(CrawlerState *state))callback;
- (void)getSenderDetails:(void(^)(NSMutableArray<SenderDetails *> *senders))callback;
- (void)insertFilters:(Filters *)filters callback:(void (^)(bool status))callback;
- (bool)upsertSkills:(NSMutableArray<Skill *> *)skills;
- (bool)upsertSoftware:(NSMutableArray<Software *> *)software;
- (bool)upsertAvailabilities:(NSMutableArray<Availability *> *)availabilities;
- (bool)upsertCountries:(NSMutableArray<Country *> *)countries;
- (void)upsertSender:(SenderDetails *)sender callback:(void (^)(bool status))callback;
- (void)insertUser:(User *)user;
- (void)insertUser:(User *)user callback:(void  (^ _Nullable)(bool status))callback;
- (void)test;
- (void)updateCrawlerState:(NSString *)skillName page:(NSUInteger)page totalCount:(NSUInteger)totalCount callback:(void (^)(bool status))callback;
- (void)updateMessage:(NSString *)message forSkill:(Skill *)skill callback:(void (^)(bool status))callback;
- (void)updateMessageState:(Skill *)skill forUser:(NSUInteger)userId isMessaged:(BOOL)isMessaged callback:(void (^)(bool status))callback;
@end

NS_ASSUME_NONNULL_END
