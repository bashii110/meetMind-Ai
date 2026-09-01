import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

/// A single turn in an in-meeting assistant conversation — SRD FR-11.1.
/// Purely client-side: `POST /meetings/{id}/assistant/query`
/// (ARCHITECTURE.md section 5) is stateless per request, so there's no
/// server id or fromJson here — every message is either typed by the user
/// or produced from a query response, both constructed locally by
/// `AssistantChatController`.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  /// True if this assistant message represents a failed query rather than
  /// an actual reply — rendered with the error color instead of the AI
  /// accent color.
  final bool isError;

  @override
  List<Object?> get props => [id, role, content, createdAt, isError];
}
