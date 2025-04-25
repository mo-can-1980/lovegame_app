import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ErrorHandler {
    static void handleError(dynamic error, BuildContext context) {
        String errorMessage = 'An unexpected error occurred';
        
        if (error is DioException) {
            switch (error.type) {
                case DioExceptionType.connectionTimeout:
                case DioExceptionType.sendTimeout:
                case DioExceptionType.receiveTimeout:
                    errorMessage = 'Connection timeout. Please check your internet connection';
                    break;
                case DioExceptionType.badResponse:
                    errorMessage = _handleResponseError(error.response?.statusCode);
                    break;
                case DioExceptionType.cancel:
                    errorMessage = 'Request was cancelled';
                    break;
                case DioExceptionType.unknown:
                    if (error.error != null && error.error.toString().contains('SocketException')) {
                        errorMessage = 'No internet connection';
                    }
                    break;
                default:
                    errorMessage = 'Network error occurred';
                    break;
            }
        }
        
        // Display error to user
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
            ),
        );
    }
    
    static String _handleResponseError(int? statusCode) {
        switch (statusCode) {
            case 400:
                return 'Bad request';
            case 401:
                return 'Unauthorized';
            case 403:
                return 'Forbidden';
            case 404:
                return 'Resource not found';
            case 500:
            case 501:
            case 502:
            case 503:
                return 'Server error';
            default:
                return 'Operation failed';
        }
    }
} 