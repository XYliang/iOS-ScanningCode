//
//  XYLBinaryCodeView.m
//  XYLScaningCode
//
//  Created by 薛银亮 on 16/2/23.
//  Copyright © 2016年 薛银亮. All rights reserved.
//

#import "XYLBinaryCodeView.h"
#import <CoreImage/CoreImage.h>
#import "UIView+extension.h"
#import "Config.h"
#define imageViewWH 200 //二维码的大小

@interface XYLBinaryCodeView()

@property(weak, nonatomic)UIView *backView;
@end
@implementation XYLBinaryCodeView

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        [self setupView];
    }
    return self;
}

-(void)setInputData:(NSString *)inputData
{
    _inputData = inputData;
    [self createBinaryCode];
}

-(void)setupView
{
    CGFloat backViewWH = [self setWidth];
    CGFloat backViewY = ([UIScreen mainScreen].bounds.size.height - [self setWidth]) / 2.0f;
    CGFloat backViewX = (self.width - backViewWH) / 2.0f;
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(backViewX, backViewY, backViewWH, backViewWH)];
    backView.backgroundColor = [UIColor whiteColor];
    self.backView = backView;
    [self addSubview:backView];
    
    CGFloat imageViewXY = (backViewWH - imageViewWH) / 2.0f;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(imageViewXY, imageViewXY, imageViewWH, imageViewWH)];
    self.imageView = imageView;
    [self.backView addSubview:imageView];
}

-(void)createBinaryCode
{
    // 1.创建滤镜对象
    CIFilter *fiter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.设置相关属性
    [fiter setDefaults];
    
    // 3.设置输入数据
    NSString *inputData = self.inputData;
    NSData *data = [inputData dataUsingEncoding:NSUTF8StringEncoding];
    [fiter setValue:data forKeyPath:@"inputMessage"];
    
    // 4.获取输出结果
    CIImage *outputImage = [fiter outputImage];
    
    // 5.显示二维码
    self.imageView.image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:imageViewWH];
}

/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
- (NSInteger)setWidth{
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

@end
