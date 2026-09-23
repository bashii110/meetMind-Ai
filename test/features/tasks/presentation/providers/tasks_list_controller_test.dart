import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_filters.dart';
import 'package:meetmind_ai/features/tasks/presentation/providers/task_providers.dart';
import 'package:meetmind_ai/features/tasks/presentation/providers/tasks_list_controller.dart';

import '../../../../test_utils/fakes/fake_task_repository.dart';
import '../../../../test_utils/fixtures.dart';

void main() {
  late FakeTaskRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeTaskRepository(
      items: [
        buildTask(id: '1', title: 'Write report', status: 'pending'),
        buildTask(id: '2', title: 'Review PR', status: 'pending'),
        buildTask(id: '3', title: 'Ship release', status: 'completed'),
      ],
      pageSize: 2,
      totalPages: 2,
    );
    container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
  });

  test('build() loads the first page from the repository', () async {
    final state = await container.read(tasksListControllerProvider.future);

    expect(state.items.length, 2);
    expect(state.items.first.title, 'Write report');
    expect(state.hasMore, isTrue);
    expect(fakeRepo.lastPage, 1);
  });

  test('loadMore() appends the next page and clears hasMore once exhausted', () async {
    await container.read(tasksListControllerProvider.future);
    final notifier = container.read(tasksListControllerProvider.notifier);

    await notifier.loadMore();

    final state = container.read(tasksListControllerProvider).value!;
    expect(state.items.length, 3);
    expect(state.items.last.title, 'Ship release');
    expect(state.hasMore, isFalse);
  });

  test('loadMore() is a no-op while already loading or once exhausted', () async {
    await container.read(tasksListControllerProvider.future);
    final notifier = container.read(tasksListControllerProvider.notifier);

    await notifier.loadMore(); // now exhausted (hasMore == false)
    await notifier.loadMore(); // should not fetch page 3

    expect(fakeRepo.lastPage, 2);
  });

  test('applyFilters() re-fetches from page 1 with the new filters', () async {
    await container.read(tasksListControllerProvider.future);
    final notifier = container.read(tasksListControllerProvider.notifier);

    await notifier.applyFilters(const TaskFilters(status: 'completed'));

    expect(fakeRepo.lastFilters?.status, 'completed');
    expect(fakeRepo.lastPage, 1);
  });

  test('loadMore() failure keeps the existing items and stops the spinner', () async {
    await container.read(tasksListControllerProvider.future);
    final notifier = container.read(tasksListControllerProvider.notifier);

    fakeRepo.listError = Exception('network down');
    await notifier.loadMore();

    final state = container.read(tasksListControllerProvider).value!;
    expect(state.items.length, 2);
    expect(state.isLoadingMore, isFalse);
  });
}
