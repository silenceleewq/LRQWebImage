//
//  LRQImageTableViewCell.m
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import "LRQImageTableViewCell.h"
#import "UIImageView+LRQWebCache.h"

NSString *const cellId = @"cellId";
NSInteger const cellHeight = 88;
CGFloat const topMargin = 4;
@interface LRQImageTableViewCell ()
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *iconLabel;
@end

@implementation LRQImageTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexpath
{
    LRQImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexpath];
    
    if (!cell) {
        cell = [[LRQImageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    return cell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addSubviews];
        [self setSubviewsFrame];
    }
    return self;
}

- (void)addSubviews {
    [self addSubview:self.iconView];
    [self addSubview:self.iconLabel];
}

- (void)setSubviewsFrame {
    [self.iconView setFrame:[self frameForIconView]];
    [self.iconLabel setFrame:[self frameForIconLabel]];
}

- (void)setCellImageURL:(NSURL *)url title:(NSString *)titleString
{
    self.iconView.image = [UIImage imageNamed:@"placeholder"];
    [self.iconView lrq_setImageWithURL:url];
    self.iconLabel.text = titleString;
}

- (UIImageView *)iconView
{
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:[self frameForIconView]];
    }
    return _iconView;
}

- (UILabel *)iconLabel
{
    if (!_iconLabel) {
        _iconLabel = [[UILabel alloc] initWithFrame:[self frameForIconLabel]];
    }
    return _iconLabel;
}

- (CGRect)frameForIconView
{
    
    CGFloat height = cellHeight - topMargin*2;
    CGFloat width = height *  200/160;
    CGFloat x = topMargin, y = topMargin;
    return CGRectMake(x, y, width, height);
}

- (CGRect)frameForIconLabel
{
    CGFloat x = CGRectGetMaxX([self frameForIconView]) + topMargin;
    CGFloat y = topMargin;
    CGFloat height = CGRectGetHeight([self frameForIconView]);
    CGFloat width = kSCREENWIDTH - x - topMargin;
    
    return CGRectMake(x, y, width, height);
}

@end
