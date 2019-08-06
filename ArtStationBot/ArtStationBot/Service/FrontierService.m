//
//  FrontierService.m
//  ArtStationBot
//
//  Created by jsloop on 05/08/19.
//

#import "FrontierService.h"

#define GD_MEAN 10  // TODO: update this interval
#define GD_SD 1
static FrontierService *_frontierService;

@interface FrontierService ()
/* Table that keeps info on the crawls that can to be scheduled */
@property (atomic, readwrite, retain) NSMutableDictionary<NSNumber *, UserFetchState *> *fetchTable;  // skillId, userFetchState
/* Table that keeps the current running crawls */
@property (atomic, readwrite) NSMutableDictionary<NSNumber *, UserFetchState *> *runTable;  // skillId, userFetchState
@property (atomic, readwrite) GKARC4RandomSource *arc4RandomSource;
@property (atomic, readwrite) GKGaussianDistribution *gaussianDistribution;
@property (nonatomic, readwrite) dispatch_queue_t dispatchQueue;
@property (atomic, readwrite) NSUInteger totalDelay;
@property (nonatomic, readwrite) FoundationDBService *fdbService;
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
    self.gaussianDistribution = [[GKGaussianDistribution alloc] initWithRandomSource:self.arc4RandomSource mean:GD_MEAN deviation:GD_SD];
    self.dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.totalDelay = 0;
}

/**
 1. Get the list of skills from filters list.
 2. For each skill, get the crawler state `fetchState`.
 3. If state exists, use the page from the state else set page to 1.
 4. Add the fetchState to a queue `fetchList`.
 5. Construct a set of time interval with a certain deviation starting from now + a skew.
 6. For each element in the queue, execute getUsersForSkill to fetch the users' list.
 */
- (void)startCrawl {
    [self.crawlerService getFilterList:^(Filters * _Nonnull filters) {
        Skill *skill;
        NSUInteger count = 0;  // TOD): test remove later
        NSUInteger page = 1;
        NSUInteger skillId;
        UserFetchState *fetchState;
        for (skill in filters.skills) {
            //if (count < 2) {
                skillId = skill.skillId;
                page = 1;
                fetchState = [self.crawlerService.crawlerState.fetchState objectForKey:@(skillId)];
                if (!fetchState) {
                    fetchState = [UserFetchState new];
                } else {
                    page = fetchState.page + 1;
                }
                fetchState.page = page;
                fetchState.skillId = [NSString stringWithFormat:@"%ld", skillId];
                [self.fetchTable setObject:fetchState forKey:@(skillId)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self scheduleFetch:skillId];
                });
            //}
            //count++;
        }
    }];
}

/** Pause scroll for the next batch. */
- (void)pauseCrawl {
}

/** Get random number with normal distribution characteristics that has a standard deviation from the set mean. */
- (NSInteger)random {
    return self.gaussianDistribution.nextInt;
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
    debug(@"fetch table count: %ld", [self.fetchTable count]);
    debug(@"perform fetch %@", index);
    UserFetchState *fetchState = [self.fetchTable objectForKey:index];
    if (fetchState) {
        [self.crawlerService getUsersForSkill:fetchState.skillId page:fetchState.page max:[Const maxUserLimit] callback:^(UserSearchResponse * _Nonnull resp) {
            debug(@"user search response: %@", resp);
            User *user;
            bool ret;
            for (user in resp.usersList) {
                ret = [self.fdbService insertUser:user];
                debug(@"insert status: %d", ret);
            }
        }];
        [self.runTable setObject:fetchState forKey:index];  // clear the state from fetch table
        [self.fetchTable removeObjectForKey:index];  // add the state to run table
    }
}

@end
