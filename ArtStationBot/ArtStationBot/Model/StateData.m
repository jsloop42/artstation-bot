//
//  StateData.m
//  ArtStationBot
//
//  Created by jsloop on 04/08/19.
//

#import "StateData.h"

static StateData *_state;

@implementation StateData

+ (void)initialize {
    if (self == [self class]) {
        if (!_state) _state = [StateData new];
    }
}

+ (instancetype)shared {
    return _state;
}

@end
