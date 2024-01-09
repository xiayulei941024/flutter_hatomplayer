/// player需要的参数
class PlayConfig {
  /// 取流方式 0-hpsclient 1-设备直连 2-npclient
  int? fetchStreamType;

  /// 是否开启硬解码 true-开启 false-关闭
  bool? hardDecode;

  /// 是否显示智能信息 true-显示 false-不显示
  bool? privateData;

  /// 取流超时时间，默认20s
  int? timeout;

  /// 码流解密key,如果是萤石设备，就是验证码
  String? secretKey;

  /// 水印信息
  List<String>? waterConfigs;

  /// 流缓冲区大小，默认为5M   格式：5*1024*1024
  int? bufferLength;

  ///设备ip
  String? ip;

  /// 端口号
  int? port;

  /// 用户名
  String? username;

  ///密码
  String? password;

  /// 通道号
  int? channelNum;

  /// 清晰度 0-主码流 1-子码流
  int? qualityType;

  /// 萤石设备序列号
  String? deviceSerial;

  /// 设备验证码
  String? verifyCode;

  PlayConfig(
      {this.fetchStreamType,
      this.hardDecode,
      this.privateData,
      this.timeout,
      this.secretKey,
      this.waterConfigs,
      this.bufferLength,
      this.deviceSerial,
      this.verifyCode,
      this.ip,
      this.port,
      this.username,
      this.password,
      this.qualityType,
      this.channelNum});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fetchStreamType'] = fetchStreamType;
    data['hardDecode'] = hardDecode;
    data['privateData'] = privateData;
    data['timeout'] = timeout;
    data['secretKey'] = secretKey;
    data['bufferLength'] = bufferLength;
    data['channelNum'] = channelNum;
    data['deviceSerial'] = deviceSerial;
    data['verifyCode'] = verifyCode;
    data['ip'] = ip;
    data['port'] = port;
    data['username'] = username;
    data['qualityType'] = qualityType;
    data['password'] = password;
    if (waterConfigs != null) {
      data['waterConfigs'] = waterConfigs!.map((v) => v).toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'PlayConfig:{fetchStreamType: $fetchStreamType,hardDecode:$hardDecode, privateData: $privateData, timeout:$timeout, secretKey: $secretKey, waterConfigs:$waterConfigs, bufferLength:$bufferLength, qualityType:$qualityType, channelNum:$channelNum,deviceSerial:$deviceSerial,verifyCode:$verifyCode}';
  }
}
