import 'package:apidash/dashbot/features/chat/models/chat_message.dart';
import 'package:apidash/dashbot/features/chat/viewmodel/chat_viewmodel.dart';
import 'package:apidash/dashbot/features/chat/models/chat_state.dart';
import 'package:apidash/dashbot/core/constants/constants.dart';
import 'package:flutter/material.dart';

class SpyChatViewmodel extends ChatViewmodel {
  SpyChatViewmodel(super.ref);

  final List<({String text, ChatMessageType type, bool countAsUser})>
      sendMessageCalls = [];

  bool clearCalled = false;
  List<ChatMessage> _messages = const [];

  void setMessages(List<ChatMessage> messages) {
    _messages = messages;
    state = state.copyWith(chatSessions: {'global': messages});
  }

  void setState(ChatState newState) {
    state = newState;
  }

  @override
  List<ChatMessage> get currentMessages => _messages;

  @override
  Future<void> sendMessage({
    required String text,
    ChatMessageType type = ChatMessageType.general,
    bool countAsUser = true,
  }) async {
    sendMessageCalls.add((text: text, type: type, countAsUser: countAsUser));
  }

  @override
  void clearCurrentChat() {
    clearCalled = true;
  }
}

class RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    lastRoute = route;
  }
}
