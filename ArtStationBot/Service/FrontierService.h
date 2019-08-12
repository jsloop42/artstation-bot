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
#import "FoundationDBService.h"
#import "UserMessageState.h"
#import "SenderDetails.h"
#import "KeychainAccount.h"
#import "MessageTemplateRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FrontierService : NSObject
@property (nonatomic, readwrite) CrawlService *crawlerService;
@property (nonatomic, readwrite) BOOL isCrawlPaused;
@property (nonatomic, readwrite) BOOL isMessengerPaused;
+ (instancetype)shared;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
- (void)startCrawl;
- (void)pauseCrawl;
- (void)scheduleFetch:(NSUInteger)index;
- (void)performFetch:(NSNumber *)index;
- (void)startMessenger;
- (void)pauseMessenger;
- (void)updateSenderDetails:(SenderDetails *)sender callback:(void (^)(bool status))callback;
@end

NS_ASSUME_NONNULL_END
