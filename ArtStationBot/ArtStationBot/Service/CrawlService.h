//
//  CrawlService.h
//  ArtStationBot
//
//  Created by jsloop on 01/08/19.
//

#import <Foundation/Foundation.h>
#import "Filters.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface CrawlService : NSObject
- (void)getCSRFToken:(void (^)(NSString *))callback;
- (void)getFilterList:(void (^)(Filters *))callback;
- (void)getUsersForSkill:(NSString *)skillId page:(NSUInteger)page max:(NSUInteger)max callback:(void (^) (NSArray<User *> *))callback;
@end

NS_ASSUME_NONNULL_END
