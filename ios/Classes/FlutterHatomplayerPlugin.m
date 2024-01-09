#import "HatomSDKPlayer.h"
#import "FlutterHatomplayerPlugin.h"
#import <hatomplayer_core/DefaultHatomPlayer.h>
#import <hatomplayer_core/HatomPlayerSDK.h>
#import <hatomplayer_core/PlayConfig.h>

static NSString *TEXTTURE_ID = @"textureId";
static NSString *SET_PLAY_CONFIG = @"setPlayConfig";
static NSString *SET_DATA_SOURCE = @"setDataSource";
static NSString *START = @"start";
static NSString *STOP = @"stop";
static NSString *ENABLE_AUDIO = @"enableAudio";
static NSString *SCREEN_SHOOT = @"screenshoot";
static NSString *CHANGE_STREAM = @"changeStream";
static NSString *INIT_PLAYER = @"initPlayer";
static NSString *SEEK_PLAYBACK = @"seekPlayback";
static NSString *PAUSE = @"pause";
static NSString *RESUME = @"resume";
static NSString *GET_PLAYBACK_SPEED = @"getPlaybackSpeed";
static NSString *SET_PLAYBACK_SPEED = @"setPlaybackSpeed";
static NSString *START_RECORD = @"startRecord";
static NSString *STOP_RECORD = @"stopRecord";
static NSString *START_RECORD_AND_CONVERT = @"startRecordAndConvert";
static NSString *GET_TOTAL_TRAFFIC = @"getTotalTraffic";
static NSString *PLAY_FILE = @"playFile";
static NSString *GET_TOTAL_TIME = @"getTotalTime";
static NSString *GET_PLAYED_TIME = @"getPlayedTime";
static NSString *SET_CURRENT_FRAME = @"setCurrentFrame";
static NSString *GET_OSDTIME = @"getOSDTime";
static NSString *SET_VOICE_DATA_SOURCE = @"setVoiceDataSource";
static NSString *START_VOICE_TALK = @"startVoiceTalk";
static NSString *STOP_VOICE_TALK = @"stopVoiceTalk";
static NSString *SET_DECODE_THREAD_NUM = @"setDecodeThreadNum";
static NSString *GET_FRAME_RATE = @"getFrameRate";
static NSString *SET_EXPECTED_FRAME_RATE = @"setExpectedFrameRate";
static NSString *RELEASE = @"release";


@interface FlutterHatomplayerPlugin()
<HatomSDKPlayerDeleagete>

/// 纹理对象
@property (nonatomic, weak) NSObject<FlutterTextureRegistry> *textures;
/// registrar
@property (nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
/// 播放player
@property (nonatomic, strong) HatomSDKPlayer *sdkPlayer;
/// 纹理id
@property (nonatomic, assign)  int64_t textureId;
/// 播放player缓存
@property (nonatomic, strong) NSMutableDictionary *playerSDKDic;
/// messagechannel缓存
@property (nonatomic, strong) NSMutableDictionary *basicMessageChannelDic;

@end

@implementation FlutterHatomplayerPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_hatomplayer"
            binaryMessenger:[registrar messenger]];
  FlutterHatomplayerPlugin* instance = [[FlutterHatomplayerPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _textures = [registrar textures];
        _registrar = registrar;
        _playerSDKDic = [NSMutableDictionary new];
        _basicMessageChannelDic = [NSMutableDictionary new];
        // 初始化视频播放SDK
        [[HatomPlayerSDK alloc] init:@"" printLog:NO];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *funName = call.method;
    NSDictionary *params = call.arguments;
//    NSLog(@"=========params:%@", params);
  if ([funName isEqualToString:INIT_PLAYER]) {
      PlayConfig *config = [self conver2PlayConfig:params];
      if (config == nil) {
          result(@(-1));
          return;
      }
    
      NSString *path = [self isEmptyNull:params[@"path"]] ? @"" : params[@"path"];
      NSDictionary *headers = params[@"headers"];
      HatomSDKPlayer *playerSDK = [[HatomSDKPlayer alloc] initPlayerWithPlayConfig:config path:path headers:headers];
      playerSDK.delegate = self;
      NSInteger textureId = [self.textures registerTexture:playerSDK.glRender];
      [self initEventChannel:@(textureId)];
      playerSDK.textureId = textureId;
      [self.playerSDKDic setValue:playerSDK forKey:@(textureId).stringValue];
      result(@(textureId));
  } else if ([funName isEqualToString:START]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      [playerSDK start];
      result(0);
  }else if ([funName isEqualToString:RELEASE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      [playerSDK disposePlayer];
      result(0);
  } else if ([funName isEqualToString:STOP]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      [playerSDK stop];
      result(0);
  } else if ([funName isEqualToString:ENABLE_AUDIO]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      BOOL enable = [params[@"enable"] boolValue];
      if ([playerSDK enableAudio:enable] == 0) {
          result(@(0));
      } else {
          result(@(-1));
      }
  } else if ([funName isEqualToString:SET_PLAY_CONFIG]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      PlayConfig *config = [self conver2PlayConfig: params];
      [playerSDK setPlayConfig:config];
      result(0);
  } else if ([funName isEqualToString:SET_DATA_SOURCE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSString *path = params[@"path"];
      NSDictionary *headers = params[@"headers"];
      [playerSDK setDataSource:path headers:headers];
      result(0);
  } else if ([funName isEqualToString:SCREEN_SHOOT]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSData *data = [playerSDK screenshoot];
      if (data == nil) {
          result(nil);
      } else {
          result([FlutterStandardTypedData typedDataWithBytes:data]);
      }
  } else if ([funName isEqualToString:CHANGE_STREAM]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int qualityType = [params[@"qualityType"] intValue];
      [playerSDK changeStream:qualityType];
      result(0);
  } else if ([funName isEqualToString:SEEK_PLAYBACK]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSString *seekTime = params[@"seekTime"];
      int ret = [playerSDK seekPlayback:seekTime];
      result(@(ret));
  } else if ([funName isEqualToString:PAUSE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int ret = [playerSDK pause];
      result(@(ret));
  } else if ([funName isEqualToString:RESUME]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int ret = [playerSDK resume];
      result(@(ret));
  } else if ([funName isEqualToString:GET_PLAYBACK_SPEED]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int res = [playerSDK getPlaybackSpeed];
      result(@(res));
  } else if ([funName isEqualToString:SET_PLAYBACK_SPEED]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int speed = [params[@"speed"] intValue];
      int ret = [playerSDK setPlaybackSpeed: speed];
      result(@(ret));
  } else if ([funName isEqualToString:START_RECORD]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSString *mediaFilePath = params[@"mediaFilePath"];
      int ret = [playerSDK startRecord:mediaFilePath];
      result(@(ret));
  } else if ([funName isEqualToString:START_RECORD_AND_CONVERT]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSString *mediaFilePath = params[@"mediaFilePath"];
      int ret = [playerSDK startRecordAndConvert:mediaFilePath];
      result(@(ret));
  } else if ([funName isEqualToString:STOP_RECORD]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int ret = [playerSDK stopRecord];
      result(@(ret));
  } else if ([funName isEqualToString:GET_TOTAL_TRAFFIC]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      long res = [playerSDK getTotalTraffic];
      result(@(res));
  } else if ([funName isEqualToString:PLAY_FILE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSString *path = params[@"path"];
      [playerSDK playFile:path];
      result(@(0));
  } else if ([funName isEqualToString:GET_TOTAL_TIME]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int res = [playerSDK getTotalTime];
      result(@(res));
  } else if ([funName isEqualToString:GET_PLAYED_TIME]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int res = [playerSDK getPlayedTime];
      result(@(res));
  } else if ([funName isEqualToString:SET_CURRENT_FRAME]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      float scale = [params[@"scale"] floatValue];
      int ret = [playerSDK setCurrentFrame:scale];
      result(@(ret));
  } else if ([funName isEqualToString:GET_OSDTIME]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      long res = [playerSDK getOSDTime];
      result(@(res));
  } else if ([funName isEqualToString:SET_VOICE_DATA_SOURCE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      NSString *path = params[@"path"];
      NSDictionary *headers = params[@"headers"];
      [playerSDK setVoiceDataSource:path headers:headers];
      result(@(0));
  } else if ([funName isEqualToString:START_VOICE_TALK]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      [playerSDK startVoiceTalk];
      result(@(0));
  } else if ([funName isEqualToString:STOP_VOICE_TALK]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      [playerSDK stopVoiceTalk];
      result(@(0));
  } else if ([funName isEqualToString:SET_DECODE_THREAD_NUM]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int num = [params[@"threadNum"] intValue];
      int ret = [playerSDK setDecodeThreadNum:num];
      result(@(ret));
  } else if ([funName isEqualToString:GET_FRAME_RATE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int res = [playerSDK getFrameRate];
      result(@(res));
  } else if ([funName isEqualToString:SET_EXPECTED_FRAME_RATE]) {
      HatomSDKPlayer *playerSDK = [self getSdkPlayer:[params objectForKey:TEXTTURE_ID]];
      int rate = [params[@"frameRate"] intValue];
      int ret = [playerSDK setExpectedFrameRate:rate];
      result(@(ret));
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

// 初始化channel
- (void)initEventChannel:(NSNumber *)textureId {
    NSString *eventChannelName = [NSString stringWithFormat:@"flutter_hatomplayer:player@%@",textureId];
    FlutterBasicMessageChannel *eventChannel = [FlutterBasicMessageChannel messageChannelWithName:eventChannelName binaryMessenger:[self.registrar messenger]];
    [self.basicMessageChannelDic setValue:eventChannel forKey:textureId.stringValue];
}


// 获取对应播放对象
- (HatomSDKPlayer *)getSdkPlayer:(NSNumber *)textureId {
    if ([textureId isKindOfClass:[NSNull class]]) {
        return nil;
    }
    return [self.playerSDKDic objectForKey:textureId.stringValue];
}

/// map转PlayConfig
- (PlayConfig *)conver2PlayConfig:(NSDictionary *)params {
    if ([params isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ([self isEmptyNull:params[@"config"]]) {
        return nil;
    }
    NSDictionary *configDict = params[@"config"];
    PlayConfig *config = [[PlayConfig alloc] init];
    if (![self isEmptyNull:configDict[@"fetchStreamType"]]) {
        config.fetchStreamType = [configDict[@"fetchStreamType"] intValue];
    }
    if (![self isEmptyNull:configDict[@"hardDecode"]]) {
        config.hardDecode = [configDict[@"hardDecode"] boolValue];
    } else {
        config.hardDecode = YES;
    }
    if (![self isEmptyNull:configDict[@"privateData"]]) {
        config.privateData = [configDict[@"privateData"] boolValue];
    } else {
        config.privateData = NO;
    }
    if (![self isEmptyNull:configDict[@"timeout"]]) {
        config.timeout = [configDict[@"timeout"] intValue];
    }
    if (![self isEmptyNull:configDict[@"secretKey"]]) {
        config.secretKey = configDict[@"secretKey"];
    }
    if (![self isEmptyNull:configDict[@"waterConfigs"]]) {
        config.waterConfigs = configDict[@"waterConfigs"];
    }
    if (![self isEmptyNull:configDict[@"bufferLength"]]) {
        config.bufferLength = [configDict[@"bufferLength"] intValue];
    }
    if (![self isEmptyNull:configDict[@"username"]]) {
        config.username = configDict[@"username"];
    }
    if (![self isEmptyNull:configDict[@"password"]]) {
        config.password = configDict[@"password"];
    }
    if (![self isEmptyNull:configDict[@"ip"]]) {
        config.ip = configDict[@"ip"];
    }
    if (![self isEmptyNull:configDict[@"port"]]) {
        config.port = [configDict[@"port"]intValue];
    }
    if (![self isEmptyNull:configDict[@"channelNum"]]) {
        config.channelNum = [configDict[@"channelNum"] intValue];
    }
    if (![self isEmptyNull:configDict[@"qualityType"]]) {
        config.qualityType = [configDict[@"qualityType"] intValue];
    }
    if (![self isEmptyNull:configDict[@"channelNum"]]) {
        config.channelNum = [configDict[@"channelNum"] intValue];
    }
    if (![self isEmptyNull:configDict[@"deviceSerial"]]) {
        config.deviceSerial = configDict[@"deviceSerial"];
    }
    if (![self isEmptyNull:configDict[@"secretKey"]]) {
        config.secretKey = configDict[@"secretKey"];
    }
    return config;
}

#pragma mark - HatomSDKPlayerDeleagete
- (void)frameUpdate:(NSInteger)textureId {
    [self.textures textureFrameAvailable:textureId];
}

// native 发送event到flutter
- (void)player:(HatomSDKPlayer*)player eventData:(NSDictionary *)eventData {
    NSLog(@"====eventData:%@", eventData);
    NSString *key = [NSString stringWithFormat:@"%ld", (long)player.textureId];;
    FlutterBasicMessageChannel *channel = self.basicMessageChannelDic[key];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (channel) {
            [channel sendMessage:eventData];
        }
    });
}

- (BOOL)isEmptyNull:(id)param {
    if (param == nil || [param isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return NO;
}

@end
