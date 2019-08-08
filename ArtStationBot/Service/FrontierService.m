//
//  FrontierService.m
//  ArtStationBot
//
//  Created by jsloop on 05/08/19.
//

#import "FrontierService.h"
#import "Constants.h"

static FrontierService *_frontierService;

@interface FrontierService ()
/* Table that keeps info on the crawls that can to be scheduled */
@property (atomic, readwrite) NSMutableDictionary<NSNumber *, UserFetchState *> *fetchTable;  // skillId, userFetchState
/* Table that keeps the current running crawls */
@property (atomic, readwrite) NSMutableDictionary<NSNumber *, UserFetchState *> *runTable;  // skillId, userFetchState
@property (atomic, readwrite) GKARC4RandomSource *arc4RandomSource;
@property (atomic, readwrite) GKGaussianDistribution *gaussianDistribution;
@property (nonatomic, readwrite) dispatch_queue_t dispatchQueue;
@property (atomic, readwrite) NSUInteger totalDelay;
@property (nonatomic, readwrite) FoundationDBService *fdbService;
@property (nonatomic, readwrite) NSMutableArray *meanList;  // [[mean, standard deviation], ..] in seconds
@property (nonatomic, readwrite) NSUInteger batchCount;
@end

@implementation FrontierService

+ (instancetype)shared {
    if (!_frontierService) {
        _frontierService = [FrontierService new];
        [_frontierService bootstrap];
    }
    return _frontierService;
}

- (void)bootstrap {
    self.crawlerService = [CrawlService new];
    self.fdbService = FoundationDBService.shared;
    self.fetchTable = [NSMutableDictionary new];
    self.arc4RandomSource = [GKARC4RandomSource new];
    [self.arc4RandomSource dropValuesWithCount:764];
    //[self.meanList addObject:@[@(10), @(1)]];
    self.meanList = [NSMutableArray new];
    [self.meanList addObject:@[@(30), @(10)]];
    [self.meanList addObject:@[@(40), @(10)]];
    NSMutableArray *arr = self.meanList[0];
    self.gaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.arc4RandomSource mean:[(NSNumber *)arr[0] intValue]
                                                                           deviation:[(NSNumber *)arr[1] intValue]];
    self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.totalDelay = 0;
    self.batchCount = 1;
    self.isCrawlPaused = NO;
    self.isMessengerPaused = NO;
}

/** Get random number with normal distribution characteristics that has a standard deviation from the set mean. */
- (NSInteger)random {
    return self.gaussianDistribution.nextInt;
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
        debug(@"Filters list fetched");
        [self.fdbService insertFilters:filters callback:^(bool status) {
            debug(@"Filters list updated");
            debug(@"Skills state updated with count: %ld", StateData.shared.skills.count);
            [self.fdbService getCrawlerState:^(CrawlerState * _Nonnull state) {
                debug(@"Crawler state obtained with fetch user count: %ld", state.fetchState.count);
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
    NSUInteger count = 0;  // TODO: test remove later
    NSUInteger page = 1;
    NSUInteger skillId;
    UserFetchState *fetchState;
    for (skill in skills) {
        //if (count < 2) {  // TODO: remove this
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
                [self.fetchTable setObject:fetchState forKey:@(skillId)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self scheduleFetch:skillId];
                });
            } else {
                debug(@"All users fetched for skill: %@", skill.name);
            }
        //}
        count++;
    }
}

/** Schedules a fetch with a delay with the past scheduled delays taken in account. The overlap of two fetches is minimal. */
- (void)scheduleFetch:(NSUInteger)index {
    NSUInteger rand = [self random];
    debug(@"rand: %ld", rand);
    self.totalDelay += rand;
    debug(@"total delay: %ld", self.totalDelay);
    [self performSelector:@selector(performFetch:) withObject:@(index) afterDelay:self.totalDelay];
}

/** Performs crawl with the state taken from fetch table corresponding to the given skill id as index. */
- (void)performFetch:(NSNumber *)index {
    debug(@"perform fetch %@", index);
    UserFetchState *fetchState = [self.fetchTable objectForKey:index];
    if (fetchState) {
        [self.crawlerService getUsersForSkill:fetchState.skillId page:fetchState.page max:[Const maxUserLimit] callback:^(UserSearchResponse * _Nonnull resp) {
            [self.fdbService updateCrawlerState:fetchState.skillName page:resp.page totalCount:resp.totalCount callback:^(bool status) {
                if (status) {
                    User *user;
                    for (user in resp.usersList) {
                        [self.fdbService insertUser:user callback:^(bool status) {
                            debug(@"insert status for %lu: %d", (unsigned long)user.userId, status);
                        }];
                    }
                }
            }];
        }];
        [self.runTable setObject:fetchState forKey:index];  // clear the state from fetch table
        [self.fetchTable removeObjectForKey:index];  // add the state to run table
    }
    debug(@"fetch table count: %ld", [self.fetchTable count]);
    /* Queue the next batch */
    if ([self.fetchTable count] == 0 && !self.isCrawlPaused) {
        ++self.batchCount;
        NSArray *meanArr = (self.batchCount % 2 == 0) ? self.meanList[1] : self.meanList[0];
        int mean = [(NSNumber *)meanArr[0] intValue];
        int deviation = [(NSNumber *)meanArr[1] intValue];
        self.gaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.arc4RandomSource mean:mean deviation:deviation];
        debug(@"Queueing the next batch: %ld", self.batchCount);
        [self crawlNextBatch:StateData.shared.skills];
    }
}

#pragma mark Messenger

- (void)startMessenger {
    self.isMessengerPaused = NO;
    if (!StateData.shared.skills || StateData.shared.skills.count == 0) {
        [self checkSkills:^(BOOL status) {
            //[self updateMessageForSkill:StateData.shared.skills.firstObject message:@"Message to 2D Animation user"];
            if (status) [self sendMessage]; // TODO:
        }];
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
            debug(@"Get users for skill callback %ld", users.count);
            // TODO: schedule sending message
        }];
    }
}

- (void)pauseMessenger {
    self.isMessengerPaused = YES;
}

- (void)updateMessageForSkill:(Skill *)skill message:(NSString *)message {
    [self.fdbService updateMessage:message forSkill:skill callback:^(bool status) {
        debug(@"Message update status for skill %@: %d", skill.name, status);
    }];
}


@end
