//
//  ASTableView.h
//  ArtStationBot
//
//  Created by jsloop on 11/08/19.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ASTableView) {
    ASTableViewSettings,
    ASTableViewCrawlSchedule,
    ASTableViewCrawlProgress,
    ASTableViewMessageSchedule,
    ASTableViewMessageProgress
};

@interface ASTableViewBuilder : NSObject
@property (nonatomic, readwrite, retain) NSTableView *tableView;
- (NSScrollView *)tableViewWithView:(NSView *)view columns:(NSUInteger)columns columnNames:(NSMutableArray *)columnNames
                        tableViewId:(enum ASTableView)tableViewId;
@end

NS_ASSUME_NONNULL_END
