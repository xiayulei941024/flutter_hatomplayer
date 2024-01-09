package com.hikvision.isms.flutter_hatomplayer.utils;

public class ReflectUtils {
    public static Object reflectClass(String className) {
        try {
            Class<?> cl = Class.forName(className);
            return cl.newInstance();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
