import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/auth/presentation/providers/auth_controller.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_filters.dart';
import 'package:meetmind_ai/features/meetings/presentation/providers/meeting_providers.dart';
import 'package:meetmind_ai/features/meetings/presentation/providers/meetings_list_controller.dart';

import '../../../../test_utils/fakes/fake_meeting_repository.dart';
import '../../../../test_utils/fakes/fixed_auth_controller.dart';
import '../../../../test_utils/fixtures.dart';

void main() {
  late FakeMeetingRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeMeetingRepository(
      items: [
        buildMeeting(id: '1', title: 'Sprint planning', status: 'scheduled'),
        buildMeeting(id: '2', title: 'Retro', status: 'completed'),
      ],
    );
    container = ProviderContainer(
      overrides: [
        meetingRepositoryProvider.overrideWithValue(fakeRepo),
        // MeetingsListController.build() watches authControllerProvider
        // purely to rebuild on login/logout - a fixed signed-in user is
        // enough to let it settle without a real token/network round trip.
        authControllerProvider.overrideWith(() => FixedAuthController(buildUser())),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() loads meetings once a user is resolved', () async {
    final state = await container.read(meetingsListControllerProvider.future);

    expect(state.items.length, 2);
    expect(state.items.first.title, 'Sprint planning');
  });

  test('refresh() re-fetches from the repository', () async {
    await container.read(meetingsListControllerProvider.future);
    fakeRepo.items = [buildMeeting(id: '3', title: 'New meeting')];

    await container.read(meetingsListControllerProvider.notifier).refresh();

    final state = container.read(meetingsListControllerProvider).value!;
    expect(state.items.single.title, 'New meeting');
  });

  test('applyFilters() passes the filters through to the repository', () async {
    await container.read(meetingsListControllerProvider.future);

    await container
        .read(meetingsListControllerProvider.notifier)
        .applyFilters(const MeetingFilters(status: 'draft'));

    expect(fakeRepo.lastFilters?.status, 'draft');
  });
}
