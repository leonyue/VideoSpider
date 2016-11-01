//
//  VideoTableViewCell.m
//  LeonYueTool
//
//  Created by YC-JG-YXKF-PC35 on 2016/10/20.
//  Copyright © 2016年 YC-JG-YXKF-PC35. All rights reserved.
//

#import "VideoTableViewCell.h"

@interface VideoTableViewCell ()

//@property (nonatomic,strong) CAGradientLayer *progressLayer;

@end

@implementation VideoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

//    [self addProgressLayer];
    // Initialization code
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

//- (void)addProgressLayer {
//    self.progressLayer = [CAGradientLayer ];
//    self.progressLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
//    [self setProgressLayerFrame];
//    [self.layer addSublayer:self.progressLayer];
//}

//- (void)setProgressLayerFrame {
//    CGRect rect = self.bounds;
//    rect.size.width = rect.size.width * self.progress;
//    self.progressLayer.frame = rect;
//}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    [self setProgressLayerFrame];
//}

- (void)setProgress:(double)progress {
    _progress = progress;
    CAGradientLayer *layer = self.layer;
    layer.colors = @[(__bridge id)[UIColor greenColor].CGColor,(__bridge id)[UIColor greenColor].CGColor,(__bridge id)[UIColor clearColor].CGColor];
    layer.locations = @[@(0.f),@(0.99f),@(1.f)];
//    layer.locations
    layer.startPoint = CGPointMake(0, 0.5);
    layer.endPoint = CGPointMake(progress, 0.5);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
