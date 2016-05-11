//
//  XYLScanView.h
//  XYLScaningCode
//
//  Created by 薛银亮 on 16/2/22.
//  Copyright © 2016年 薛银亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Config.h"

@protocol XYLScanViewDelegate <NSObject>
- (void)view:(UIView*)view didCatchGesture:(UIGestureRecognizer *)gesture;
@end

@interface XYLScanView : UIView

@property (weak, nonatomic) id<XYLScanViewDelegate> delegate;
@property (assign , nonatomic) XYLScaningLineMoveMode lineMoveMode;
@property (assign, nonatomic) XYLScaningLineMode lineMode;
@property (assign, nonatomic) XYLScaningWarningTone warninTone;

- (instancetype)initWithFrame:(CGRect)frame lineMode:(XYLScaningLineMode)lineMode ineMoveMode:(XYLScaningLineMoveMode)lineMoveMode;
- (NSInteger)width;
- (NSInteger)height;
-(void)stopMove;
@end
