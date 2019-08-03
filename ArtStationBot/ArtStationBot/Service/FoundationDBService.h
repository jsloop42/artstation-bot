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
- (int)initDocLayer;
- (void)insertFilters:(Filters *)filters callback:(void (^)(BOOL))callback;
- (int)insertSkills:(NSMutableArray<Skill *> *)skills;
- (int)insertSoftware:(NSMutableArray<Software *> *)software;
- (int)insertAvailabilities:(NSMutableArray<Availability *> *)availabilities;
- (int)insertUser:(User *)user;
@end

NS_ASSUME_NONNULL_END


