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

NS_ASSUME_NONNULL_BEGIN

@interface FoundationDBService : NSObject
+ (FoundationDBService *)shared;
@property (nonatomic, readwrite) NSString *configPath;
- (bool)initDocLayer;
- (void)getUsersWithOffset:(NSUInteger)userId limit:(NSUInteger)limit callback:(void (^) (NSArray<User *> *))callback;
- (void)getSkills:(void (^)(void))callback;
- (void)getCrawlerState:(void(^)(CrawlerState *))callback;
- (void)insertFilters:(Filters *)filters callback:(void (^)(BOOL))callback;
- (bool)upsertSkills:(NSMutableArray<Skill *> *)skills;
- (bool)upsertSoftware:(NSMutableArray<Software *> *)software;
- (bool)upsertAvailabilities:(NSMutableArray<Availability *> *)availabilities;
- (bool)upsertCountries:(NSMutableArray<Country *> *)countries;
- (void)insertUser:(User *)user;
- (void)insertUser:(User *)user callback:(void  (^ _Nullable)(bool))callback;
- (void)test;
- (bool)updateCrawlerState:(NSString *)skillName page:(NSUInteger)page totalCount:(NSUInteger)totalCount;
@end

NS_ASSUME_NONNULL_END


