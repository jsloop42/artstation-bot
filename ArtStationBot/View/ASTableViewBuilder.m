//
//  ASTableView.m
//  ArtStationBot
//
//  Created by jsloop on 11/08/19.
//

#import "ASTableViewBuilder.h"

@implementation ASTableViewBuilder {
    NSScrollView *_scrollView;
    NSTextField *_cellTextField;
}

@synthesize tableView;

- (NSScrollView *)tableViewWithView:(NSView *)view columns:(NSUInteger)columns columnNames:(NSMutableArray *)columnNames
                        tableViewId:(enum ASTableView)tableViewId {
    _scrollView = [[NSScrollView alloc] initWithFrame:view.bounds];
    [_scrollView setBorderType:NSBezelBorder];
    self.tableView = [[NSTableView alloc] initWithFrame:view.bounds];
    NSTableColumn *col;
    NSInteger i = 0;
    for (i = 0; i < columns; i++) {
        col = [[NSTableColumn alloc] initWithIdentifier:[columnNames objectAtIndex:i]];
        if (tableViewId == ASTableViewSettings) {
            if (i == 2) {
                [col setWidth: NSApp.mainWindow.frame.size.width - 672];
            } else if (i == 1) {
                [col setWidth:320];
            } else {
                [col setWidth:100];
            }
        } else {
            [col setWidth:100];
        }
        [[col headerCell] setStringValue:[columnNames objectAtIndex:i]];
        [self.tableView addTableColumn:col];
    }
    [self.tableView setUsesAlternatingRowBackgroundColors:YES];
    [self.tableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
    [self.tableView setRowHeight:23.0];
    [self.tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
    [self.tableView setAutoresizesSubviews:YES];
    [self.tableView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:NO];
    [_scrollView setAutoresizesSubviews:YES];
    [_scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_scrollView setDocumentView:self.tableView];

    return _scrollView;
}

@end


