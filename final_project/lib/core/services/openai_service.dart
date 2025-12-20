import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get _threadId => dotenv.env['OPENAI_THREAD_ID'] ?? '';
  
  /// Send a query to ChatGPT with restaurant context
  static Future<String> getChatGPTResponse(String userMessage, {String? restaurantContext}) async {
    if (_apiKey.isEmpty) {
      debugPrint('❌ OpenAI API key not found in .env file');
      return 'Sorry, the AI assistant is not configured properly. Please check the API key.';
    }
    
    try {
      debugPrint('🤖 Sending query to OpenAI: $userMessage');
      
      // Build the system prompt with restaurant context
      final systemPrompt = _buildSystemPrompt(restaurantContext);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userMessage,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );
      
      debugPrint('🤖 OpenAI response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        
        debugPrint('✅ OpenAI response received successfully');
        return content.toString().trim();
      } else {
        debugPrint('❌ OpenAI API error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      debugPrint('❌ OpenAI service error: $e');
      return _getFallbackResponse(userMessage);
    }
  }
  
  /// Build system prompt with restaurant context
  static String _buildSystemPrompt(String? restaurantContext) {
    const basePrompt = '''You are Torbaaz AI Assistant, a helpful chatbot for a food delivery and restaurant discovery app called Torbaaz. 

Your role:
- Help users find restaurants, deals, and menu items
- Provide information about food options in Khanewal, Pakistan
- Be friendly, concise, and helpful
- Focus on local restaurants and Pakistani cuisine
- Suggest popular dishes and current deals

Keep responses under 100 words and always be enthusiastic about food and local restaurants.''';

    if (restaurantContext != null && restaurantContext.isNotEmpty) {
      return '$basePrompt\n\nCurrent restaurant data context:\n$restaurantContext\n\nUse this data to provide accurate, up-to-date information about restaurants, menus, and deals.';
    }
    
    return basePrompt;
  }
  
  /// Provide fallback response when OpenAI fails
  static String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('restaurant') || lowerMessage.contains('food')) {
      return '🍽 Sorry, I\'m having trouble connecting to my brain right now! But I can tell you that Torbaaz has amazing local restaurants in Khanewal. Try exploring the menu to discover great food options!';
    } else if (lowerMessage.contains('deal') || lowerMessage.contains('offer')) {
      return '🎉 I\'m temporarily offline, but don\'t miss out on the exciting deals available in the app! Check out the latest offers from local restaurants.';
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return '👋 Hello! I\'m the Torbaaz AI Assistant. I\'m having a small technical hiccup, but I\'m here to help you discover amazing food! How can I assist you today?';
    } else {
      return '🤖 I apologize, but I\'m experiencing some technical difficulties right now. Please try again in a moment, or explore the app to discover great restaurants and deals!';
    }
  }
  
  /// Get restaurant context from the app data
  static String buildRestaurantContext({
    List<Map<String, dynamic>>? restaurants,
    List<Map<String, dynamic>>? deals,
    List<Map<String, dynamic>>? menuItems,
  }) {
    final contextParts = <String>[];
    
    if (restaurants != null && restaurants.isNotEmpty) {
      final restaurantInfo = restaurants.map((r) => 
        '${r['name']} - ${r['cuisine']} cuisine, Rating: ${r['rating']}/5, Location: ${r['location']}'
      ).join('\n');
      contextParts.add('RESTAURANTS:\n$restaurantInfo');
    }
    
    if (deals != null && deals.isNotEmpty) {
      final dealInfo = deals.map((d) => 
        'Deal: ${d['title']} - ${d['description']} (${d['discount']})'
      ).join('\n');
      contextParts.add('CURRENT DEALS:\n$dealInfo');
    }
    
    if (menuItems != null && menuItems.isNotEmpty) {
      final menuInfo = menuItems.take(10).map((m) => 
        '${m['name']} - Rs.${m['price']} (${m['category']})'
      ).join('\n');
      contextParts.add('POPULAR MENU ITEMS:\n$menuInfo');
    }
    
    return contextParts.join('\n\n');
  }
  
  /// Test OpenAI connection
  static Future<bool> testConnection() async {
    if (_apiKey.isEmpty) {
      debugPrint('❌ OpenAI API key not configured');
      return false;
    }
    
    try {
      final response = await getChatGPTResponse('Hello, can you help me test the connection?');
      return response.isNotEmpty && !response.contains('not configured properly');
    } catch (e) {
      debugPrint('❌ OpenAI connection test failed: $e');
      return false;
    }
  }
}