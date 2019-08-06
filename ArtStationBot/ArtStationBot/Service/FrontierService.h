//
//  FrontierService.h
//  ArtStationBot
//
//  Created by jsloop on 05/08/19.
//

#import <Foundation/Foundation.h>
#import <GameplayKit/GameplayKit.h>
#import "CrawlerState.h"
#import "CrawlService.h"
#import "Constants.h"
#import "FoundationDBService.h"

NS_ASSUME_NONNULL_BEGIN

@interface FrontierService : NSObject
@property (nonatomic, readwrite) CrawlService *crawlerService;
+ (instancetype)shared;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
- (void)startCrawl;
- (void)pauseCrawl;
- (void)scheduleFetch:(NSUInteger)index;
- (void)performFetch:(NSNumber *)index;
@end

NS_ASSUME_NONNULL_END
