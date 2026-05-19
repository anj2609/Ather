import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/constants/app_constants.dart';
import 'core/errors/app_failure.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/domain/chat_message.dart';
import 'features/chat/presentation/chat_providers.dart';
import 'features/raid/domain/raid_snapshot.dart';
import 'features/raid/presentation/raid_join_controller.dart';
import 'features/raid/presentation/raid_providers.dart';
import 'features/world_event/presentation/world_event_providers.dart';

void main() {
  runApp(const ProviderScope(child: AetherApp()));
}

final class AetherApp extends StatelessWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Aether',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AetherScreen(),
    );
  }
}

final class AetherScreen extends StatelessWidget {
  const AetherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: wide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 6, child: EventCommandPanel()),
                        SizedBox(width: 20),
                        Expanded(flex: 4, child: ChatPanel()),
                      ],
                    )
                  : const SingleChildScrollView(
                      child: Column(
                        children: [
                          EventCommandPanel(compact: true),
                          SizedBox(height: 20),
                          SizedBox(height: 520, child: ChatPanel()),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

final class EventCommandPanel extends StatelessWidget {
  const EventCommandPanel({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final integrityPanel = DecoratedBox(
      decoration: _panelDecoration(context),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: ConcurrencyReadout(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 18),
        const CountdownPanel(),
        const SizedBox(height: 18),
        const RaidPanel(),
        const SizedBox(height: 18),
        if (compact) SizedBox(height: 340, child: integrityPanel),
        if (!compact) Expanded(child: integrityPanel),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROJECT AETHER', style: textTheme.displaySmall),
        const SizedBox(height: 6),
        Text('World event operations console', style: textTheme.bodyMedium),
      ],
    );
  }
}

final class CountdownPanel extends ConsumerWidget {
  const CountdownPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(worldEventTickProvider).value;
    final remaining = tick?.remaining ?? Duration.zero;
    final expired = tick?.expired ?? false;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final tenths = (remaining.inMilliseconds.remainder(1000) ~/ 100).toString();

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: _panelDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORLD BOSS',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nyx, the Rift Engine',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expired ? 'OPEN' : '$minutes:$seconds.$tenths',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (expired) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => ref
                          .read(worldBossStartsAtProvider.notifier)
                          .restart(),
                      child: const Text('Restart Countdown'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class RaidPanel extends ConsumerWidget {
  const RaidPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot =
        ref.watch(raidStreamProvider).value ??
        const RaidSnapshot(capacity: AppConstants.raidCapacity, slots: []);
    final joinState = ref.watch(joinControllerProvider);
    final userId = ref.watch(localUserIdProvider);
    final joined = snapshot.containsUser(userId);
    final busy = joinState is JoinSubmitting;
    final disabled = busy || snapshot.isFull || joined;

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Geo-Raid Slots',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${snapshot.occupied}/${snapshot.capacity} locked'),
              ],
            ),
            const SizedBox(height: 14),
            RaidSlotGrid(snapshot: snapshot),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: JoinStatusText(
                    state: joinState,
                    joined: joined,
                    isFull: snapshot.isFull,
                  ),
                ),
                FilledButton(
                  onPressed: disabled
                      ? null
                      : () => ref.read(joinControllerProvider.notifier).join(),
                  child: Text(
                    busy
                        ? 'Joining'
                        : joined
                        ? 'Joined'
                        : 'Join Raid',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class RaidSlotGrid extends StatelessWidget {
  const RaidSlotGrid({required this.snapshot, super.key});

  final RaidSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final occupants = {
      for (final slot in snapshot.slots) slot.index: slot.userId,
    };
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemCount: snapshot.capacity,
      itemBuilder: (context, index) {
        final occupied = occupants.containsKey(index);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: occupied ? const Color(0xFF17423D) : const Color(0xFF151B28),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: occupied
                  ? const Color(0xFF67E8F9)
                  : const Color(0xFF263247),
            ),
          ),
          child: Center(
            child: Text(
              occupied ? 'S${index + 1}' : '--',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

final class JoinStatusText extends StatelessWidget {
  const JoinStatusText({
    required this.state,
    required this.joined,
    required this.isFull,
    super.key,
  });

  final JoinState state;
  final bool joined;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final message = switch (state) {
      JoinSubmitting() => 'Submitting atomic join...',
      JoinSucceeded(:final receipt) =>
        receipt.idempotentReplay
            ? 'Join replayed safely: slot ${receipt.slotIndex + 1}'
            : 'Assigned slot ${receipt.slotIndex + 1}',
      JoinRejected(:final failure) => failure.message,
      JoinIdle() =>
        joined
            ? 'You are in the raid.'
            : isFull
                ? 'Raid is full. Allocation closed.'
                : 'Ready for atomic allocation.',
    };
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
  }
}

final class ConcurrencyReadout extends ConsumerWidget {
  const ConcurrencyReadout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(raidStreamProvider).value;
    final full = snapshot?.isFull ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Integrity Contract',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _MetricRow(label: 'Capacity invariant', value: 'slots <= 15'),
        _MetricRow(label: 'Join semantics', value: 'transactional CAS'),
        _MetricRow(label: 'Idempotency key', value: 'userId'),
        _MetricRow(
          label: 'Current state',
          value: full ? 'closed' : 'accepting',
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: full ? null : () => _simulateJoins(ref),
          child: const Text('Simulate 50 Joins'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            ref.read(raidRepositoryProvider).reset();
            ref.invalidate(joinControllerProvider);
          },
          child: const Text('Reset Simulation'),
        ),
      ],
    );
  }

  Future<void> _simulateJoins(WidgetRef ref) async {
    final repository = ref.read(raidRepositoryProvider);
    final runId = DateTime.now().microsecondsSinceEpoch;
    await Future.wait(
      List.generate(50, (index) {
        return repository.joinRaid('sim-$runId-$index');
      }),
    );
  }
}

final class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

final class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

final class _ChatPanelState extends ConsumerState<ChatPanel> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(latestChatProvider).value ?? const [];
    final sendState = ref.watch(sendChatControllerProvider);
    final sending = sendState.isLoading;
    final sendError = sendState.error;
    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Engagement Chat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                reverse: true,
                itemCount: messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return ChatMessageTile(message: messages[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Send raid callout',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: sendError == null
                          ? null
                          : switch (sendError) {
                              AppFailure(:final message) => message,
                              _ => 'Message could not be sent',
                            },
                    ),
                    onSubmitted: sending ? null : (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: sending ? null : _send,
                  child: Text(sending ? 'Sending' : 'Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final body = _controller.text;
    await ref.read(sendChatControllerProvider.notifier).send(body);
    if (!mounted || ref.read(sendChatControllerProvider).hasError) {
      return;
    }
    _controller.clear();
  }
}

final class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(message.sentAt);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151B28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263247)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.userId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(message.body),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Theme.of(context).dividerColor),
    boxShadow: const [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );
}
