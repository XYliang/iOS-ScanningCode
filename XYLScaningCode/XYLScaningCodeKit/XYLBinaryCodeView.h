//
//  XYLBinaryCodeView.h
//  XYLScaningCode
//
//  Created by 薛银亮 on 16/2/23.
//  Copyright © 2016年 薛银亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYLBinaryCodeView : UIView
@property(strong, nonatomic)UIImageView *imageView;
@property(strong, nonatomic)NSString *inputData;//设置二维码内容字符串：例如设置二维码包含的内容是inputData=@"www.baidu.com"
- (NSInteger)setWidth;
- (NSInteger)height;
@end
