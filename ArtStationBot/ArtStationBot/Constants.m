//
//  Constants.m
//  ArtStationBot
//
//  Created by jsloop on 01/08/19.
//

#import "Constants.h"

static NSString *_seedURL;
static NSString *_csrfURL;
static NSString *_contentTypeJSON;
static NSString *_host;
static NSString *_filterFieldsFrag;

@implementation Constants

+ (void)initialize {
    if (self == [self class]) {
        [self bootstrap];
    }
}

+ (void)bootstrap {
    _seedURL = @"https://artstation.com/";
    _csrfURL = [NSString stringWithFormat:@"%@api/v2/csrf_protection/token.json", _seedURL];
    _contentTypeJSON = @"application/json";
    _host = @"artstation.com";
    _filterFieldsFrag = @"api/v2/search/users/filter_fields.json";
}

+ (NSString *)seedURL {
    return _seedURL;
}

+ (NSString *)csrfTokenURL {
    return _csrfURL;
}

+ (NSString *)contentTypeJSON {
    return _contentTypeJSON;
}

+ (NSString *)domain {
    return _host;
}

+ (NSString *)filterListFragment {
    return _filterFieldsFrag;
}

+ (NSString *)filterListURL {
    return [NSString stringWithFormat:@"%@%@", _seedURL, _filterFieldsFrag];
}

@end
