//
//  LRQImageTableViewCell.h
//  LRQWebImage
//
//  Created by lirenqiang on 2017/11/28.
//  Copyright © 2017年 lirenqiang. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const cellId;
extern NSInteger const cellHeight;
@interface LRQImageTableViewCell : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexpath;

- (void)setCellImageURL:(NSURL *)url title:(NSString *)titleString;

@end
