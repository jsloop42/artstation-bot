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
#import "Constants.h"

NS_ASSUME_NONNULL_BEGIN

@interface FrontierService : NSObject
@property (nonatomic, readwrite) CrawlService *crawlerService;
@property (nonatomic, readwrite) BOOL isCrawlPaused;
@property (nonatomic, readwrite) BOOL isMessengerPaused;
/* Table that keeps info on the crawls that can to be scheduled */
@property (atomic, readwrite) NSMutableDictionary<NSNumber *, UserFetchState *> *fetchTable;  /* skillId, userFetchState */
/* Table that keeps the current running crawls */
@property (atomic, readwrite) NSMutableDictionary<NSNumber *, UserFetchState *> *crawlerRunTable;  /* skillId, userFetchState */
@property (atomic, readwrite) NSMutableDictionary<UserMessageKey *, UserMessageState *> *messageTable;  /* Message schedule queue (table) - skillId, user */
@property (atomic, readwrite) NSMutableDictionary<UserMessageKey *, UserMessageState *> *messengerRunTable;  /*  skillId, user */
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
