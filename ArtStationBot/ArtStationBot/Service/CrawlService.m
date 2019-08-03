//
//  CrawlService.m
//  ArtStationBot
//
//  Created by jsloop on 01/08/19.
//

#import "CrawlService.h"
#import "ArtStationBot-Swift.h"
#import "Constants.h"

@interface CrawlService ()
@property (nonatomic, readwrite) NetworkService *nwsvc;
@property (nonatomic, readwrite) Filters *filters;
@end

@implementation CrawlService {
    NetworkService *_nwsvc;
    NSString *_csrfToken;
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
    _csrfToken = @"";
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
            debug(@"CSRF token:  %@", this->_csrfToken);
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
    debug(@"url: %@", comp);
    NSDictionary *headers = @{@"PUBLIC-CSRF-TOKEN": _csrfToken};
    [self.nwsvc getWithComp:comp headers:headers callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        CrawlService *this = weakSelf;
        NSError *err;
        NSArray *ret;
        if (data) {
            ret = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            debug(@"Skills list is %@", ret);
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
                            skill.skillId = (NSUInteger)[idict valueForKey:@"id"];
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
                            software.softwareId = (NSUInteger)[idict valueForKey:@"id"];
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

@end
