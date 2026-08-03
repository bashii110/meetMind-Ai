import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/meeting.dart';
import 'meeting_providers.dart';
import 'meetings_list_controller.dart';

class MeetingDetailsController
    extends AutoDisposeFamilyAsyncNotifier<Meeting, String> {

  @override
  Future<Meeting> build(String arg) {
    return ref.read(getMeetingUseCaseProvider)(arg);
  }

  Future<void> changeStatus(String status) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
          () => ref.read(changeMeetingStatusUseCaseProvider)(arg, status),
    );

    _refreshList();
  }


  Future<void> updateProfile({
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? location,
    String? onlineLink,
    String? priority,
    String? category,
    List<String>? tags,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
          () => ref.read(updateMeetingUseCaseProvider)(
        arg,
        title: title,
        description: description,
        date: date,
        time: time,
        location: location,
        onlineLink: onlineLink,
        priority: priority,
        category: category,
        tags: tags,
      ),
    );

    if (state.hasError) {
      throw state.error!;
    }

    _refreshList();
  }


  Future<List<String>> inviteParticipants(
      List<String> emails,
      ) async {
    final notFound =
    await ref.read(inviteParticipantsUseCaseProvider)(
      arg,
      emails,
    );

    await _reload();

    return notFound;
  }


  Future<void> respondToInvitation(String status) async {
    await ref.read(respondToInvitationUseCaseProvider)(
      arg,
      status,
    );

    await _reload();

    _refreshList();
  }


  Future<void> removeParticipant(String userId) async {
    await ref
        .read(meetingRepositoryProvider)
        .removeParticipant(arg, userId);

    await _reload();
  }


  Future<void> delete() async {
    await ref.read(deleteMeetingUseCaseProvider)(arg);

    _refreshList();
  }


  Future<void> _reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
          () => ref.read(getMeetingUseCaseProvider)(arg),
    );
  }


  void _refreshList() {
    ref
        .read(meetingsListControllerProvider.notifier)
        .refresh();
  }
}


final meetingDetailsControllerProvider =
AsyncNotifierProvider.autoDispose
    .family<MeetingDetailsController, Meeting, String>(
  MeetingDetailsController.new,
);