# Project Aether

Project Aether is a single-screen Flutter submission for a high-concurrency MMORPG world event. The implementation focuses on deterministic raid-slot allocation, granular reactive rendering, testable feature modules, and a Firebase scaling plan that avoids runaway realtime read costs.

## Architecture Overview

The app uses clean, modular, feature-first architecture with Riverpod for dependency injection and narrowly scoped reactive state.

```text
lib/
  core/
    constants/
    errors/
    services/
    theme/
    utils/
  features/
    raid/
      data/
      domain/
      presentation/
    chat/
      data/
      domain/
      presentation/
    world_event/
      domain/
      presentation/
```

Domain models are immutable. Data DTOs are separate from domain entities. UI widgets depend on use cases and repositories through providers, not concrete persistence APIs. The current persistence layer is an in-memory simulation so the concurrency harness can run deterministically without Firebase credentials, but the repository contracts map directly to Firestore transaction and listener boundaries.

## Feature Design

`world_event` owns the 100ms boss countdown. The timer is exposed as a stream provider, and the countdown text is isolated behind a `RepaintBoundary` so the fast cadence does not rebuild the raid and chat surfaces.

`raid` owns slot allocation. The UI calls `JoinRaidUseCase`, which calls `RaidRepository`. The repository uses a serial transaction runner to model Firestore transaction isolation locally. This keeps business logic independently testable and makes the atomic path explicit.

`chat` owns latest-window listening, pagination, and message sending. The app listens only to the visible shard and a bounded latest window. Historical reads are paginated through cursor APIs instead of being attached to a realtime listener.

## Raid Concurrency Strategy

The raid invariant is:

```text
0 <= occupiedSlots <= 15
one userId maps to at most one slot
slot assignment happens only inside the transaction boundary
```

The join flow is compare-and-swap semantics:

1. Enter the transaction runner.
2. Check whether the `userId` already owns a slot.
3. Return the same slot as an idempotent replay if it exists.
4. Check capacity inside the same transaction.
5. Allocate the next slot and publish the snapshot.
6. If capacity is full, return a typed `RaidFullFailure`.

In Firestore, the same contract would be implemented with `runTransaction` against a raid document or a small set of shard documents:

```text
raids/{raidId}
  capacity: 15
  occupied: n
  version: monotonic integer
  members/{userId}
```

The transaction reads the raid document and the member document, creates the member only if absent, increments `occupied` only when `occupied < capacity`, and fails gracefully otherwise. Firestore retries conflicting transactions, so simultaneous joins converge on exactly 15 successful commits. A uniqueness constraint is achieved by using `members/{userId}` as the idempotency key.

The included test harness fires 50 simultaneous joins and verifies exactly 15 successes, exactly 35 full failures, and slot indexes `0..14`.

## Firebase Chat Scaling Strategy

A naive chat listener for 10,000 users can multiply reads by every message delivered to every connected client. The scalable design is to limit listener scope and split hot paths from historical reads.

Recommended Firestore layout:

```text
chatRooms/{roomId}
  meta/latest
  shards/{shardId}/buckets/{yyyyMMddHH}/messages/{messageId}
  archives/{yyyyMMdd}/messages/{messageId}
presence/{roomId}/shards/{shardId}/users/{userId}
aggregates/{roomId}/minuteBuckets/{bucketId}
```

Cost controls:

- Room sharding: split writes across deterministic shards, commonly by user hash or region. Clients subscribe to only the shard or merged subset needed for their viewport.
- Message bucketing: write messages into hourly or minute buckets to keep queries bounded and indexes efficient.
- Latest-window listeners: attach realtime listeners only to the newest `N` messages, such as 30 to 100. Older history is loaded with paginated one-shot reads.
- Cursor pagination: historical scrollback uses `startAfter` cursors and `limit`, never an unbounded listener.
- Batched listeners: large rooms can have one listener per visible bucket/shard, with hard caps. The client detaches listeners outside the viewport.
- Fan-out reduction: avoid sending every message to every client if the UI does not need it. Use shard-local latest windows and server-side summary documents for room-level activity.
- Write aggregation: Cloud Functions can update aggregate counters and latest-message summaries, letting lobby surfaces read one small document instead of listening to message collections.
- TTL cleanup: ephemeral event chat should have Firestore TTL policies for short-lived buckets, with archival export for compliance or replay.
- Selective subscriptions: combat log, raid leader calls, and general chat should be separate streams so clients subscribe only to relevant channels.
- Cache-first strategy: enable local persistence and render cached latest windows immediately, then reconcile with server snapshots.
- Presence separation: presence is not stored in the message path. It has short TTL documents or Realtime Database presence, preventing high-churn presence writes from invalidating chat listeners.
- Archival collections: cold history is compacted into archive collections or object storage. Realtime listeners never attach to archives.

For 10,000 concurrent users, the target is not zero reads; it is bounded reads proportional to visible windows and selected shards, not total room traffic. A raid command UI may listen to leader-call shard `0` and fetch general chat only on demand.

## Performance Considerations

- Riverpod providers are scoped by feature and expose small state surfaces.
- The 100ms timer selects only `Duration remaining`, so unrelated widgets do not rebuild.
- The countdown is isolated in a repaint boundary.
- Raid snapshots are immutable and published as unmodifiable lists.
- Chat listens to a bounded latest window and paginates history.
- UI controls represent pending, full, joined, and rejected states explicitly.

## Testing

Run:

```bash
flutter analyze
flutter test
```

Covered behavior:

- 50 concurrent raid join attempts result in exactly 15 successes and 35 failures.
- Raid joins are idempotent by `userId`.
- Raid reset publishes an empty snapshot.
- Chat latest-window listeners are shard-scoped and limit-scoped.
- Chat pagination returns bounded cursor pages.
- Empty chat messages fail with typed errors.
- World-event countdown clamps expired timers to zero and emits 100ms cadence ticks.

## Tradeoffs

The production Firestore adapter is represented by repository contracts and a deterministic in-memory adapter because this submission must run without external Firebase configuration. That choice keeps the concurrency contract executable in tests while still preserving a direct migration path to Firestore transactions.

The chat demo uses a single visible shard in UI to make listener scoping obvious. Production clients can merge multiple shard windows when the UX requires a broader room view, but every added shard has a measurable read-cost impact.

## Future Roadmap

- Add a Firestore-backed `RaidRepository` using `runTransaction` and emulator tests.
- Add a Firestore-backed `ChatRepository` with sharded buckets and integration tests against the Firebase Emulator Suite.
- Add server-issued raid join tokens to prevent forged client writes.
- Add App Check and security rules for raid membership, chat writes, TTL, and presence.
- Add telemetry for join latency, transaction retry rate, listener counts, and read-per-user budgets.
- Add load tests that replay launch spikes and verify Firestore retry behavior under emulator contention.

