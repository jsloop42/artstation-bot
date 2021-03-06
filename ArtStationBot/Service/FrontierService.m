//
//  FrontierService.m
//  ArtStationBot
//
//  Created by jsloop on 05/08/19.
//

#import "FrontierService.h"
#import "Constants.h"
#import "ArtStationBot-Swift.h"

static FrontierService *_frontierService;

@interface FrontierService () <WebKitControllerDelegate>
@end

@interface FrontierService ()

@property (nonatomic, readwrite) dispatch_queue_t dispatchQueue;
@property (nonatomic, readwrite) FoundationDBService *fdbService;

/* Crawler */
@property (atomic, readwrite) GKARC4RandomSource *crawlerARC4RandomSource;
@property (atomic, readwrite) GKGaussianDistribution *crawlerGaussianDistribution;
@property (atomic, readwrite) NSUInteger crawlerTotalDelay;
@property (nonatomic, readwrite) NSMutableArray *crawlerMeanList;  /* [[mean, standard deviation], ..] in seconds */
@property (nonatomic, readwrite) NSUInteger crawlerBatchCount;  /* Used to choose different delay for each batch run */

/* Messenger */
/* Send message proccessing queue, but the message is not yet run. The message state has been picked from the messageTable, but not yet ready for sending
   (waiting for the WebKit window to load), after which it will be added to the message run table */
@property (atomic, readwrite) NSMutableArray<UserMessageState *> *messageStartQueue;
@property (atomic, readwrite) GKARC4RandomSource *messengerARC4RandomSource;
@property (atomic, readwrite) GKGaussianDistribution *messengerGaussianDistribution;
@property (atomic, readwrite) NSUInteger messengerTotalDelay;
@property (nonatomic, readwrite) NSMutableArray *messengerMeanList;  /* [[mean, standard deviation], ..] in seconds */
@property (nonatomic, readwrite) NSUInteger messengerBatchCount;

@end

@implementation FrontierService

+ (instancetype)shared {
    if (!_frontierService) {
        _frontierService = [FrontierService new];
        [_frontierService bootstrap];
    }
    return _frontierService;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)bootstrap {
    self.crawlerService = [CrawlService new];
    self.fdbService = FoundationDBService.shared;

    /* crawler */
    self.fetchTable = [NSMutableDictionary new];
    self.crawlerRunTable = [NSMutableDictionary new];
    self.crawlerARC4RandomSource = [GKARC4RandomSource new];
    [self.crawlerARC4RandomSource dropValuesWithCount:764];
    self.crawlerMeanList = [NSMutableArray new];
    //[self.crawlerMeanList addObject:@[@(10), @(1)]];
    [self.crawlerMeanList addObject:@[@(30), @(10)]];
    [self.crawlerMeanList addObject:@[@(40), @(10)]];
    NSMutableArray *carr = self.crawlerMeanList[0];
    self.crawlerGaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.crawlerARC4RandomSource mean:[(NSNumber *)carr[0] intValue]
                                                                                  deviation:[(NSNumber *)carr[1] intValue]];
    /* messenger */
    self.messageTable = [NSMutableDictionary new];
    self.messengerRunTable = [NSMutableDictionary new];
    self.messageStartQueue = [NSMutableArray new];
    self.messengerARC4RandomSource = [GKARC4RandomSource new];
    [self.messengerARC4RandomSource dropValuesWithCount:764];
    self.messengerMeanList = [NSMutableArray new];
    //[self.messengerMeanList addObject:@[@(5), @(1)]];
    [self.messengerMeanList addObject:@[@(25), @(15)]];
    [self.messengerMeanList addObject:@[@(35), @(15)]];
    NSMutableArray *marr = self.messengerMeanList[0];
    self.messengerGaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.messengerARC4RandomSource mean:[(NSNumber *)marr[0] intValue]
                                                                                    deviation:[(NSNumber *)marr[1] intValue]];
    self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.crawlerTotalDelay = 0;
    self.crawlerBatchCount = 1;
    self.isCrawlPaused = YES;
    self.isMessengerPaused = YES;

    [self initEvents];
}

- (void)initEvents {

}

/** Get random number for crawler with normal distribution characteristics that has a standard deviation from the set mean. */
- (NSInteger)crawlerRandom {
    return self.crawlerGaussianDistribution.nextInt;
}

- (NSInteger)messengerRandom {
    return self.messengerGaussianDistribution.nextInt;
}

#pragma mark Crawler

/**
 Basic algorithm for crawling
 1. Get the list of skills from filters list.
 2. For each skill, get the crawler state `fetchState`.
 3. If state exists, use the page from the state else set page to 1.
 4. Add the fetchState to a queue `fetchList`.
 5. Construct a set of time interval starting from now + a skew with a certain deviation.
 6. For each element in the queue, execute getUsersForSkill to fetch the users' list.
 */
- (void)startCrawl {
    self.isCrawlPaused = NO;
    [self.crawlerService getFilterList:^(Filters * _Nonnull filters) {
        [self.fdbService insertFilters:filters callback:^(bool status) {
            [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.settingsTableViewShouldReload object:self]];
            [self.fdbService getCrawlerState:^(CrawlerState * _Nonnull state) {
                self.crawlerService.crawlerState = state;
                [self crawlNextBatch:filters.skills];
            }];
        }];
    }];
}

- (void)checkSkills:(void (^)(BOOL))callback {
    NSMutableArray<Skill *> *skills = StateData.shared.skills;
    NSUInteger len = skills.count;
    BOOL __block status = YES;
    if (len == 0) {
        [self.fdbService getSkills:^{
            if (StateData.shared.skills.count == 0) {
                error(@"Skills collection is empty. Please crawl to fetch the skills list.");
                status = NO;
            }
            callback(status);
        }];
    } else {
        callback(status);
    }
}

/** Pause scroll for the next batch. */
- (void)pauseCrawl {
    self.isCrawlPaused = YES;
}

- (void)crawlNextBatch:(NSMutableArray<Skill *> *)skills {
    Skill *skill;
    NSUInteger page = 1;
    NSUInteger skillId;
    UserFetchState *fetchState;
    for (skill in skills) {
        skillId = skill.skillId;
        page = 1;
        fetchState = [self.crawlerService.crawlerState.fetchState objectForKey:@(skillId)];
        if (!fetchState) {
            fetchState = [UserFetchState new];
        } else {
            page = fetchState.page + 1;
        }
        if (fetchState.page <= ceil(fetchState.totalCount / [Const maxUserLimit] * 1.0)) {
            fetchState.page = page;
            fetchState.skillId = [NSString stringWithFormat:@"%ld", skillId];
            fetchState.skillName = skill.name;
            fetchState.scheduledTime = [NSDate dateWithTimeInterval:self.crawlerTotalDelay + 60 sinceDate:[NSDate new]];  // initial data
            [self.fetchTable setObject:fetchState forKey:@(skillId)];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scheduleFetch:skillId];
            });
        }
    }
    [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.dashboardTableViewShouldReload object:self]];
}

/** Schedules a fetch with a delay with the past scheduled delays taken in account. The overlap of two fetches is minimal. */
- (void)scheduleFetch:(NSUInteger)index {
    NSUInteger rand = [self crawlerRandom];
    self.crawlerTotalDelay += rand;
    UserFetchState *fetchState = [self.fetchTable objectForKey:@(index)];
    fetchState.scheduledTime = [NSDate dateWithTimeInterval:self.crawlerTotalDelay sinceDate:[NSDate new]];
    [self.fetchTable setObject:fetchState forKey:@(index)];
    [self performSelector:@selector(performFetch:) withObject:@(index) afterDelay:self.crawlerTotalDelay];
}

/** Performs crawl with the state taken from fetch table corresponding to the given skill id as index. */
- (void)performFetch:(NSNumber *)index {
    UserFetchState *fetchState = [self.fetchTable objectForKey:index];
    if (fetchState) {
        [self.crawlerService getUsersForSkill:fetchState.skillId page:fetchState.page max:[Const maxUserLimit] callback:^(UserSearchResponse * _Nonnull resp) {
            [self.fdbService updateCrawlerState:fetchState.skillName page:resp.page totalCount:resp.totalCount callback:^(bool status) {
                if (status) {
                    User *user;
                    for (user in resp.usersList) {
                        [self.fdbService insertUser:user callback:^(bool status) {
                            [self.crawlerRunTable removeObjectForKey:index];
                            [NSNotificationCenter.defaultCenter
                             postNotification:[NSNotification notificationWithName:ASNotification.dashboardTableViewShouldReload object:self]];
                        }];
                    }
                }
            }];
        }];
        [self.crawlerRunTable setObject:fetchState forKey:index];  /* add the state to run table */
        [self.fetchTable removeObjectForKey:index];  /* clear the state from fetch table */
        [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.dashboardTableViewShouldReload object:self]];
    }
    /* Queue the next batch */
    if ([self.fetchTable count] == 0 && !self.isCrawlPaused) {
        ++self.crawlerBatchCount;
        NSArray *meanArr = (self.crawlerBatchCount % 2 == 0) ? self.crawlerMeanList[1] : self.crawlerMeanList[0];
        int mean = [(NSNumber *)meanArr[0] intValue];
        int deviation = [(NSNumber *)meanArr[1] intValue];
        self.crawlerGaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.crawlerARC4RandomSource mean:mean deviation:deviation];
        [self crawlNextBatch:StateData.shared.skills];
    } else if (self.fetchTable.count == 0 && self.crawlerRunTable.count == 0 && self.isCrawlPaused) {
        [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.crawlerDidPause object:self]];
    }
}

#pragma mark Messenger

- (void)startMessenger {
    self.isMessengerPaused = NO;
    if (!StateData.shared.skills || StateData.shared.skills.count == 0) {
        [self checkSkills:^(BOOL status) {
            if (status) [self sendMessage];
        }];
    } else {
        [self sendMessage];
    }
}

/*
 1. For each skill, get list of users who had not been messaged, and get the message for the skill
 2. For each user in the list, schedule sending message
 */
- (void)sendMessage {
    Skill *skill;
    for (skill in StateData.shared.skills) {
        [self.fdbService getUsersForSkill:skill.name limit:[Const maxUserLimit] isMessaged:NO callback:^(NSArray<User *> * _Nonnull users) {
            User *user = nil;
            UserMessageState *state = nil;
            UserMessageKey *key = nil;
            NSUInteger count = 0;
            for (user in users) {
                if (count <= 2) {
                    state = [UserMessageState new];
                    state.skill = skill;
                    state.user = user;
                    state.scheduledTime = [NSDate dateWithTimeInterval:self.messengerTotalDelay + 60 sinceDate:[NSDate new]];  // initial data
                    key = [UserMessageKey new];
                    key.skillId = @(skill.skillId);
                    key.userId = @(user.userId);
                    [self.messageTable setObject:state forKey:key];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self scheduleMessaging:key];
                    });
                }
                count++;
            }
        }];
    }
}

- (void)scheduleMessaging:(UserMessageKey *)key {
    NSUInteger rand = [self messengerRandom];
    self.messengerTotalDelay += rand;
    UserMessageState *state = [self.messageTable objectForKey:key];
    state.scheduledTime = [NSDate dateWithTimeInterval:self.messengerTotalDelay sinceDate:[NSDate new]];
    [self.messageTable setObject:state forKey:key];
    [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.dashboardTableViewShouldReload object:self]];
    [self performSelector:@selector(performMessaging:) withObject:key afterDelay:self.messengerTotalDelay];
}

- (void)performMessaging:(UserMessageKey *)key {
    UserMessageState *state = [self.messageTable objectForKey:key];
    if (state) {
        /* Interpolate message template */
        MessageTemplateField *field = [MessageTemplateField new];
        field.usernameOfUser = state.user.username;
        field.fullNameOfUser = state.user.fullName;
        field.profileURLOfUser = state.user.artstationProfileURL;
        field.skillName = state.skill.name;
        field.nameOfSender = StateData.shared.senderDetails.name;
        field.urlOfSender = StateData.shared.senderDetails.url;
        field.emailOfSender = StateData.shared.senderDetails.contactEmail;
        MessageTemplateRenderer *renderer = [MessageTemplateRenderer new];
        [renderer setTemplateValue:field];
        state.skill.interpolatedMessage = [renderer renderTemplate:state.skill.message];

        WebKitWindowController *wkwc = [UI createWebKitWindow];
        [wkwc setShouldCascadeWindows:YES];
        state.webKitWC = wkwc;
        [self.messageStartQueue addObject:state];
        wkwc.delegate = self;
        [wkwc.vc setCredentials:StateData.shared.senderDetails.artStationEmail password:StateData.shared.senderDetails.password];
        [wkwc.vc setShouldSignIn:YES];
        wkwc.vc.seedURL = state.user.artstationProfileURL;
        [wkwc show];
    }
}

- (void)queueNextMessengerBatch {
    /* Queue the next batch */
    if ([self.messengerRunTable count] == 0 && !self.isMessengerPaused) {
        ++self.messengerBatchCount;
        NSArray *meanArr = (self.messengerBatchCount % 2 == 0) ? self.messengerMeanList[1] : self.messengerMeanList[0];
        int mean = [(NSNumber *)meanArr[0] intValue];
        int deviation = [(NSNumber *)meanArr[1] intValue];
        self.messengerGaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.messengerARC4RandomSource mean:mean deviation:deviation];
        [self sendMessage];
    } else if ([self.messengerRunTable count] == 0 && self.isMessengerPaused) {
        [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.messengerDidPause object:self]];
    }
}

- (void)pauseMessenger {
    self.isMessengerPaused = YES;
}

- (void)updateSenderDetails:(SenderDetails *)sender callback:(void (^)(bool status))callback {
    BOOL ret = NO;
    /* Save credentials to macOS keychain */
    ret = [Utils setAccountToKeychainWithName:sender.artStationEmail password:sender.password];
    if (!ret) {
        callback(ret);
        return;
    }
    /* Update sender details in the DB */
    [self.fdbService upsertSender:sender callback:^(bool status) {
        callback(status);
    }];
}

- (void)webKitWindowDidLoad {
    while (self.messageStartQueue.count != 0) {
        UserMessageState *state = [self.messageStartQueue firstObject];
        [self.messageStartQueue removeObjectAtIndex:0];
        WebKitWindowController *wkwc = (WebKitWindowController *)state.webKitWC;
        UserMessageKey *key = [UserMessageKey new];
        key.userId = @(state.user.userId);
        key.skillId = @(state.skill.skillId);
        [wkwc.vc sendMessage:key state:state callback:^(BOOL status) {
            [wkwc close];
            if (status) {
                [self.fdbService updateMessageState:state.skill forUser:state.user.userId isMessaged:YES callback:^(bool status) {}];
            }
            [self.messengerRunTable removeObjectForKey:key];
            [self queueNextMessengerBatch];
            [NSNotificationCenter.defaultCenter
             postNotification:[NSNotification notificationWithName:ASNotification.dashboardTableViewShouldReload object:self]];
        }];
        [self.messengerRunTable setObject:state forKey:key];
        [self.messageTable removeObjectForKey:key];
        [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:ASNotification.dashboardTableViewShouldReload object:self]];
    }
}

@end
