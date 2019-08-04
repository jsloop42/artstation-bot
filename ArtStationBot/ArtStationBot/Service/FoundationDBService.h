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

NS_ASSUME_NONNULL_BEGIN

@interface FoundationDBService : NSObject
+ (FoundationDBService *)shared;
@property (nonatomic, readwrite) NSString *configPath;
- (bool)initDocLayer;
- (void)insertFilters:(Filters *)filters callback:(void (^)(BOOL))callback;
- (bool)insertSkills:(NSMutableArray<Skill *> *)skills;
- (bool)insertSoftware:(NSMutableArray<Software *> *)software;
- (bool)insertAvailabilities:(NSMutableArray<Availability *> *)availabilities;
- (bool)insertUser:(User *)user;
@end

NS_ASSUME_NONNULL_END


