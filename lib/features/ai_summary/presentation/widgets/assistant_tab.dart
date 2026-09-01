import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/ai%20status/presentation/providers/ai_status_controller.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../ai status/presentation/screens/ai_status_states.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/assistant_chat_controller.dart';

/// SRD FR-11.2's listed capabilities, offered as tappable presets rather
/// than bespoke UI per capability — each just sends different prompt text
/// through the same generic `queryAssistant` endpoint (FR-11.1).
const _suggestedPrompts = [
  'Summarize this meeting',
  'Who owns each task?',
  "What's the next deadline?",
  'Draft a follow-up email',
  'Generate meeting minutes',
  'Convert to a project plan',
];

/// SRD FR-11.1/11.2: in-meeting AI assistant chat with suggested prompts
/// (PHASES.md Phase 8). Gated the same way TranscriptTab is — the
/// assistant needs at least a transcript to answer anything useful, so it
/// doesn't wait for the full summary/task-extraction pipeline to finish.
class AssistantTab extends ConsumerStatefulWidget {
  const AssistantTab({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends ConsumerState<AssistantTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(assistantChatControllerProvider(widget.meetingId).notifier).send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(aiStatusControllerProvider(widget.meetingId));

    return status.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (aiStatus) {
        if (!aiStatus.hasRecording) {
          return const AiEmptyState(
            icon: Icons.smart_toy_outlined,
            title: 'No recording yet',
            message: 'Record this meeting, and you can ask the assistant questions about it here.',
          );
        }
        if (aiStatus.hasFailed) {
          return AiFailedState(message: aiStatus.errorMessage ?? 'Processing failed.');
        }
        // The assistant only needs the transcript, not the full
        // summary/task pipeline — same gate TranscriptTab uses.
        final transcriptExpected = aiStatus.status != AiPipelineStatus.pending &&
            aiStatus.status != AiPipelineStatus.uploading &&
            aiStatus.status != AiPipelineStatus.uploaded &&
            aiStatus.status != AiPipelineStatus.transcribing;
        if (!transcriptExpected) {
          return AiProcessingState(label: aiStatus.label);
        }

        final chat = ref.watch(assistantChatControllerProvider(widget.meetingId));

        return Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? _SuggestedPromptsView(onTap: _send)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(Spacing.lg),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: chat.messages[index]),
                    ),
            ),
            if (chat.isSending)
              const Padding(
                padding: EdgeInsets.only(bottom: Spacing.xs),
                child: _TypingIndicator(),
              ),
            _Composer(
              controller: _controller,
              enabled: !chat.isSending,
              onSend: () => _send(),
            ),
          ],
        );
      },
    );
  }
}

class _SuggestedPromptsView extends StatelessWidget {
  const _SuggestedPromptsView({required this.onTap});

  final void Function(String prompt) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 48, color: AppTheme.aiAccent(context)),
            const SizedBox(height: Spacing.md),
            Text('Ask about this meeting', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              'Try one of these, or ask your own question below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final prompt in _suggestedPrompts)
                  ActionChip(
                    label: Text(prompt),
                    onPressed: () => onTap(prompt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;

    final bubbleColor = message.isError
        ? scheme.errorContainer
        : isUser
            ? scheme.primaryContainer
            : scheme.tertiaryContainer;
    final textColor = message.isError
        ? scheme.onErrorContainer
        : isUser
            ? scheme.onPrimaryContainer
            : scheme.onTertiaryContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.md),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      'Assistant',
                      style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            SelectableText(message.content, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.aiAccent(context)),
          ),
          const SizedBox(width: Spacing.sm),
          Text('Assistant is thinking…', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                decoration: const InputDecoration(hintText: 'Ask the assistant…'),
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
