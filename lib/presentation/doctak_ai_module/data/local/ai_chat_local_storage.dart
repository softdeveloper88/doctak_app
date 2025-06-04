import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_chat_model/ai_chat_message_model.dart';
import '../models/ai_chat_model/ai_chat_session_model.dart';

class AiChatLocalStorage {
  // Keys
  static const String _sessionsKey = 'ai_chat_sessions';
  static const String _messagesPrefix = 'ai_chat_messages_';
  static const String _lastUpdateKey = 'ai_chat_last_update';

  // Cache expiration time (24 hours)
  static const int _cacheExpirationHours = 24;

  // Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Save sessions to local storage
  static Future<void> saveSessions(List<AiChatSessionModel> sessions) async {
    final prefs = await _prefs;
    final sessionsJson = sessions.map((session) => session.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    await _updateLastUpdateTime();
  }

  // Get sessions from local storage
  static Future<List<AiChatSessionModel>?> getSessions() async {
    final prefs = await _prefs;
    
    // Check if cache is expired
    if (await _isCacheExpired()) {
      return null;
    }
    
    final sessionsString = prefs.getString(_sessionsKey);
    if (sessionsString == null) {
      return null;
    }
    
    try {
      final List sessionsList = jsonDecode(sessionsString);
      return sessionsList
          .map((json) => AiChatSessionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error deserializing sessions: $e');
      return null;
    }
  }

  // Save messages for a session
  static Future<void> saveMessages(String sessionId, List<AiChatMessageModel> messages) async {
    final prefs = await _prefs;
    final messagesJson = messages.map((message) => message.toJson()).toList();
    await prefs.setString('$_messagesPrefix$sessionId', jsonEncode(messagesJson));
    await _updateLastUpdateTime();
  }

  // Get messages for a session
  static Future<List<AiChatMessageModel>?> getMessages(String sessionId) async {
    final prefs = await _prefs;
    
    // Check if cache is expired
    if (await _isCacheExpired()) {
      return null;
    }
    
    final messagesString = prefs.getString('${_messagesPrefix}$sessionId');
    if (messagesString == null) {
      return null;
    }
    
    try {
      final List messagesList = jsonDecode(messagesString);
      return messagesList
          .map((json) => AiChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error deserializing messages: $e');
      return null;
    }
  }

  // Add a new message to a session's message list
  static Future<void> addMessage(String sessionId, AiChatMessageModel message) async {
    final messages = await getMessages(sessionId) ?? [];
    messages.add(message);
    await saveMessages(sessionId, messages);
  }

  // Clear all AI chat data
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key == _sessionsKey || key.startsWith(_messagesPrefix) || key == _lastUpdateKey) {
        await prefs.remove(key);
      }
    }
  }

  // Update the last update timestamp
  static Future<void> _updateLastUpdateTime() async {
    final prefs = await _prefs;
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  // Check if cache is expired
  static Future<bool> _isCacheExpired() async {
    final prefs = await _prefs;
    final lastUpdateString = prefs.getString(_lastUpdateKey);
    
    if (lastUpdateString == null) {
      return true;
    }
    
    try {
      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);
      
      return difference.inHours > _cacheExpirationHours;
    } catch (e) {
      print('Error parsing last update time: $e');
      return true;
    }
  }
}