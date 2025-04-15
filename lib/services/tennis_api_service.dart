import 'package:dio/dio.dart';

class TennisApiService {
    final Dio _dio = Dio();
    final String _baseUrl = 'https://api.example.com';  // Replace with actual API URL

    TennisApiService() {
        _dio.options.baseUrl = _baseUrl;
        _dio.options.connectTimeout = const Duration(seconds: 10);
        _dio.options.receiveTimeout = const Duration(seconds: 10);
        _dio.options.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
    }

    Future<List<dynamic>> getLiveMatches() async {
        try {
            final response = await _dio.get('/matches/live');
            return response.data['matches'] ?? [];
        } catch (e) {
            // In a real app, we'd handle different error types and log them
            print('Error fetching live matches: $e');
            return [];
        }
    }

    Future<List<dynamic>> getMatchesByDate(DateTime date) async {
        try {
            final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final response = await _dio.get('/matches/date/$formattedDate');
            return response.data['matches'] ?? [];
        } catch (e) {
            print('Error fetching matches by date: $e');
            return [];
        }
    }

    Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
        try {
            final response = await _dio.get('/matches/$matchId');
            return response.data ?? {};
        } catch (e) {
            print('Error fetching match details: $e');
            return {};
        }
    }
} 