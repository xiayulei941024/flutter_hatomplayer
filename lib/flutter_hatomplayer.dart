import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hatomplayer/play_config.dart';

import 'hatom_player_event.dart';

typedef PlayStateCallBack = void Function(HatomPlayerEvent event);

class FlutterHatomplayer {
  static const MethodChannel _channel = MethodChannel('flutter_hatomplayer');
  static const String SET_PLAY_CONFIG = 'setPlayConfig';
  static const String SET_DATA_SOURCE = 'setDataSource';
  static const String START = 'start';
  static const String STOP = 'stop';
  static const String ENABLE_AUDIO = 'enableAudio';
  static const String SCREEN_SHOOT = 'screenshoot';
  static const String CHANGE_STREAM = 'changeStream';
  static const String INIT_PLAYER = 'initPlayer';
  static const String SEEK_PLAYBACK = 'seekPlayback';
  static const String PAUSE = 'pause';
  static const String RESUME = 'resume';
  static const String GET_PLAYBACK_SPEED = 'getPlaybackSpeed';
  static const String SET_PLAYBACK_SPEED = 'setPlaybackSpeed';
  static const String START_RECORD = 'startRecord';
  static const String STOP_RECORD = 'stopRecord';
  static const String START_RECORD_AND_CONVERT = 'startRecordAndConvert';
  static const String GET_TOTAL_TRAFFIC = 'getTotalTraffic';
  static const String PLAY_FILE = 'playFile';
  static const String GET_TOTAL_TIME = 'getTotalTime';
  static const String GET_PLAYED_TIME = 'getPlayedTime';
  static const String SET_CURRENT_FRAME = 'setCurrentFrame';
  static const String GET_OSDTIME = 'getOSDTime';
  static const String SET_VOICE_DATA_SOURCE = 'setVoiceDataSource';
  static const String START_VOICE_TALK = 'startVoiceTalk';
  static const String STOP_VOICE_TALK = 'stopVoiceTalk';
  static const String SET_DECODE_THREAD_NUM = 'setDecodeThreadNum';
  static const String GET_FRAME_RATE = 'getFrameRate';
  static const String SET_EXPECTED_FRAME_RATE = 'setExpectedFrameRate';
  static const String RELEASE = 'release';

  /// 播放前配置
  PlayConfig? playConfig;
  String? urlPath;
  Map<String, dynamic>? headers;
  PlayStateCallBack playEventCallBack;

  /// 初始化构造
  FlutterHatomplayer(
      {this.playConfig,
      this.urlPath,
      this.headers,
      required this.playEventCallBack});

  /// 播放器textureId
  int? textureId;

  ///===============================public=================================

  ///创建纹理、EventChannel，这个方法只会执行一次
  ///必须等这个异步方法执行完成才能执行后面的方法，不然可能会导致回调问题
  Future<bool> initialize() async {
    // 初始化player
    Map<String, dynamic> arguments = {
      'config': playConfig?.toJson(),
      'path': urlPath,
      'headers': headers
    };
    textureId = await _channel.invokeMethod(INIT_PLAYER, arguments);
    if (textureId != -1) {
      var messageChannel = BasicMessageChannel(
          'flutter_hatomplayer:player@$textureId', StandardMessageCodec());
      messageChannel.setMessageHandler((message) async {
        debugPrint('on event: $message');
        var mapData = message as Map;
        var event = mapData['event'];
        playEventCallBack(
            HatomPlayerEvent(event, body: _convertEventBody(event, mapData)));
      });
      return true;
    } else {
      return false;
    }
  }

  /// 设置数据源
  /// [url]播放路径
  /// [headers]携带的参数
  Future<int?> setDataSource(String urlPath,
      {Map<String, dynamic>? headers}) async {
    this.urlPath = urlPath;
    this.headers = headers;
    Map<String, dynamic> arguments = {'path': urlPath, 'headers': headers};
    return await _sendCmd(SET_DATA_SOURCE, arguments);
  }

  /// 设置播放参数
  /// [playConfig] 播放参数
  Future<int?> setPlayConfig(PlayConfig playConfig) async {
    this.playConfig = playConfig;
    Map<String, dynamic> arguments = {'config': playConfig.toJson()};
    return await _sendCmd(SET_PLAY_CONFIG, arguments);
  }

  /// 开始播放
  Future<int?> start() async {
    return await _sendCmd(START);
  }

  /// 停止播放
  Future<int?> stop() async {
    return await _sendCmd(STOP);
  }

  /// 声音操作
  /// [enable] true-开启 false-关闭
  Future<int?> enableAudio(bool enable) async {
    return await _sendCmd(ENABLE_AUDIO, {'enable': enable});
  }

  /// 抓图操作
  /// [enable] true-开启 false-关闭
  Future<Uint8List?> screenshoot() async {
    return await _sendCmd(SCREEN_SHOOT);
  }

  /// 修改码流清晰度
  /// [qualityType] 清晰度 0-主码流 1-子码流
  Future<int?> changeStream(int qualityType) async {
    return await _sendCmd(CHANGE_STREAM, {'qualityType': qualityType});
  }

  /// 回放定位播放
  /// [seekTime] 定位播放的时间，格式为 yyyy-MM-dd'T'HH:mm:ss.SSS
  Future<int?> seekPlayback(String seekTime) async {
    return await _sendCmd(SEEK_PLAYBACK, {'seekTime': seekTime});
  }

  /// 暂停播放
  Future<int?> pause() async {
    return await _sendCmd(PAUSE);
  }

  /// 恢复播放
  Future<int?> resume() async {
    return await _sendCmd(RESUME);
  }

  /// 获取回放倍速值
  Future<int?> getPlaybackSpeed() async {
    return await _sendCmd(GET_PLAYBACK_SPEED);
  }

  /// 设置回放倍速
  /// [speed] 倍速值-8/-4/-2/1/2/4/8，负数为慢放，正数为快放
  Future<int?> setPlaybackSpeed(int speed) async {
    return await _sendCmd(SET_PLAYBACK_SPEED, {'speed': speed});
  }

  /// 开启录像
  /// [mediaFilePath]录像的存储路径
  Future<int?> startRecord(String mediaFilePath) async {
    return await _sendCmd(START_RECORD, {'mediaFilePath': mediaFilePath});
  }

  /// 开始录像同时转码(转码是指转码为系统播放器可以识别的标准 mp4封装）
  /// [mediaFilePath]录像的存储路径
  Future<int?> startRecordAndConvert(String mediaFilePath) async {
    return await _sendCmd(
        START_RECORD_AND_CONVERT, {'mediaFilePath': mediaFilePath});
  }

  /// 停止录像
  Future<int?> stopRecord() async {
    return await _sendCmd(STOP_RECORD);
  }

  /// 获取消耗的流量
  Future<int?> getTotalTraffic() async {
    return await _sendCmd(GET_TOTAL_TRAFFIC);
  }

  /// 播放本地的录像文件
  /// [path] 文件路径
  Future<int?> playFile(String path) async {
    return await _sendCmd(PLAY_FILE, {'path': path});
  }

  /// 获取文件总播放时长
  Future<int?> getTotalTime() async {
    return await _sendCmd(GET_TOTAL_TIME);
  }

  /// 获取当前视频播放时间
  Future<int?> getPlayedTime() async {
    return await _sendCmd(GET_PLAYED_TIME);
  }

  /// 设置当前播放进度值
  /// [scale] 当前播放进度和总进度比  取值范围 0-1.0
  Future<int?> setCurrentFrame(double scale) async {
    return await _sendCmd(SET_CURRENT_FRAME, {'scale': scale});
  }

  /// 获取系统播放时间
  Future<int?> getOSDTime() async {
    return await _sendCmd(GET_OSDTIME);
  }

  /// 设置对讲参数
  /// [path] 对讲url
  /// [headers] 请求参数
  Future<int?> setVoiceDataSource(String? path,
      {Map<String, dynamic>? headers}) async {
    Map<String, dynamic> arguments = {'path': path, 'headers': headers};
    return await _sendCmd(SET_VOICE_DATA_SOURCE, arguments);
  }

  /// 开启对讲
  Future<int?> startVoiceTalk() async {
    return await _sendCmd(START_VOICE_TALK);
  }

  /// 关闭对讲
  Future<int?> stopVoiceTalk() async {
    return await _sendCmd(STOP_VOICE_TALK);
  }

  /// 设置多线程解码线程数（硬解不支持设置解码线程）
  /// [threadNum]线程数（1~8）
  Future<int?> setDecodeThreadNum(int threadNum) async {
    return await _sendCmd(SET_DECODE_THREAD_NUM, {'threadNum': threadNum});
  }

  /// 获取当前码流帧率
  Future<int?> getFrameRate() async {
    return await _sendCmd(GET_FRAME_RATE);
  }

  /// 设置期望帧率（硬解不支持）
  /// [frameRate] 帧率范围(1~码流最大帧率)，播放成功后可以通过getFrameRate获取当前码流最大帧率
  Future<int?> setExpectedFrameRate(int frameRate) async {
    return await _sendCmd(SET_EXPECTED_FRAME_RATE, {'frameRate': frameRate});
  }

  /// 释放player
  Future<dynamic> release() async {
    return await _sendCmd(RELEASE);
  }

  ///===============================private=================================

  ///解析序列化数据
  dynamic _convertEventBody(String event, dynamic message) {
    if (event == EVENT_PLAY_ERROR) {
      return message['error'];
    } else if (event == EVENT_PLAY_FINISH) {
      return message;
    } else if (event == EVENT_TALK_ERROR) {
      return message['error'];
    } else if (event == EVENT_TALK_SUCCESS) {
      return message;
    } else {
      return message['body'];
    }
  }

  /// 发送命令的基本方法
  Future<dynamic> _sendCmd(String cmd, [Map<String, dynamic>? argument]) {
    if (textureId == null) {
      debugPrint('warning: you are calling {method: $cmd} without initialized');
      return Future.value();
    }
    if (argument == null) {
      argument = Map();
    }
    argument['textureId'] = textureId;
    return _channel.invokeMethod(cmd, argument);
  }
}
