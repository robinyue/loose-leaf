//
//  MMListSidebarStackView.m
//  LooseLeaf
//
//  Created by Adam Wulf on 10/18/16.
//  Copyright © 2016 Milestone Made, LLC. All rights reserved.
//

#import "MMListSidebarStackView.h"
#import "NSArray+Extras.h"


@interface MMListPaperStackView (Protected)

- (void)realignPagesInListView:(NSSet*)pagesToMove animated:(BOOL)animated forceRecalculateAll:(BOOL)recalculateAll;

- (void)ensurePageIsAtTopOfVisibleStack:(MMPaperView*)aPage;

- (CGRect)frameForListViewForPage:(MMPaperView*)page;

@end


@implementation MMListSidebarStackView

- (CGRect)frameForListViewForPage:(MMPaperView*)page {
    CGRect fr = [super frameForListViewForPage:page];

    if ([[self.stackDelegate.bezelPagesContainer viewsInSidebar] count]) {
        CGFloat maxMove = 120;
        CGFloat maxX = CGRectGetWidth([self.stackDelegate.bezelPagesContainer bounds]);
        CGFloat movement = (fr.origin.x) / maxX * maxMove + kWidthOfSidebarButtonBuffer;
        fr.origin.x -= movement;
    }

    return fr;
}

- (CGPoint)addPageBackToListViewAndAnimateOtherPages:(MMPaperView*)page {
    CGPoint locInSelf = [self convertPoint:page.center fromView:page.superview];

    NSArray* currentlyVisiblePages = [self findPagesInVisibleRowsOfListView];
    MMPaperView* nearbyPage = [self findPageClosestToOffset:locInSelf];

    if (nearbyPage) {
        [self ensurePageIsAtTopOfVisibleStack:nearbyPage];
        [self addPage:page belowPage:nearbyPage];
        [page disableAllGestures];
    } else {
        [visibleStackHolder pushSubview:page];
    }

    // animate pages into their new location
    [self realignPagesInListView:[NSSet setWithArray:currentlyVisiblePages] animated:YES forceRecalculateAll:YES];

    // immediately move non-visible pages to their new location
    NSMutableSet* allOtherPages = [NSMutableSet setWithArray:visibleStackHolder.subviews];
    [allOtherPages addObjectsFromArray:hiddenStackHolder.subviews];
    [allOtherPages removeObjectsInArray:currentlyVisiblePages];
    [self realignPagesInListView:allOtherPages animated:NO forceRecalculateAll:NO];

    CGRect fr = [self frameForListViewForPage:page];
    page.bounds = CGRectFromSize(fr.size);

    return CGRectGetMidPoint(fr);
}

- (MMPaperView*)findPageClosestToOffset:(CGPoint)offsetOfListView {
    //
    // scrolling is enabled, so we need to return
    // the list of pages that are currently visible

    NSArray* arraysOfSubviews[2];
    arraysOfSubviews[0] = visibleStackHolder.subviews;
    arraysOfSubviews[1] = hiddenStackHolder.subviews;
    int countOfSubviews[2]; // can't be NSUInteger, or -1 < count will be false
    countOfSubviews[0] = (int)[visibleStackHolder.subviews count];
    countOfSubviews[1] = (int)[hiddenStackHolder.subviews count];

    NSArray* allPages = [visibleStackHolder.subviews arrayByAddingObjectsFromArray:[hiddenStackHolder.subviews reversedArray]];

    int startRow = floor(offsetOfListView.y) / (self.bufferWidth + self.rowHeight);
    int startCol = floor(offsetOfListView.x) / (self.bufferWidth + self.columnWidth);
    int startIndex = startRow * kNumberOfColumnsInListView + startCol;

    NSInteger endIndex = startIndex + kNumberOfColumnsInListView;
    startIndex -= kNumberOfColumnsInListView;

    startIndex = MAX(0, startIndex);
    endIndex = MIN([allPages count] - 1, endIndex);

    if (endIndex >= startIndex) {
        NSArray* closePages = [allPages subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex + 1)];
        return [closePages jotReduce:^id(id obj, NSUInteger index, MMPaperView* accum) {
            CGRect fr1 = [self frameForListViewForPage:obj];
            CGRect fr2 = [self frameForListViewForPage:accum];
            CGFloat d1 = DistanceBetweenTwoPoints(offsetOfListView, CGRectGetMidPoint(fr1));
            CGFloat d2 = DistanceBetweenTwoPoints(offsetOfListView, CGRectGetMidPoint(fr2));
            if (!accum || d1 < d2) {
                return obj;
            } else {
                return accum;
            }
        }];
    }
    return nil;
}


@end