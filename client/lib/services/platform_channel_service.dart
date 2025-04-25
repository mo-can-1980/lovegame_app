import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _channel =
      MethodChannel('com.example.lovegame/channel');

  // 日志辅助函数
  static void _logInfo(String message) {
    if (kDebugMode) {
      print('[PlatformChannel] INFO: $message');
    }
  }

  static void _logWarning(String message) {
    if (kDebugMode) {
      print('[PlatformChannel] WARNING: $message');
    }
  }

  static void _logError(String message) {
    if (kDebugMode) {
      print('[PlatformChannel] ERROR: $message');
    }
  }

  // 修复后的通用方法调用函数
  static Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      _logInfo('Invoking method: $method');
      final result = await _channel.invokeMethod<T>(method, arguments);
      _logInfo('Method $method completed successfully');
      return result;
    } catch (error) {
      _logError('Error invoking method $method: $error');
      // 在这里重新抛出错误，而不是返回null，确保错误被正确处理
      rethrow;
    }
  }

  // 处理Promise风格的调用
  static Future<T?> invokePromiseMethod<T>(String method, [dynamic arguments]) {
    final Completer<T?> completer = Completer<T?>();

    invokeMethod<T>(method, arguments).then((result) {
      completer.complete(result);
    }).catchError((error) {
      // 正确处理错误 - 传递错误信息给reject回调
      _logWarning('Rejecting promise with error: $error');
      completer.completeError(error);
    });

    return completer.future;
  }
}
