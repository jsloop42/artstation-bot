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

NS_ASSUME_NONNULL_BEGIN

@interface FoundationDBService : NSObject
+ (FoundationDBService *)shared;
@property (nonatomic, readwrite) NSString *configPath;
- (bool)initDocLayer;
- (void)insertFilters:(Filters *)filters callback:(void (^)(BOOL))callback;
- (bool)upsertSkills:(NSMutableArray<Skill *> *)skills;
- (bool)upsertSoftware:(NSMutableArray<Software *> *)software;
- (bool)upsertAvailabilities:(NSMutableArray<Availability *> *)availabilities;
- (bool)upsertCountries:(NSMutableArray<Country *> *)countries;
- (bool)insertUser:(User *)user;
- (void)test;
- (void)getUsersWithOffset:(NSUInteger)userId limit:(NSUInteger)limit callback:(void (^) (NSArray<User *> *))callback;
@end

NS_ASSUME_NONNULL_END


