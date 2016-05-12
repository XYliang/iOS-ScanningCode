//
//  XYLScanView.m
//  XYLScaningCode
//
//  Created by 薛银亮 on 16/2/22.
//  Copyright © 2016年 薛银亮. All rights reserved.
//

#import "XYLScanView.h"


@interface XYLScanView()


@property (strong, nonatomic) UIView *line;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGFloat origin;
@property (assign, nonatomic) BOOL isReachEdge;
@end

@implementation XYLScanView

- (instancetype)initWithFrame:(CGRect)frame lineMode:(XYLScaningLineMode)lineMode ineMoveMode:(XYLScaningLineMoveMode)lineMoveMode{
    self = [super initWithFrame:frame];
    if (self) {
        [self initConfigWithLineMode:lineMode ineMoveMode:lineMoveMode];
    }
    return self;
}

- (void)initConfigWithLineMode:(XYLScaningLineMode)lineMode ineMoveMode:(XYLScaningLineMoveMode)lineMoveMode
{
    self.backgroundColor = [UIColor clearColor];
    //添加滑动返回手势
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(viewWillDisappear:) name:@"ViewWillDisappearNotification" object:nil];
    UIScreenEdgePanGestureRecognizer *edgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(gesture:)];
    [edgePanGesture setEdges:UIRectEdgeLeft];
    [self addGestureRecognizer:edgePanGesture];
    //设置扫描模式
    self.lineMode = lineMode ? lineMode : XYLScaningLineModeDeafult;
    self.lineMoveMode = lineMoveMode ? lineMoveMode : XYLScaningLineMoveModeDown;
    //创建扫描线
    self.line = [self creatLine];
    [self addSubview:self.line];
    [self starMove];
}

- (void)gesture:(UIScreenEdgePanGestureRecognizer *)edgePanGesture{
    [self.delegate view:self didCatchGesture:edgePanGesture];
}

/**
 *  创建扫描线
 */
- (UIView *)creatLine{
    
    if (_lineMoveMode == XYLScaningLineMoveModeNone) return nil;
    
    UIView *line = [[UIView alloc]initWithFrame:CGRectMake(ScreenSize.width*.5 - TransparentArea([self width],[self height]).width*.5,
                                                           ScreenSize.height*.5 - TransparentArea([self width], [self height]).height*.5,
                                                           TransparentArea([self width],[self height]).width,
                                                           2)];
    
    if (_lineMode == XYLScaningLineModeDeafult) {
        line.backgroundColor = LineColor;
        self.origin = line.frame.origin.y;
    }
    
    if (_lineMode == XYLScaningLineModeImge) {
        line.backgroundColor = [UIColor clearColor];
        self.origin = line.frame.origin.y;
        UIImageView *v = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"line@2x.png"]];
        v.contentMode = UIViewContentModeScaleAspectFill; 
        v.frame = CGRectMake(0, 0, line.frame.size.width, line.frame.size.height);
        [line addSubview:v];
    }
    
    if (_lineMode == XYLScaningLineModeGrid) {
        line.clipsToBounds = YES;
        CGRect frame = line.frame;
        frame.size.height = TransparentArea([self width], [self height]).height;
        line.frame = frame;
        UIImageView *iv = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"scan_net@2x.png"]];
        iv.frame = CGRectMake(0, -TransparentArea([self width], [self height]).height, line.frame.size.width, TransparentArea([self width], [self height]).height);
        [line addSubview:iv];
    }
    return line;
}

/**
 *  开始扫描
 */
- (void)starMove
{
    if (_lineMode == XYLScaningLineModeDeafult) {  //注意！！！此模式非常消耗性能
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.0125 target:self selector:@selector(showLine) userInfo:nil repeats:YES];
        [self.timer fire];
    }
    if (_lineMode == XYLScaningLineModeImge) {
        [self showLine];
    }
    if (_lineMode == XYLScaningLineModeGrid) {
        
        UIImageView *iv = _line.subviews[0];
        [UIView animateWithDuration:1.5 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            iv.transform = CGAffineTransformTranslate(iv.transform, 0, TransparentArea([self width], [self height]).height);
        } completion:^(BOOL finished)
        {
            iv.frame = CGRectMake(0, -TransparentArea([self width], [self height]).height, _line.frame.size.width, TransparentArea([self width], [self height]).height);
            [self starMove];
        }];
    }
}

-(void)stopMove
{
    [self.line removeFromSuperview];
    self.line = nil;
    if (_lineMode == XYLScaningLineModeDeafult) {  //注意！！！此模式非常消耗性能
        [self.timer invalidate];
    }
}

- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 40/255.0, 40/255.0, 40/255.0, .5);
    CGContextFillRect(context, rect);
    CGRect clearDrawRect = CGRectMake(rect.size.width / 2 - TransparentArea([self width], [self height]).width / 2,
                                      rect.size.height / 2 - TransparentArea([self width], [self height]).height / 2,
                                      TransparentArea([self width], [self height]).width,TransparentArea([self width], [self height]).height);
    
    CGContextClearRect(context, clearDrawRect);
    [self addWhiteRect:context rect:clearDrawRect];
    [self addCornerLineWithContext:context rect:clearDrawRect];
}

- (void)addCornerLineWithContext:(CGContextRef)ctx rect:(CGRect)rect{
    
    //画四个边角
    CGContextSetLineWidth(ctx, 2);
    CGContextSetRGBStrokeColor(ctx, 83 /255.0, 239/255.0, 111/255.0, 1);//绿色
    
    //左上角
    CGPoint poinsTopLeftA[] = {
        CGPointMake(rect.origin.x+0.7, rect.origin.y),
        CGPointMake(rect.origin.x+0.7 , rect.origin.y + 15)
    };
    CGPoint poinsTopLeftB[] = {CGPointMake(rect.origin.x, rect.origin.y +0.7),CGPointMake(rect.origin.x + 15, rect.origin.y+0.7)};
    [self addLine:poinsTopLeftA pointB:poinsTopLeftB ctx:ctx];
    //左下角
    CGPoint poinsBottomLeftA[] = {CGPointMake(rect.origin.x+ 0.7, rect.origin.y + rect.size.height - 15),CGPointMake(rect.origin.x +0.7,rect.origin.y + rect.size.height)};
    CGPoint poinsBottomLeftB[] = {CGPointMake(rect.origin.x , rect.origin.y + rect.size.height - 0.7) ,CGPointMake(rect.origin.x+0.7 +15, rect.origin.y + rect.size.height - 0.7)};
    [self addLine:poinsBottomLeftA pointB:poinsBottomLeftB ctx:ctx];
    //右上角
    CGPoint poinsTopRightA[] = {CGPointMake(rect.origin.x+ rect.size.width - 15, rect.origin.y+0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y +0.7 )};
    CGPoint poinsTopRightB[] = {CGPointMake(rect.origin.x+ rect.size.width-0.7, rect.origin.y),CGPointMake(rect.origin.x + rect.size.width-0.7,rect.origin.y + 15 +0.7 )};
    [self addLine:poinsTopRightA pointB:poinsTopRightB ctx:ctx];
    
    CGPoint poinsBottomRightA[] = {CGPointMake(rect.origin.x+ rect.size.width -0.7 , rect.origin.y+rect.size.height+ -15),CGPointMake(rect.origin.x-0.7 + rect.size.width,rect.origin.y +rect.size.height )};
    CGPoint poinsBottomRightB[] = {CGPointMake(rect.origin.x+ rect.size.width - 15 , rect.origin.y + rect.size.height-0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height - 0.7 )};
    [self addLine:poinsBottomRightA pointB:poinsBottomRightB ctx:ctx];
    CGContextStrokePath(ctx);
}

- (void)addLine:(CGPoint[])pointA pointB:(CGPoint[])pointB ctx:(CGContextRef)ctx
{
    CGContextAddLines(ctx, pointA, 2);
    CGContextAddLines(ctx, pointB, 2);
}


- (void)addWhiteRect:(CGContextRef)ctx rect:(CGRect)rect
{
    /**
     *  绘制rect路径
     Quartz uses the line width and stroke color of the graphics state to paint the path. As a side effect when you call this function, Quartz clears the current path:解释：Quartz使用指定线宽和颜色来绘制路径，但是有一个副作用 就是绘制前会清空之前的路径
     */
    CGContextStrokeRect(ctx, rect);
    /**
     *  绘制刚才的路径的颜色
     Quartz sets the current stroke color to the value specified by the red, green, blue, and alpha parameters.解释：使用提供的红绿蓝透明度来绘制指定的路径
     */
    CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
    /**
     *  设置线宽
     */
    CGContextSetLineWidth(ctx, 0.8);
    /**
     *  把画出的图形添加到上下文
     This is a convenience function that adds a rectangle to a path：添加矩形到上下文
     */
    CGContextAddRect(ctx, rect);
    /**
     *  开始绘制图片
     */
    CGContextStrokePath(ctx);
}

/**
 *  展示扫描线
 */
- (void)showLine
{
    if (_lineMode == XYLScaningLineModeDeafult)
    {
        CGRect frame = self.line.frame;
        self.isReachEdge?(frame.origin.y -= LineMoveSpeed):(frame.origin.y += LineMoveSpeed);
        self.line.frame = frame;
        
        UIView *shadowLine = [[UIView alloc]initWithFrame:self.line.frame];
        shadowLine.backgroundColor = self.line.backgroundColor;
        [self addSubview:shadowLine];
        [UIView animateWithDuration:LineShadowLastInterval animations:^{
            shadowLine.alpha = 0;
        } completion:^(BOOL finished) {
            [shadowLine removeFromSuperview];
        }];
        
        if (_lineMoveMode == XYLScaningLineMoveModeDown) {
            if (self.line.frame.origin.y - self.origin >= TransparentArea([self width], [self height]).height) {
                [self.line removeFromSuperview];
                CGRect frame = self.line.frame;
                frame.origin.y = ScreenSize.height*.5 - TransparentArea([self width], [self height]).height*.5;
                self.line.frame = frame;
            }
            
        }else if(_lineMoveMode==XYLScaningLineMoveModeUpAndDown){
            if (self.line.frame.origin.y - self.origin >= TransparentArea([self width], [self height]).height) {
                self.isReachEdge = !self.isReachEdge;
            }else if (self.line.frame.origin.y == self.origin){
                self.isReachEdge = !self.isReachEdge;
            }
        }
    }
    
    if (_lineMode == XYLScaningLineModeImge) {
        [self imagelineMoveWithMode:_lineMoveMode];
    }
    
}

/**
 *  扫描线运动模式
 */
- (void)imagelineMoveWithMode:(XYLScaningLineMoveMode)mode
{
    [UIView animateWithDuration:2 animations:^{
        CGRect frame = self.line.frame;
        frame.origin.y +=  TransparentArea([self width], [self height]).height-2;
        self.line.frame = frame;
    } completion:^(BOOL finished) {
        if (mode == XYLScaningLineMoveModeDown) {
            CGRect frame = self.line.frame;
            frame.origin.y = ScreenSize.height*.5 - TransparentArea([self width], [self height]).height*.5;
            self.line.frame = frame;
            [self imagelineMoveWithMode:mode];
        }else{
            [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect frame = self.line.frame;
                frame.origin.y = ScreenSize.height*.5 - TransparentArea([self width], [self height]).height*.5;
                self.line.frame = frame;
            } completion:^(BOOL finished) {
                [self imagelineMoveWithMode:mode];
            }];
        }
    }];
}


- (NSInteger)width{
    if (Iphone4||Iphone5) {
        return Iphone45ScanningSize_width;
    }else if(Iphone6){
        return Iphone6ScanningSize_width;
    }else if(Iphone6Plus){
        return Iphone6PlusScanningSize_width;
    }else{
        return Iphone45ScanningSize_width;
    }
}

- (NSInteger)height{
    if (Iphone4||Iphone5) {
        return Iphone45ScanningSize_height;
    }else if(Iphone6){
        return Iphone6ScanningSize_height;
    }else if(Iphone6Plus){
        return Iphone6PlusScanningSize_height;
    }else{
        return Iphone45ScanningSize_height;
    }
}

- (void)viewWillDisappear:(NSNotification *)noti{
    [self.timer invalidate];
    self.timer = nil;
}

@end
