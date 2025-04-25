import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 延迟设置方法通道，确保Flutter引擎已完全初始化
    DispatchQueue.main.async { [weak self] in
      self?.setupMethodChannel()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    methodChannel = FlutterMethodChannel(name: "com.example.lovegame/channel", 
                                        binaryMessenger: controller.binaryMessenger)
    
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      switch call.method {
      case "getSomeData":
        self.getSomeData(result: result)
      case "performAction":
        if let args = call.arguments as? [String: Any] {
          self.performAction(args: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are invalid", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func getSomeData(result: @escaping FlutterResult) {
    // 模拟异步操作
    DispatchQueue.global().async {
      // 模拟一些数据
      let data = ["key": "value", "status": "success"]
      
      // 返回到主线程
      DispatchQueue.main.async {
        result(data)
      }
    }
  }
  
  private func performAction(args: [String: Any], result: @escaping FlutterResult) {
    // 模拟异步操作
    DispatchQueue.global().async {
      // 处理参数
      if let actionType = args["type"] as? String {
        // 成功情况
        DispatchQueue.main.async {
          result(["success": true, "action": actionType])
        }
      } else {
        // 失败情况 - 正确的错误处理方式
        DispatchQueue.main.async {
          let error = FlutterError(code: "INVALID_TYPE", 
                                  message: "Action type is missing or invalid", 
                                  details: nil)
          result(error)
        }
      }
    }
  }
}
