//
//  HatomSDKPlayer.h
//  flutter_hatomplayer
//
//  Created by chenmengyi on 2022/2/24.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import "HatomOpenGLYUV.h"
#import <hatomplayer_core/PlayConfig.h>

NS_ASSUME_NONNULL_BEGIN

@class HatomSDKPlayer;

@protocol HatomSDKPlayerDeleagete <NSObject>

@optional

// 刷新纹理
- (void)frameUpdate:(NSInteger)textureId;

// native 发送event到flutter
- (void)player:(HatomSDKPlayer*)player eventData:(NSDictionary *)eventData;

@end


typedef void (^ResultBlock)(id result);

@interface HatomSDKPlayer : NSObject

@property(nonatomic, weak)id<HatomSDKPlayerDeleagete> delegate;

/// flutter 纹理对象
@property (nonatomic, weak) NSObject<FlutterTextureRegistry> *textures;
/// 纹理渲染器
@property (nonatomic, strong) HatomOpenGLYUV *glRender;
/// 纹理ID
@property (nonatomic, assign) NSInteger textureId;


/// 播放器设置
/// @param playConfig 配置信息
/// @param path 播放url
/// @param headers 请求头信息
- (instancetype)initPlayerWithPlayConfig:(PlayConfig*)playConfig path:(NSString *)path headers:(NSDictionary *)headers;

/// 配置播放信息
/// @param playConfig 播放参数
- (void)setPlayConfig:(PlayConfig *)playConfig;

/// 设置播放参数
/// @param path 播放url
/// @param headers 请求参数
- (void)setDataSource:(nullable NSString *)path headers:(nullable NSDictionary *)headers;

/// 开启播放
- (void)start;

/// 关闭播放
- (void)stop;

/// 声音操作
/// @param enable YES-开启  NO-关闭
- (int)enableAudio:(BOOL)enable;

// 抓图操作
- (nullable NSData *)screenshoot;

/// 切换码流
/// @param quality 码流质量
- (BOOL)changeStream:(int)quality;

/// 定位播放
/// @param seekTime 定位时间,格式为 yyyy-MM-dd'T'HH:mm:ss.SSS
- (int)seekPlayback:(NSString *)seekTime;

/// 暂停播放
- (int)pause;

/// 恢复播放
- (int)resume;

/// 获取回放倍速值
- (int)getPlaybackSpeed;

/// 设置回放倍速s
/// 倍速值-8/-4/-2/1/2/4/8，负数为慢放，正数为快放
- (int)setPlaybackSpeed:(float)speed;

/// 开始录像
/// @param mediaFilePath 录像文件路径
- (int)startRecord:(NSString *)mediaFilePath;

///开始录像同时转码(转码是指转码为系统播放器可以识别的标准 mp4封装）
///@param mediaFilePath 录像文件路径
- (int)startRecordAndConvert:(NSString *)mediaFilePath;

/// 停止录像
- (int)stopRecord;

/// 获取消耗的流量
- (long)getTotalTraffic;

/// 获取系统播放时间
- (long)getOSDTime;

/// 播放本地的录像文件
/// @param path 文件路径
- (void)playFile:(NSString *)path;

/// 获取文件总播放时长
- (int)getTotalTime;

/// 获取当前视频播放时间
- (int)getPlayedTime;

/// 设置当前进度值
/// @param scale 当前播放进度和总进度比  取值范围 0-1.0
- (int)setCurrentFrame:(float)scale;

/// 设置对讲参数
/// @param path 对讲url
/// @param headers 请求参数
- (void)setVoiceDataSource:(nullable NSString *)path headers:(nullable NSDictionary *)headers;

/// 开启对讲
- (void)startVoiceTalk;

/// 关闭对讲
- (void)stopVoiceTalk;

/// 设置多线程解码线程数（硬解不支持设置解码线程）
/// @param threadNum 线程数（1~8）
- (BOOL)setDecodeThreadNum:(int)threadNum;

/// 获取当前码流帧率
- (int)getFrameRate;

/// 设置期望帧率（硬解不支持）
/// @param frameRate 帧率范围(1~码流最大帧率)，播放成功后可以通过getFrameRate获取当前码流最大帧率
- (BOOL)setExpectedFrameRate:(int)frameRate;

/// 释放播放器
- (void)disposePlayer;

@end

NS_ASSUME_NONNULL_END
