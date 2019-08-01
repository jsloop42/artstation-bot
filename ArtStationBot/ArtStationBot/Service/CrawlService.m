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

- (void)getFilterList:(void (^)(NSDictionary *))callback {
    //CrawlService __block *weakSelf = self;
    NSURLComponents *comp = [[NSURLComponents alloc] initWithString:Constants.filterListURL];
    debug(@"url: %@", comp);
    NSDictionary *headers = @{@"PUBLIC-CSRF-TOKEN": _csrfToken};
    [self.nwsvc getWithComp:comp headers:headers callback:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //CrawlService *this = weakSelf;
        NSError *err;
        NSDictionary *ret;
        if (data) {
            ret = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            debug(@"Skills list is %@", ret);
            callback(ret);
        }
    }];
}

@end
