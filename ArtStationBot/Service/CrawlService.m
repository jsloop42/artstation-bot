//
//  CrawlService.m
//  ArtStationBot
//
//  Created by jsloop on 01/08/19.
//

#import "CrawlService.h"
#import "ArtStationBot-Swift.h"

@interface CrawlService ()
@property (nonatomic, readwrite) NetworkService *nwsvc;
@property (nonatomic, readwrite) Filters *filters;
@end

@implementation CrawlService {
    NetworkService *_nwsvc;
    NSString *_csrfToken;
    dispatch_queue_t _dispatchQueue;
}

@synthesize nwsvc = _nwsvc;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self bootstrap];
    }
    return self;
}

- (void)bootstrap {
    _nwsvc = [NetworkService new];
    _nwsvc.queueType = QueueTypeBackground;
    _dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT , 0);
    _csrfToken = @"";
    self.crawlerState = [CrawlerState new];
}

- (void)getCSRFToken:(void (^)(NSString *))callback {
    CrawlService __block *weakSelf = self;
    [self.nwsvc postWithUrl:Constants.csrfTokenURL body:nil headers:nil callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response,
                                                                                   NSError * _Nullable error) {
        CrawlService *this = weakSelf;
        NSError *err;
        NSDictionary *resp;
        if (data) {
            resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            this->_csrfToken = resp[@"public_csrf_token"];
            callback(this->_csrfToken);
        } else {
            error(@"Error getting CSRF token: %@", error);
            callback(@"");
        }
    }];
}

- (void)getFilterList:(void (^)(Filters *))callback {
    CrawlService __block *weakSelf = self;
    NSURLComponents *comp = [[NSURLComponents alloc] initWithString:Constants.filterListURL];
    NSDictionary *headers = @{@"PUBLIC-CSRF-TOKEN": _csrfToken};
    [self.nwsvc getWithComp:comp headers:headers callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        CrawlService *this = weakSelf;
        NSError *err;
        NSArray *ret;
        if (data) {
            ret = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            Filters *filters = [Filters new];
            NSDictionary *odict = nil;
            NSDictionary *idict = nil;
            NSArray *arr = nil;
            for (odict in ret) {
                if ([[odict valueForKey:@"name"] isEqual:@"skill_ids"]) {
                    arr = [odict valueForKey:@"select_options"];
                    if ([arr count] > 0) {
                        filters.skills = [NSMutableArray new];
                        for (idict in arr) {
                            Skill *skill = [Skill new];
                            skill.skillId = [(NSNumber *)[idict valueForKey:@"id"] integerValue];
                            skill.name = [idict valueForKey:@"name"];
                            [filters.skills addObject:skill];
                        }
                    }
                } else if ([[odict valueForKey:@"name"] isEqual:@"countries"]) {
                    arr = [odict valueForKey:@"select_options"];
                    if ([arr count] > 0) {
                        filters.countries = [NSMutableArray new];
                        for (idict in arr) {
                            Country *country = [Country new];
                            country.countryId = [idict valueForKey:@"id"];
                            country.name = [idict valueForKey:@"name"];
                            [filters.countries addObject:country];
                        }
                    }
                } else if ([[odict valueForKey:@"name"] isEqual:@"software_ids"]) {
                    arr = [odict valueForKey:@"select_options"];
                    if ([arr count] > 0) {
                        filters.software = [NSMutableArray new];
                        for (idict in arr) {
                            Software *software = [Software new];
                            software.softwareId = [(NSNumber *)[idict valueForKey:@"id"] integerValue];
                            software.iconURL = [idict valueForKey:@"icon_url"];
                            software.name = [idict valueForKey:@"name"];
                            [filters.software addObject:software];
                        }
                    }
                } else if ([[odict valueForKey:@"name"] isEqual:@"availability"]) {
                    arr = [odict valueForKey:@"select_options"];
                    if ([arr count] > 0) {
                        filters.availabilities = [NSMutableArray new];
                        for (idict in arr) {
                            Availability *availability = [Availability new];
                            availability.availabilityId = [idict valueForKey:@"id"];
                            availability.name = [idict valueForKey:@"name"];
                            [filters.availabilities addObject:availability];
                        }
                    }
                }
            }
            this.filters = filters;
            callback(filters);
        }
    }];
}

- (void)getUsersForSkill:(NSString *)skillId page:(NSUInteger)page max:(NSUInteger)max callback:(void (^) (UserSearchResponse *))callback {
    [self getCSRFToken:^(NSString * _Nonnull csrfToken) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setValue:@"" forKey:@"query"];
        [dict setValue:@(page) forKey:@"page"];
        [dict setValue:@([Constants maxUserLimit]) forKey:@"per_page"];  // Since the website uses 15 users per page, we have to use the same
        [dict setValue:@"followers" forKey:@"sorting"];
        [dict setValue:@"1" forKey:@"pro_first"];
        [dict setObject:@[@{@"field": @"skill_ids", @"method": @"include", @"value": @[skillId]}] forKey:@"filters"];
        [dict setObject:@[] forKey:@"additional_fields"];
        NSData *body = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        [self.nwsvc postWithUrl:[Constants searchUsersURL] body:body
                        headers:@{[Constants csrfTokenHeader]: csrfToken, [Constants cloudFlareCSRFTokenHeader]: csrfToken}
                       callback:^(NSData * _Nullable data, NSURLResponse * _Nullable resp, NSError * _Nullable err) {
           NSError *aErr;
           NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&aErr];
           UserSearchResponse *uresp = [UserSearchResponse new];
           if (err || aErr) {
               uresp.status = NO;
               callback(uresp);
               return;
           }
           uresp.status = YES;
           uresp.usersList = [NSMutableArray new];
           uresp.totalCount = (NSUInteger)[(NSString *)[jsonDict valueForKey:@"total_count"] integerValue];
           uresp.skillId = skillId;
           uresp.page = page;
           UserFetchState *userFetchState = [self.crawlerState.fetchState objectForKey:@((NSUInteger)[skillId integerValue])];
           if (!userFetchState) userFetchState = [UserFetchState new];
           userFetchState.skillId = skillId;
           userFetchState.page = page;
           userFetchState.totalCount = uresp.totalCount;
           [self.crawlerState.fetchState setObject:userFetchState forKey:skillId];
           NSMutableArray *usersList;
           id val = [jsonDict objectForKey:@"data"];
           if (val && val != [NSNull null]) usersList = (NSMutableArray *)val;
           NSMutableDictionary *dict;
           if ([usersList count] > 0) {
               User *user;
               for (dict in usersList) {
                   user = [ModelUtils.shared userFromDictionary:dict convertType:ConvertTypeJSON];
                   [uresp.usersList addObject:user];
               }
           }
           callback(uresp);
        }];
    }];
}

@end
