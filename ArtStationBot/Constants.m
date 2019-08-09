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
static NSString *_searchUsers;
static NSString *_csrfTokenHeader;
static NSString *_cfCSRFTokenHeader;
static NSUInteger _maxUserLimit;

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
    _searchUsers = @"api/v2/search/users.json";
    _csrfTokenHeader = @"PUBLIC-CSRF-TOKEN";
    _cfCSRFTokenHeader = @"x-csrf-token";
    _maxUserLimit = 15;
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

+ (NSString *)searchUsersURL {
    return [NSString stringWithFormat:@"%@%@", _seedURL, _searchUsers];
}

+ (NSString *)csrfTokenHeader {
    return _csrfTokenHeader;
}

+ (NSString *)cloudFlareCSRFTokenHeader {
    return _cfCSRFTokenHeader;
}

+ (NSUInteger)maxUserLimit {
    return _maxUserLimit;
}

@end

@implementation ASNotification
static NSString *_sendMessage = @"sendMessage";
static NSString *_sendMessageACK = @"sendMessageACK";

@dynamic sendMessage;
@dynamic sendMessageACK;

+ (NSString *)sendMessage {
    return _sendMessage;
}

+ (NSString *)sendMessageACK {
    return _sendMessageACK;
}

@end
