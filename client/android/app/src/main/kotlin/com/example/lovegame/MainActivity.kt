package com.example.lovegame

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.lovegame/channel"
    private val mainHandler = Handler(Looper.getMainLooper())
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 延迟设置方法通道，避免在Flutter未准备好时发送消息
        mainHandler.post {
            setupMethodChannel(flutterEngine)
        }
    }
    
    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSomeData" -> {
                    getSomeData(result)
                }
                "performAction" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args != null) {
                        performAction(args, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Arguments are invalid", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun getSomeData(result: MethodChannel.Result) {
        // 模拟异步操作
        Thread {
            // 模拟数据
            val data = HashMap<String, Any>()
            data["key"] = "value"
            data["status"] = "success"
            
            // 返回到主线程
            mainHandler.post {
                result.success(data)
            }
        }.start()
    }
    
    private fun performAction(args: Map<String, Any>, result: MethodChannel.Result) {
        // 模拟异步操作
        Thread {
            val actionType = args["type"] as? String
            
            if (actionType != null) {
                // 成功情况
                val responseData = HashMap<String, Any>()
                responseData["success"] = true
                responseData["action"] = actionType
                
                mainHandler.post {
                    result.success(responseData)
                }
            } else {
                // 错误情况 - 正确的错误处理方式
                mainHandler.post {
                    result.error(
                        "INVALID_TYPE",
                        "Action type is missing or invalid",
                        null
                    )
                }
            }
        }.start()
    }
} 