package com.hikvision.isms.flutter_hatomplayer

import android.os.Handler
import android.os.Looper
import android.util.LongSparseArray
import androidx.annotation.NonNull
import com.hikvision.hatomplayer.DefaultHatomPlayer
import com.hikvision.hatomplayer.PlayCallback
import com.hikvision.hatomplayer.PlayConfig
import com.hikvision.hatomplayer.core.PlaybackSpeed
import com.hikvision.hatomplayer.core.Quality
import com.hikvision.hatomplayer.stream.StreamClient
import com.hikvision.isms.flutter_hatomplayer.utils.*
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import org.json.JSONObject
import java.lang.Exception
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors.newCachedThreadPool

/** HatomPlayerMethodCallHandlerImpl */
class HatomPlayerMethodCallHandlerImpl(
    private val textureRegistry: TextureRegistry,
    private val binaryMessenger: BinaryMessenger
) : MethodCallHandler {

    private var executor: ExecutorService = newCachedThreadPool()
    private var handler: Handler = Handler(Looper.getMainLooper())

    private val players = LongSparseArray<DefaultHatomPlayer>()

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        logDebug("method: " + call.method + ",arguments: " + call.arguments)
        when (call.method) {
            FlutterPlayerConstants.INIT_PLAYER -> {
                initPlayer(call, result)
            }
            FlutterPlayerConstants.SET_PLAY_CONFIG -> {
                try {
                    val config = call.requireArg<Map<String, Any>>("config")
                    val playConfig: PlayConfig? = convert2PlayConfig(config)
                    if (playConfig != null) {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.setPlayConfig(playConfig)
                        result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                    } else {
                        result.success(FlutterPlayerConstants.RESULT_FAIL)
                    }
                } catch (e: Exception) {
                    result.success(FlutterPlayerConstants.RESULT_FAIL)
                }
            }
            FlutterPlayerConstants.SET_DATA_SOURCE -> {
                try {
                    val headers = call.requireArg<Map<String, String>>("headers")
                    val urlPath: String = call.requireArg("path")
                    if (urlPath.isNotEmpty()) {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.setDataSource(urlPath, headers)
                        result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                    } else {
                        result.success(FlutterPlayerConstants.RESULT_FAIL)
                    }
                } catch (e: Exception) {
                    result.success(FlutterPlayerConstants.RESULT_FAIL)
                }
            }
            FlutterPlayerConstants.SET_VOICE_DATA_SOURCE -> {
                try {
                    val headers = call.requireArg<Map<String, String>>("headers")
                    val urlPath: String = call.requireArg("path")
                    if (urlPath.isNotEmpty()) {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.setVoiceDataSource(urlPath, headers)
                        result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                    } else {
                        result.success(FlutterPlayerConstants.RESULT_FAIL)
                    }
                } catch (e: Exception) {
                    result.success(FlutterPlayerConstants.RESULT_FAIL)
                }
            }
            FlutterPlayerConstants.START -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.start()
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.STOP -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.stop()
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.START_VOICE_TALK -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.startVoiceTalk()
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.STOP_VOICE_TALK -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.stopVoiceTalk()
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.SCREEN_SHOOT -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val screenshotJPEGData = players[textureId]?.screenshot()
                        if (screenshotJPEGData != null) {
                            handler.post {
                                result.success(screenshotJPEGData.mJpegBuffer)
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.ENABLE_AUDIO -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val enable = call.requireArg<Boolean>("enable")
                        val enableAudio = players[textureId]?.enableAudio(enable)
                        handler.post {
                            result.success(enableAudio)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.CHANGE_STREAM -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val qualityType = call.requireArg<Int>("qualityType")
                        var quality = Quality.SUB_STREAM_STANDARD
                        when (qualityType) {
                            Quality.MAIN_STREAM_HIGH.stream -> {
                                quality = Quality.MAIN_STREAM_HIGH
                            }
                            Quality.SUB_STREAM_STANDARD.stream -> {
                                quality = Quality.SUB_STREAM_STANDARD
                            }
                            Quality.SUB_STREAM_LOW.stream -> {
                                quality = Quality.SUB_STREAM_LOW
                            }
                            Quality.STREAM_SUPER_CLEAR.stream -> {
                                quality = Quality.STREAM_SUPER_CLEAR
                            }
                        }
                        val changeStream = players[textureId]?.changeStream(quality)
                        handler.post {
                            result.success(changeStream)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.SEEK_PLAYBACK -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val seekTime = call.requireArg<String>("seekTime")
                        players[textureId]?.seekPlayback(seekTime)
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.PAUSE -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.pause()
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.RESUME -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.resume()
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.GET_PLAYBACK_SPEED -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val playbackSpeed = players[textureId]?.playbackSpeed
                        if (playbackSpeed != null) {
                            handler.post {
                                result.success(playbackSpeed.value)
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }

                }
            }
            FlutterPlayerConstants.SET_PLAYBACK_SPEED -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val speed = call.requireArg<Float>("speed")
                        var playbackSpeed = PlaybackSpeed.NORMAL
                        when (speed) {
                            PlaybackSpeed.NORMAL.value -> {
                                playbackSpeed = PlaybackSpeed.NORMAL
                            }
                            PlaybackSpeed.DOUBLE.value -> {
                                playbackSpeed = PlaybackSpeed.DOUBLE
                            }
                            PlaybackSpeed.FOUR.value -> {
                                playbackSpeed = PlaybackSpeed.FOUR
                            }
                            PlaybackSpeed.EIGHT.value -> {
                                playbackSpeed = PlaybackSpeed.EIGHT
                            }
                            PlaybackSpeed.SIXTEEN.value -> {
                                playbackSpeed = PlaybackSpeed.SIXTEEN
                            }
                            PlaybackSpeed.THIRTY_TWO.value -> {
                                playbackSpeed = PlaybackSpeed.THIRTY_TWO
                            }
                            PlaybackSpeed.HALF.value -> {
                                playbackSpeed = PlaybackSpeed.HALF
                            }
                            PlaybackSpeed.QUARTER.value -> {
                                playbackSpeed = PlaybackSpeed.QUARTER
                            }
                            PlaybackSpeed.ONE_EIGHTH.value -> {
                                playbackSpeed = PlaybackSpeed.ONE_EIGHTH
                            }
                        }
                        players[textureId]?.playbackSpeed = playbackSpeed
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.START_RECORD -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val mediaFilePath = call.requireArg<String>("mediaFilePath")
                        val startRecord = players[textureId]?.startRecord(mediaFilePath)
                        handler.post {
                            result.success(startRecord)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.START_RECORD_AND_CONVERT -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val mediaFilePath = call.requireArg<String>("mediaFilePath")
                        val startRecordAndConvert =
                            players[textureId]?.startRecordAndConvert(mediaFilePath)
                        handler.post {
                            result.success(startRecordAndConvert)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.STOP_RECORD -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val stopRecord = players[textureId]?.stopRecord()
                        handler.post {
                            result.success(stopRecord)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }

                }
            }
            FlutterPlayerConstants.GET_TOTAL_TRAFFIC -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val totalTraffic = players[textureId]?.totalTraffic
                        if (totalTraffic != null) {
                            handler.post {
                                result.success(totalTraffic)
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.PLAY_FILE -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val path = call.requireArg<String>("path")
                        players[textureId]?.playFile(path)
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.GET_TOTAL_TIME -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val totalTime = players[textureId]?.totalTime
                        if (totalTime != null) {
                            handler.post {
                                result.success(totalTime)
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }

                }
            }
            FlutterPlayerConstants.GET_PLAYED_TIME -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val playedTime = players[textureId]?.playedTime
                        if (playedTime != null) {
                            handler.post {
                                result.success(playedTime)
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }

                }
            }
            FlutterPlayerConstants.GET_OSDTIME -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val osdTime = players[textureId]?.osdTime
                        if (osdTime != null) {
                            handler.post {
                                result.success((osdTime / 1000).toInt())
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }

                }
            }
            FlutterPlayerConstants.SET_CURRENT_FRAME -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val scale = call.requireArg<Float>("scale")
                        val currentFrame = players[textureId]?.setCurrentFrame(scale.toDouble())
                        handler.post {
                            result.success(currentFrame)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.SET_DECODE_THREAD_NUM -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val threadNum = call.requireArg<Int>("threadNum")
                        val decodeThreadNum = players[textureId]?.setDecodeThreadNum(threadNum)
                        handler.post {
                            result.success(decodeThreadNum)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }

                }
            }
            FlutterPlayerConstants.GET_FRAME_RATE -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val frameRate = players[textureId]?.frameRate
                        if (frameRate != null) {
                            handler.post {
                                result.success(frameRate)
                            }
                        } else {
                            handler.post {
                                result.success(FlutterPlayerConstants.RESULT_FAIL)
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.SET_EXPECTED_FRAME_RATE -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        val frameRate = call.requireArg<Int>("frameRate")
                        val expectedFrameRate =
                            players[textureId]?.setExpectedFrameRate(frameRate.toFloat())
                        handler.post {
                            result.success(expectedFrameRate)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            FlutterPlayerConstants.RELEASE -> {
                executor.execute {
                    try {
                        val textureId = call.requireArg<Int>("textureId").toLong()
                        players[textureId]?.stop()
                        players.remove(textureId)
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_SUCCESS)
                        }
                    } catch (e: Exception) {
                        handler.post {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                        }
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * 初始化播放器
     */
    private fun initPlayer(call: MethodCall, result: Result) {
        try {
            val config = call.requireArg<Map<String, Any>>("config")
            val headers = call.requireArg<Map<String, String>>("headers")
            val urlPath: String = call.requireArg("path")
            val playConfig: PlayConfig? = convert2PlayConfig(config)
            val surfaceTextureEntry = textureRegistry.createSurfaceTexture()
            val messageChannel =
                BasicMessageChannel(
                    binaryMessenger,
                    "flutter_hatomplayer:player@${surfaceTextureEntry.id()}",
                    StandardMessageCodec.INSTANCE
                )
            if (playConfig != null && urlPath.isNotEmpty()) {
                val hatomPlayer = when (playConfig.fetchStreamType) {
                    0 -> {
                        DefaultHatomPlayer()
                    }
                    1 -> {
                        val reflectClass =
                            ReflectUtils.reflectClass("com.hikvision.stream.hcnet.HcNetStreamClient")
                        if (reflectClass != null) {
                            DefaultHatomPlayer(reflectClass as StreamClient)
                        } else {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                            return
                        }
                    }
                    else -> {
                        val reflectClass =
                            ReflectUtils.reflectClass("com.hikvision.stream.np.NpStreamClient")
                        if (reflectClass != null) {
                            DefaultHatomPlayer(reflectClass as StreamClient)
                        } else {
                            result.success(FlutterPlayerConstants.RESULT_FAIL)
                            return
                        }
                    }
                }
                val surfaceTexture = surfaceTextureEntry.surfaceTexture()
                hatomPlayer.setSurfaceTexture(surfaceTexture)
                hatomPlayer.setPlayConfig(playConfig)
                hatomPlayer.setDataSource(urlPath, headers)
                hatomPlayer.setVoiceStatusCallback { status, errorCode ->
                    when (status) {
                        PlayCallback.Status.SUCCESS -> {
                            handler.post {
                                messageChannel.send(mapOf("event" to "onTalkSuccess"))
                            }
                        }
                        PlayCallback.Status.FAILED -> {
                            handler.post {
                                messageChannel.send(
                                    mapOf(
                                        "event" to "onTalkError",
                                        "error" to errorCode
                                    )
                                )
                            }
                        }
                        PlayCallback.Status.EXCEPTION -> {
                            handler.post {
                                messageChannel.send(
                                    mapOf(
                                        "event" to "onTalkError",
                                        "body" to errorCode
                                    )
                                )
                            }
                        }
                        PlayCallback.Status.FINISH -> {
                        }
                    }
                }
                hatomPlayer.setPlayStatusCallback { status, errorCode ->
                    when (status) {
                        PlayCallback.Status.SUCCESS -> {
                            try {
                                val jsonObject = JSONObject(errorCode)
                                if (jsonObject.has("displayWidth") && jsonObject.has("displayHeight")) {
                                    surfaceTexture.setDefaultBufferSize(
                                        jsonObject.getInt("displayWidth"),
                                        jsonObject.getInt("displayHeight")
                                    )
                                }
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                            handler.post {
                                messageChannel.send(mapOf("event" to "onPlaySuccess"))
                            }
                        }
                        PlayCallback.Status.FAILED -> {
                            handler.post {
                                messageChannel.send(
                                    mapOf(
                                        "event" to "onPlayError",
                                        "error" to errorCode
                                    )
                                )
                            }
                        }
                        PlayCallback.Status.EXCEPTION -> {
                            handler.post {
                                messageChannel.send(
                                    mapOf(
                                        "event" to "onUnknown",
                                        "body" to errorCode
                                    )
                                )
                            }
                        }
                        PlayCallback.Status.FINISH -> {
                            handler.post {
                                messageChannel.send(mapOf("event" to "onPlayFinish"))
                            }
                        }
                    }

                }
                players.put(surfaceTextureEntry.id(), hatomPlayer)
                //先连接EventChannel，EventChannel连接成功后开始播放并
                result.success(surfaceTextureEntry.id())
            } else {
                result.success(FlutterPlayerConstants.RESULT_FAIL)
            }
        } catch (e: Exception) {
            result.success(FlutterPlayerConstants.RESULT_FAIL)
        }
    }

    fun teardown() {
        handler.removeCallbacksAndMessages(null)
        executor.shutdown()
    }

}
