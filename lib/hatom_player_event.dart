class HatomPlayerEvent {
  final String event;
  final dynamic body;

  HatomPlayerEvent(this.event, {this.body});
}

/// 预览/回放 失败
const EVENT_PLAY_ERROR = 'onPlayError';

/// 预览/回放 成功
const EVENT_PLAY_SUCCESS = 'onPlaySuccess';

/// 对讲开启成功
const EVENT_TALK_SUCCESS = 'onTalkSuccess';

/// 对讲开启失败
const EVENT_TALK_ERROR = 'onTalkError';

/// 回放结束
const EVENT_PLAY_FINISH = 'onPlayFinish';

///未知的事件，没有处理的平台事件
const EVENT_UNKNOWN = 'onUnknown';
