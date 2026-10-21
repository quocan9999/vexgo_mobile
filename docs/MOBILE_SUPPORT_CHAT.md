# Customer support chat on Mobile

## Scope and backend dependency

Initial text chat integration built from mobile develop `7981d22` against VexGo backend PR #37 (`0fec20b` contract, plus its local follow-up fixes). Backend chat must be deployed before enabling this mobile flow against that environment. Account PR #6 is separate and is not included.

Entry: Account → Chat với nhà xe. Signed-in customers can select an active bus company, create or resume its active conversation, view old/closed conversations, load older messages, send text, retry an unconfirmed send, see read receipts and typing, and close a conversation. The server owns customer/tenant authorization and all authoritative message/conversation status.

Demo Mode shows a clear online-service requirement. It does not synthesize support agents or messages. File upload, attachment sending, push/background chat notifications and a persistent offline outbox are outside this initial scope. Received image messages are shown as an image-message label/content; arbitrary external attachment URLs are not opened automatically. The backend currently records the conversation channel as WEB; Mobile does not invent an unsupported DTO field.

## Contract and architecture

- `SupportChatRemoteDataSource` uses the existing authenticated `ApiClient` and refresh handling, REST `/api/v1/support-chat`. It follows public active bus-company pagination rather than limiting selection to the first page.
- `SupportChatRepository` separates transport from `SupportChatCubit` and the Flutter screen.
- `SupportChatSocket` uses Socket.IO client 3.1.6, `/chat` namespace, Engine.IO default `/socket.io`, `auth.token` JWT, native websocket transport, force-new/non-multiplexed sockets to prevent cached credentials from another session. It waits for `support.connected`, not transport connect, before commands.
- Exact supported event names and payloads come from `apps/api/src/support-chat/constants/chat-events.constants.ts` and DTOs. The REST list/message pages retain the server pagination envelopes. Close is followed by an authoritative detail read because the first close response can contain only scalar fields.
- One cryptographically random client message ID is reused for Socket.IO acknowledgement, REST fallback and explicit retry. Broadcast, ACK and history reconcile by server ID or matching client ID plus sender. An error after commit is checked against authoritative history before showing an unconfirmed retry state. No optimistic message is claimed to be server-persisted without an authoritative server record.
- Reconnect rejoins the selected conversation, refreshes its details and bridges all missing history pages from the last authoritative history checkpoint. A newer realtime ID cannot advance that checkpoint. An in-flight token-refreshing REST request is awaited before socket authentication recovery.
- Close is single flight. Unknown conversation statuses fail closed for sending.

## Session, read and race boundaries

The global chat Cubit receives the same authenticated account identity as existing ticket/notification state. Token invalidation, logout and account switches disconnect the socket and clear all customer chat state. The mounted screen separately verifies its displayed session against AuthBloc. REST responses, ACKs and lifecycle changes are guarded by session epoch and selected-conversation generation. Switching A → B cannot insert A's late history/ACK into B. Backgrounding disconnects realtime, disables reads, clears invalidated create/close busy flags and invalidates stale view work; foreground reconnect resynchronizes. A suspended create failure cannot clear a newer create operation or insert stale errors after resume.

Read requests contain only nonempty explicit IDs of incoming server messages whose rendered bubbles intersect the active transcript viewport. Covered routes, background documents and loading history are excluded. Own-account read receipts never imply that staff read outgoing messages. Typing is throttled and expires locally. No chat text or JWT is written to debug logs by the chat adapter.

Pending text and retry IDs live in the current transcript in memory. Navigating away or restarting the process reloads persisted server history; there is no durable offline outbox or cross-device draft synchronization.

## Verification on 2026-10-21

Executed locally:

- `flutter test --reporter expanded`: **358 passed**, including **27 chat model/HTTP/Cubit regressions and 5 chat widget regressions**.
- `flutter analyze`: **No issues found**.
- `dart format --output=none --set-exit-if-changed lib test`: **162 files, 0 changes**.
- `flutter build apk --debug --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:4000/api/v1`: **passed**, final incremental build 124.4 seconds.
- A separate temporary Dart integration harness executed **10 actual API/JWT/Socket.IO checks** against dedicated local API 4012 / MySQL 3308 (`vexgo_chat_mobile_test`). It used newly created disposable customer/staff/tenant fixtures, without guard overrides, and did not touch the shared database or the browser QA conversation. Actual checks included native Dart authentication and ACK/event delivery, idempotent REST retry, real REST fallback, reconnect catchup of an offline staff reply, persisted read status, typing and close. The harness and evidence remain outside Git in `mobile-qa-evidence/chat-qa/`.

The regressions cover a slow history response racing realtime, conversation/session switch, ACK failure after a broadcast, REST fallback using the same ID, persistence recovered from GET after send errors/close, retained ID/single-flight retry, read receipts and precise visible reads, all company pages, close single flight, JWT recovery waiting on an in-flight list, a realtime message arriving before reconnect history resync, deferred create/close operations across background/resume, and a suspended create failure racing a newer create. Widget tests cover send → refresh → reopen, logout/draft isolation, received messages, closed composer and offscreen reads.

The 358-test suite consists of automated contract/HTTP-fixture/widget tests. The separate 10-check run uses the real Dart adapter and local NestJS/MySQL. Neither result claims physical-device E2E. The first widget harness failures (settling the old FAB animation, delivering a fixture stream from setUp's real async zone, and a dispose callback after an already closed Cubit) were corrected; the real source disposal path now safely ignores a closed Cubit. Private command logs are outside Git in `mobile-qa-evidence/`.

QA debug build uses `--dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:4000/api/v1`. Device QA requires forwarding phone port 4000 to the dedicated local chat API port (currently 4012). No shared database migration/reset/seed is part of this mobile change. No PR merge or review-thread resolution is authorized by these checks.


## PR #7 Lead review follow-up

Baseline: `5c7ea756592f19305a9da83108528284a83f4554`. Seven deterministic regressions were added and executed against the baseline implementation first; all seven failed for the reported behavior before the implementation fix.

- Socket activation and authentication recovery now check the current foreground connection generation after both the conversation-list await and the token await. Backgrounding, leaving chat, or changing sessions invalidates pending connection work. An old activation cannot reconnect with its suspended token after a newer foreground activation has already connected.
- Automatic conversation summary refreshes retain previously loaded pages and the highest fetched page cursor. The latest server page is ordered first, cached rows from later pages remain available, and offset-page overlaps after a reorder are deduplicated by conversation ID. The next load-more fetch continues with the next unfetched page; a realtime event does not reopen exhausted pagination. Explicit list refresh retains its existing page-reset behavior.

The new pagination regression defers the reordered first-page response after loading 40 rows, introduces a new conversation while promoting an existing older row, then verifies the retained 41 rows and page sequence `1, 2, 1, 3, 4` until all 61 unique rows are loaded. A separate exhausted-pagination regression covers reordering without adding rows. Foreground regressions cover each activation/recovery await boundary and a suspended activation racing the resumed connection.

Executed after the fixes: **39 focused chat tests**, **365 full Flutter tests**, analyzer **0 issues**, format **162 files / 0 changes**, and the Real Mode debug APK build **passed** (121.9 seconds). These checks use fixtures and controlled Futures; they do not claim a new physical-device run or replay the earlier live API integration. No shared database writes, APK installation, merge, commit, or push is part of this follow-up validation. Red/green logs are kept outside Git under `mobile-qa-evidence/chat-qa/mobile-pr7-lead-*`.
