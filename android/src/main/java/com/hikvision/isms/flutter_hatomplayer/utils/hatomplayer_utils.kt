package com.hikvision.isms.flutter_hatomplayer.utils

import android.util.Log
import com.hikvision.hatomplayer.PlayConfig
import io.flutter.plugin.common.MethodCall

/**
 * 描述：通道数据转化类
 */

fun logDebug(message: Any) {
    Log.d("flutter_hatomplayer", message.toString())
}


fun convert2PlayConfig(config: Map<String, Any>?): PlayConfig? {
    if (config == null) {
        return null
    }
    val playConfig = PlayConfig()
    val fetchStreamType = config["fetchStreamType"]
    if (fetchStreamType != null) {
        playConfig.fetchStreamType = fetchStreamType as Int
    }
    val hardDecode = config["hardDecode"]
    if (hardDecode != null) {
        playConfig.hardDecode = hardDecode as Boolean
    }
    val privateData = config["privateData"]
    if (privateData != null) {
        playConfig.privateData = privateData as Boolean
    }
    val timeout = config["timeout"]
    if (timeout != null) {
        playConfig.timeout = timeout as Int
    }
    val secretKey = config["secretKey"]
    if (secretKey != null) {
        playConfig.secretKey = secretKey as String?
    }
    val bufferLength = config["bufferLength"]
    if (bufferLength != null) {
        playConfig.playBuffer = bufferLength as Int
    }

    val ip = config["ip"]
    if (ip != null) {
        playConfig.ip = ip as String?
    }

    val port = config["port"]
    if (port != null) {
        playConfig.port = port as Int
    }

    val username = config["username"]
    if (username != null) {
        playConfig.username = username as String?
    }

    val password = config["password"]
    if (password != null) {
        playConfig.password = password as String?
    }

    val qualityType = config["qualityType"]
    if (qualityType != null) {
        playConfig.qualityType = qualityType as Int
    }

    val channelNum = config["channelNum"]
    if (channelNum != null) {
        playConfig.channelNum = channelNum as Int
    }
    val deviceSerial = config["deviceSerial"]
    if (deviceSerial != null) {
        playConfig.deviceSerial = deviceSerial as String?
    }
    val verifyCode = config["verifyCode"]
    if (verifyCode != null) {
        playConfig.verifyCode = verifyCode as String?
    }

    return playConfig
}

fun <T> MethodCall.requireArg(key: String): T {
    if (hasArgument(key)) {
        try {
            return argument(key) ?: throw MethodCallArgumentException("no value for key $key")
        } catch (e: Exception) {
            ///可能强转失败
            e.printStackTrace()
            throw MethodCallArgumentException("no value for key $key", e)
        }
    }
    throw MethodCallArgumentException("no value for key $key")
}


class MethodCallArgumentException(message: String?, cause: Throwable? = null) :
    Exception(message, cause)