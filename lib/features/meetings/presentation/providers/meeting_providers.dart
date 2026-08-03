import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/meeting_remote_data_source.dart';
import '../../data/repositories/meeting_repository_impl.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../../domain/usecases/change_meeting_status_usecase.dart';
import '../../domain/usecases/create_meeting_usecase.dart';
import '../../domain/usecases/delete_meeting_usecase.dart';
import '../../domain/usecases/get_meeting_usecase.dart';
import '../../domain/usecases/invite_participants_usecase.dart';
import '../../domain/usecases/list_meetings_usecase.dart';
import '../../domain/usecases/respond_to_invitation_usecase.dart';
import '../../domain/usecases/update_meeting_usecase.dart';

final meetingRemoteDataSourceProvider = Provider(
  (ref) => MeetingRemoteDataSource(ref.watch(dioProvider)),
);

final meetingRepositoryProvider = Provider<MeetingRepository>(
  (ref) => MeetingRepositoryImpl(ref.watch(meetingRemoteDataSourceProvider)),
);

final listMeetingsUseCaseProvider = Provider((ref) => ListMeetingsUseCase(ref.watch(meetingRepositoryProvider)));
final getMeetingUseCaseProvider = Provider((ref) => GetMeetingUseCase(ref.watch(meetingRepositoryProvider)));
final createMeetingUseCaseProvider = Provider((ref) => CreateMeetingUseCase(ref.watch(meetingRepositoryProvider)));
final updateMeetingUseCaseProvider = Provider((ref) => UpdateMeetingUseCase(ref.watch(meetingRepositoryProvider)));
final deleteMeetingUseCaseProvider = Provider((ref) => DeleteMeetingUseCase(ref.watch(meetingRepositoryProvider)));
final changeMeetingStatusUseCaseProvider =
    Provider((ref) => ChangeMeetingStatusUseCase(ref.watch(meetingRepositoryProvider)));
final inviteParticipantsUseCaseProvider =
    Provider((ref) => InviteParticipantsUseCase(ref.watch(meetingRepositoryProvider)));
final respondToInvitationUseCaseProvider =
    Provider((ref) => RespondToInvitationUseCase(ref.watch(meetingRepositoryProvider)));
