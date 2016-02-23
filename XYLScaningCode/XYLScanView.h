//
//  XYLScanView.h
//  XYLScaningCode
//
//  Created by 薛银亮 on 16/2/22.
//  Copyright © 2016年 薛银亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XYLScanViewDelegate <NSObject>
- (void)view:(UIView*)view didCatchGesture:(UIGestureRecognizer *)gesture;
@end

@interface XYLScanView : UIView
@property (weak, nonatomic) id<XYLScanViewDelegate> delegate;
- (NSInteger)width;
- (NSInteger)height;
@end
