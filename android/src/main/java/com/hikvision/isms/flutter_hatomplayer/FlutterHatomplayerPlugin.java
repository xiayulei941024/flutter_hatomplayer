package com.hikvision.isms.flutter_hatomplayer;

import android.app.Application;
import android.content.Context;

import androidx.annotation.NonNull;

import com.hikvision.hatomplayer.HatomPlayerSDK;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class FlutterHatomplayerPlugin implements FlutterPlugin {

    private static final String CHANNEL_NAME = "flutter_hatomplayer";
    private MethodChannel channel;
    private HatomPlayerMethodCallHandlerImpl handler;

    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        final FlutterHatomplayerPlugin plugin = new FlutterHatomplayerPlugin();
        plugin.setupChannel(registrar.messenger(), registrar.context(), registrar.textures());
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        setupChannel(binding.getBinaryMessenger(), binding.getApplicationContext(), binding.getTextureRegistry());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        teardownChannel();
    }

    private void setupChannel(BinaryMessenger messenger, Context context, TextureRegistry textureRegistry) {
        HatomPlayerSDK.init((Application) context, "", false);
        channel = new MethodChannel(messenger, CHANNEL_NAME);
        handler = new HatomPlayerMethodCallHandlerImpl(textureRegistry, messenger);
        channel.setMethodCallHandler(handler);
    }

    private void teardownChannel() {
        handler.teardown();
        handler = null;
        channel.setMethodCallHandler(null);
        channel = null;
    }
}
