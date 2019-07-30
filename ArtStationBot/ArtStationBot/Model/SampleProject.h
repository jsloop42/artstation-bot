//
//  SampleProject.h
//  ArtStationBot
//
//  Created by jsloop on 30/07/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleProject : NSObject
@property (nonatomic, readwrite) NSUInteger sampleProjectId;
@property (nonatomic, readwrite) NSString *smallerSquareCoverURL;
@property (nonatomic, readwrite) NSString *url;
@property (nonatomic, readwrite) NSString *title;
@end

NS_ASSUME_NONNULL_END
