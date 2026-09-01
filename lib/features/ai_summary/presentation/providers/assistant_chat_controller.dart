import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/chat_message.dart';
import 'ai_summary_providers.dart';

const _uuid = Uuid();

class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isSending = false,
  });

  final List<ChatMessage> messages;
  final bool isSending;

  AssistantChatState copyWith({List<ChatMessage>? messages, bool? isSending}) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// In-meeting AI assistant chat — SRD FR-11.1/11.2. autoDispose + family
/// by meetingId: the conversation only matters while the Assistant tab is
/// open. Nothing is persisted server-side to resume from (see
/// ChatMessage's doc comment), so leaving and re-entering the meeting
/// starts a fresh conversation — a documented simplification, not a bug;
/// see PHASE8_README.md.
class AssistantChatController extends AutoDisposeFamilyNotifier<AssistantChatState, String> {
  @override
  AssistantChatState build(String arg) => const AssistantChatState();

  Future<void> send(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMessage], isSending: true);

    try {
      final reply = await ref.read(queryAssistantUseCaseProvider)(arg, trimmed);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(id: _uuid.v4(), role: ChatRole.assistant, content: reply, createdAt: DateTime.now()),
        ],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: _uuid.v4(),
            role: ChatRole.assistant,
            content: ApiFailure.from(e).message,
            createdAt: DateTime.now(),
            isError: true,
          ),
        ],
        isSending: false,
      );
    }
  }

  void clear() => state = const AssistantChatState();
}

final assistantChatControllerProvider = NotifierProvider.autoDispose
    .family<AssistantChatController, AssistantChatState, String>(AssistantChatController.new);
