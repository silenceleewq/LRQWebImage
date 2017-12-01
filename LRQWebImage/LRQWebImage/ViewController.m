//
//  ViewController.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/27.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "ViewController.h"
#import "LRQWebImageDownloader.h"
#import "UIImageView+LRQWebCache.h"
#import "LRQImageTableView.h"
#import "LRQImageTableViewCell.h"
#import "LRQImageCache.h"


NSString *str = @"http://www.firsthdwallpapers.com/uploads/2013/05/Free-Hd-Wallpapers-1080p-3.jpg";

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addTableView];
    
    NSLog(@"size: %zd",[[LRQImageCache sharedImageCache] getSize]);
    NSLog(@"count: %zd",[[LRQImageCache sharedImageCache] getDiskCount]);
    [[LRQImageCache sharedImageCache] calculateSizeWithCompletion:^(NSUInteger fileCount, NSUInteger totalSize) {
        NSLog(@"size: %zd, count: %zd", totalSize, fileCount);
    }];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setViewsFrame];
}

- (void)addTableView
{
    self.tableView = [[UITableView alloc] init];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.tableView registerClass:[LRQImageTableViewCell class] forCellReuseIdentifier:cellId];
    [self.view addSubview:self.tableView];
}

- (void)setViewsFrame {
    self.tableView.frame = [self frameForTableView];
}

- (CGRect)frameForTableView
{
    CGFloat x = 0,
    y = self.view.safeAreaInsets.top,
    width = kSCREENWIDTH,
    height = kSCREENHEIGHT - self.view.safeAreaInsets.top;
    return CGRectMake(x, y, width, height);
}

#pragma mark - tableview datasource delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LRQImageTableViewCell *cell = [LRQImageTableViewCell cellWithTableView:tableView indexPath:indexPath];
    
    [self setCellData:cell indexPath:indexPath];
    
    return cell;
}

#pragma mark - tableview delegate method
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return cellHeight;
}

#pragma mark - dispose data

- (void)setCellData:(LRQImageTableViewCell *)cell indexPath:(NSIndexPath *)indexpath
{
    NSDictionary *dict = self.dataArray[indexpath.row];
    NSString *urlString = dict[@"icon"];
    NSURL *url = [NSURL URLWithString:urlString];
    [cell setCellImageURL:url title:@(indexpath.row).stringValue];
}


#pragma mark - lazy load
- (NSArray *)dataArray
{
    if (!_dataArray) {
        NSString *imagePlistPath = [[NSBundle mainBundle] pathForResource:@"ImageList.plist" ofType:nil];
        NSArray *array = [NSArray arrayWithContentsOfFile:imagePlistPath];
        _dataArray = array;
    }
    return _dataArray;
}

@end
























