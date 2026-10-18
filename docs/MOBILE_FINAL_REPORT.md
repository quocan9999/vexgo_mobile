# VexGo Mobile — báo cáo triển khai 18–19/10/2026

## 1. Tiến độ và phiên bản đối chiếu

- Mobile ban đầu: `4aea4235505d69df61f1602e820fb915bbcab82e`, nhánh `feature/seat-hold-and-countdown`, PR [#5](https://github.com/quocan9999/vexgo_mobile/pull/5).
- Nhánh tích hợp: `fix/mobile-contract-integrity`. Vòng 1 chốt tại `a266508`; source vòng 2 đóng băng tại **`0a58e3f59cd8214f3e4e3d18c5d70a0118c61f2b`**, sau các commit đổi mật khẩu, fresh detail/guest lookup, quote/khuyến mãi và bản sửa review QR/refund. Gate vòng 2 được ghi bên dưới.
- Đã fetch `team`; `team/develop@ba66748c7f13b57f7081ae27db56cea2708890e9` đã nằm trong lịch sử nhánh Mobile. Không có commit develop mới để nhập thêm.
- Theo yêu cầu lấy code dev mới nhất, Backend đã chuyển từ `feature/realtime-chat-support@0fec20b` sang `develop@8b339250a95b6825cef591b1d10ae537ba1068f4`, bằng fast-forward nhánh develop. Nhánh feature cũ được giữ lại.
- Trong vòng implementation, bốn chỉnh sửa có sẵn được giữ riêng: `lib/app/routes.dart` (phần tìm kiếm), `lib/data/adapters/city_search_adapter.dart`, `lib/features/user/home/presentation/widgets/search_form_card.dart`, `test/lead_review_findings_regression_test.dart`. Sau khi người dùng đồng ý push để Lead review, chúng được chốt thành commit riêng `a7fba6f9febc69b4fe87d7d1ad8307142e92acff`.
- Gate vòng 2 kiểm tra source freeze cùng bốn thay đổi này; patch đã được đối chiếu với commit `a7fba6f` và khớp. Trên working tree sạch tại commit này, chạy lại analyze (không có issue) và toàn bộ **283 tests PASS**. Không có thay đổi implementation mới sau gate/APK; các commit handoff tiếp theo chỉ sửa tài liệu/bằng chứng.
- PR #5 được đọc trực tiếp: 62 threads, 6 chưa resolve tại thời điểm audit. Các finding được đối chiếu source; không tự resolve thread của Lead.
- Giữ BLoC → Repository → DataSource; không nâng dependencies. Không sửa implementation API Backend.

## 2. Feature Matrix trước và sau

Trạng thái sau phân biệt code đã sửa và kiểm thử component với xác minh end-to-end. `PARTIAL`/`NEEDS_VERIFICATION` không có nghĩa là fake success được chấp nhận.

| Feature | Trước | Backend develop mới | Sau | Finding / dependency còn lại | Ưu tiên | Owner |
|---|---|---|---|---|---|---|
| Login/register/OTP | PARTIAL | Có contract | NEEDS_VERIFICATION | Hydrate `/me`, input/OTP/error lifecycle đã sửa; chưa gửi SMS/đăng ký tài khoản thật | P1 | flutter-feature-engineer |
| Refresh/logout | NOT_IMPLEMENTED/PARTIAL | Có rotation/logout | NEEDS_VERIFICATION | Single-flight, một replay, storage failure/logout/account-switch đã test; chưa chạy phiên auth live | P1 | orchestrator + reviewer |
| Xem/sửa profile | PARTIAL | GET/PATCH `/me` | NEEDS_VERIFICATION | Dữ liệu profile thật, nullable clears và error giữ session đã test; bỏ số chuyến/voucher/hạng thành viên tự dựng trên Real UI | P1 | flutter-feature-engineer + orchestrator |
| Đổi mật khẩu | NOT_IMPLEMENTED | POST `/auth/change-password` | NEEDS_VERIFICATION | Nối API có bảo vệ, 8–72 byte UTF-8, không trim, chặn gửi trùng; 7 regression và review độc lập đạt; chưa đổi tài khoản live | P1 | orchestrator |
| Tìm chuyến/chi tiết | NEEDS_VERIFICATION | Có | NEEDS_VERIFICATION | API live search/detail/seats đạt; đọc đủ meta pages, retry khi page lỗi; detail fetch mới và booking nhận model mới; component tests đạt | P1 | flutter-feature-engineer + QA |
| Ghế thật/hold/countdown/release | PARTIAL | Có persistent holds | NEEDS_VERIFICATION | Clock/resume, release, chống double action và ghế unknown đã test component; chưa thao tác hold trên device thật | P1 | booking-payment-engineer |
| Guest Checkout | Ban đầu BLOCKED theo backend cũ | Đã hỗ trợ `/bookings` optional auth và public detail | PARTIAL | Tạo đơn không ép login; capability headers và ticket lookup thật; context phục hồi hiện giữ trong bộ nhớ, chưa có phục hồi qua app restart | P1 | orchestrator |
| Đặt vé / retry | PARTIAL | Có, chưa có client idempotency key | PARTIAL | Lưu từng ID, retry không tạo lại booking; mất response POST được khóa chờ xác minh; chưa có recovery query theo idempotency key | P0 | booking-payment-engineer |
| Báo giá / khuyến mãi / đơn 0đ | PARTIAL | Quote nhận contactPhone/optional auth; trả Decimal strings và eligibility | NEEDS_VERIFICATION | Summary/Confirm dùng quote server, chặn stale/lỗi, nhập mã thật, đơn 0đ không tạo payment; 15 regression PASS; live quote 404 do dữ liệu/cấu hình chưa đáp ứng | P0 | booking-payment-engineer |
| VietQR/SePay | Chưa nối đúng | Có webhook xác minh và settlement | NEEDS_VERIFICATION | Poll order ID/code/amount + cả hai trạng thái paid; public account config đối chiếu Backend; chưa chuyển tiền/ngân hàng thật | P0 | orchestrator + reviewer |
| MoMo/ZaloPay/VNPAY production | PARTIAL | Vẫn từ chối create ngoài demo | BLOCKED_BY_BACKEND | Real UI chỉ cung cấp VietQR; reject payment `mode: DEMO` trong Real Mode | P0 | Lead/backend |
| Xác minh payment và vé | PARTIAL, có P0 vé tự dựng | Có status, booking summary, full ticket | NEEDS_VERIFICATION | Không fallback vé giả; full ticket từng ID; paid/cancelled/unknown checks, multi-seat success route đã test | P0 | booking-payment-engineer |
| Vé của tôi / review | PARTIAL | Có | NEEDS_VERIFICATION | Fresh detail/retry ẩn QR cũ, guest code/phone lookup độc lập, chặn response qua phiên; list paging/review guard có regression; chưa xác minh tài khoản live | P1 | flutter-feature-engineer |
| Thông báo | PARTIAL | Có REST paging/read | NEEDS_VERIFICATION | Chỉ load theo phiên, xóa cache account cũ, lỗi read có xử lý, follow paging; chưa kiểm tra tài khoản live | P1 | flutter-feature-engineer |
| UI/UX | PARTIAL | Tùy feature | PARTIAL | Loading/error/retry và guest lookup đã bổ sung; không giả thao tác chia sẻ/gọi/đổi vé; push/ngôn ngữ/sinh trắc học/membership thiếu integration được hiển thị chưa hỗ trợ | P2 | feature engineers |
| Device / provider E2E | NEEDS_VERIFICATION | Backend local chạy được | NEEDS_VERIFICATION | Không có Android device/AVD; không có giao dịch ngân hàng thật | P1 | QA |

Hai blocker guest/gateway từ Backend `0fec20b` đã được đánh giá lại sau khi cập nhật dev. Không còn đánh dấu guest booking hoặc SePay/VietQR là Backend chưa hỗ trợ. Không đồng nhất việc có webhook code với đã kiểm chứng ngân hàng thật.

## 3. Công việc từng Agent

| Vai trò | Công việc thực tế | Bằng chứng |
|---|---|---|
| api-architect | Audit controllers/DTO/mappers và source Backend ban đầu; phân định gap và phát hiện vé DA_DAT trước thanh toán | Matrix/API contract trong Execution Plan; orchestrator đối chiếu lại develop mới |
| booking-payment-engineer | Staged checkout, giữ IDs, full ticket hydration, nhiều vé, wall-clock/lifecycle, QR gate, seat unknown và regression fixtures | Worktree/commit `e0f4299`, tích hợp thành `313d588` |
| booking-payment-engineer (vòng 2) | Quote/khuyến mãi thật, contact/session invalidation, Decimal parsing, đơn 0đ và mã phục hồi; bỏ checkbox lưu hành khách chưa có implementation | Worktree/commit `b07ad66`, tích hợp thành `c1a47f0`; 15 regression mới, full suite worktree 251 PASS, format/analyze PASS |
| flutter-feature-engineer | Hydrate profile, OTP form, nullable profile, đồng bộ/clear session cache, pagination/error/retry/review guard | Worktree/commit `fe8ceeb`, tích hợp thành `4cb1d78` |
| flutter-feature-engineer (vòng 2) | Search đủ pages; fresh trip/ticket detail; guest lookup và lifecycle; bỏ thông tin liên hệ/thao tác giả | Worktree/commit `af1de10`, tích hợp thành `f50b230`; 20 regression PASS; parent tích hợp chạy cùng 7 auth tests: 27 PASS |
| flutter-feature-engineer (sửa review vòng 1) | QR modal/card ràng buộc owner/token/reader, cả entrypoint không có reader; refund chưa xác nhận không báo đã hoàn | Worktree/commit `90660b2`, tích hợp thành `0a58e3f`; 46 scoped tests PASS, analyze/format PASS; reviewer chạy lại probe gốc |
| qa-e2e-engineer | Runtime probes độc lập; build Backend; GET live; mandatory Mobile gates | `../mobile-qa-evidence/` và báo cáo runtime mới |
| security-code-reviewer | Probes độc lập cho storage/refresh, guest/VietQR, QR/session, auth/password, quote/zero-total; phát hiện và xác minh sửa QR/refund | `security-review/REVIEW.md` (64); `AUTH-03-REVIEW.md` (29); `BP03-REVIEW.md` (20); `FINAL-0a58e3f-REVIEW.md` (31). Các nhóm có regression dùng lại, không cộng thành số test duy nhất |
| orchestrator | Fetch dev; cập nhật contract, triển khai refresh/storage, guest/VietQR, search race, tích hợp, sửa regression, backup/migrate và báo cáo | Các commit NET/integration/navigation; logs migration và test |

Runtime giới hạn ba Sub-Agent đồng thời; năm vai trò được chạy theo giai đoạn và writer dùng worktree riêng. Có gián đoạn usage: giữ lại code đang làm, orchestrator tiếp tục trực tiếp; QA/reviewer sau đó chạy lại được và đã xác minh độc lập. Người dùng chỉ cần theo dõi chat điều phối này.

## 4. Các lỗi đã sửa

- **P0:** Vé tự dựng `TKT_*`/`VXG-*` khi thiếu full ticket hoặc API lỗi; không dùng booking summary làm boarding pass.
- **P0:** Vé giữ chỗ chưa thanh toán, cancelled/used/unknown không được mở QR; payment SUCCESS đơn thuần không đủ nếu booking/order/ticket không xác nhận.
- **P0:** Retry/concurrent Confirm không tạo booking trùng; giữ booking/payment IDs sau lỗi từng stage. Nếu POST có kết quả chưa biết, không blind retry.
- **P0:** Cache dữ liệu của tài khoản trước và response in-flight không được ghi lại sau logout/account switch; màn hình vé riêng được loại khỏi navigation.
- **P0/P1:** Storage lỗi không cho phép ghép access token B với refresh token A; logout không phục hồi token qua response refresh đến muộn.
- **P1:** Countdown theo `expiresAt`, reconcile khi resume; consumed hold không làm mất đường kiểm tra payment; từ chối ghế thứ bảy không giải phóng hold hợp lệ.
- **P1:** Login/register tải `/me`; form giữ lỗi và password whitespace; không hứa thưởng 100 điểm giả; nullable profile clear hoạt động.
- **P1:** Lookup booking khi review và notification read failure được catch; protected data chỉ load theo session; pull refresh/paging được xử lý.
- **P1:** Kết quả search cũ không ghi đè ngày/tuyến mới; không tự hiển thị giá cho ngày chưa query hoặc đưa bảng phí hủy chưa xác minh.
- **P1:** Guest order sau login vẫn dùng đúng public booking/ticket lookup; không gửi người dùng guest vào API owner-only.
- **P1:** Unknown payment status được giữ là chưa xác định, không mặc định là pending/success.
- **P1:** Chi tiết chuyến/vé không dùng snapshot cũ để quyết định booking/QR; guest lookup không ghi vé vào cache tài khoản.
- **P1:** Đổi mật khẩu theo Backend mới, giữ lỗi form và chờ xác nhận; logout/refresh/late response được kiểm tra độc lập.
- **P2:** Bỏ hotline không có nguồn và lời hứa share/dial/đổi vé chưa thực hiện; Real profile không tự gán số chuyến/voucher/hạng thành viên hoặc bật giả push/biometric.
- **P0/P1:** Giá và mã khuyến mãi được xác minh bằng Backend quote, bao gồm eligibility contact/identity; không hiển thị 0đ khi chưa có giá; response quote cũ không được dùng để tạo booking.
- **P1 (sửa review vòng 1):** QR đang mở bị xóa/ẩn khi owner/token/reader hết hiệu lực; không chỉ xóa dữ liệu bên dưới modal. Vé hủy và số tiền hoàn chỉ được mô tả là chưa xác nhận khi thiếu settlement proof.

## 5. Kiểm thử thực tế và giới hạn

- Baseline: **144 tests PASS**. Baseline xanh chưa bắt các lỗi giao dịch nêu trên.
- Sau tích hợp, lần chạy full suite trước nhóm search/raw-status cuối: **233 tests PASS** (`../mobile-full-tests-r3.log`).
- Review độc lập cuối: **64 tests/probes PASS**, gồm VietQR positive amount với cấu hình public fixture, guest→login, amount mismatch và QR/session security. Đây là component/HTTP fixture, không phải ngân hàng thật.
- Vòng 1 tại `a266508`: QA độc lập chạy đủ **format 143 files/0 changed, analyze sạch, 236 tests PASS, debug APK PASS**. APK 157917305 bytes; SHA256 `727297B65738620783BD53C0064637838336F41B538E877483381B152B27BD29`. Đây là bản trước vòng hoàn thiện 2, không gán kết quả này cho source mới.
- AUTH-03: **29 tests/probes PASS** trong review độc lập (4 probe ngoài repo + 7 regression mới + 18 auth/profile hiện có). Báo cáo `security-review/AUTH-03-REVIEW.md`; không thay đổi mật khẩu tài khoản thật.
- Sau tích hợp AUTH-03 + FE-03 + BP-03 tại `c1a47f0`, parent chạy toàn bộ `flutter test --no-pub`: **278 PASS** (log `../mobile-qa-evidence/completion-integration-tests-pre-review.log`). Chưa thay kết quả này cho gate sau bản sửa review cuối.
- Review FE-03 vòng 1 bắt **2 P1** mà 20 tests feature chưa bắt: QR modal snapshot còn hiển thị sau đổi phiên/xóa token; cancelled detail khẳng định tiền đã hoàn khi chưa có proof. Ba widget probe độc lập tái hiện FAIL tại `f50b230`; giữ nguyên log/probe. Sau bản sửa `0a58e3f`, **cả 3 probe gốc không đổi đều PASS**, cộng 3 probe độc lập mới và 25 FE regression thành **31 PASS**. Không còn P0/P1 đã xác nhận trong phạm vi được review; không gán kết luận này cho provider/device chưa kiểm tra.
- Review BP-03 tại `c1a47f0`: **20 tests/probes PASS** (5 probe độc lập ngoài repo + 15 pricing regression); không còn P0/P1 xác nhận trong phần quote/eligibility/zero-total được review. Bao gồm đổi session khi quote đang chạy, RemoveVoucher trước response FREE, contact mất hợp lệ, zero-total chưa settled, currency/financial fields sai. Không xem fixture settlement là ngân hàng thật.
- Backend `8b33925`: Prisma generate + Nest build **PASS**. API live local: health/routes/operators/search/trip detail/seats **200**; protected guest calls **401**; ngày sai **400**. Dữ liệu chuyến hiện có dùng ngày 2099; tìm ngày gần hiện tại trả rỗng hợp lệ. QA không tạo tài khoản/đơn/thanh toán/hold live.
- QA-02 bổ sung kiểm thử giữ ghế thật (không tạo booking/payment/account): trip 187, ghế 3294, tạo hold **201**, inventory `DANG_GIU`, giữ trùng **409 SEAT_UNAVAILABLE**, release trong `finally` **200**, inventory trở lại `TRONG`; mọi trạng thái ghế khác được giữ nguyên. Capability chỉ giữ trong bộ nhớ và được che trong bằng chứng.
- Báo giá live cho cả trip 149/187 trả **404**; suy luận từ source là không có biểu giá áp dụng cho các chuyến tương lai hiện có. Không chỉnh fare/seed để ép PASS. Quote rỗng ghế trả **400** đúng validation; chưa chứng minh được giá Decimal hoặc nhánh mã khuyến mãi live vì 404 xảy ra trước. Đây là blocker dữ liệu/cấu hình local cho booking E2E, tách khỏi kiểm thử HTTP fixture.
- QA-02 chạy lại `prisma migrate status`: **exit 0, 30 migrations, database up to date**. Runtime cũ đã dừng; QA khởi động lại API test mode, session `79456`, PID `28604`.
- Các probe API local chạy trong `NODE_ENV=test` để tránh payment-expiry/refund worker; existing seat stale cleanup vẫn có lịch chạy. Không xem môi trường này là production. PID/session chỉ là snapshot; QA kiểm tra lại trong lúc build cuối thấy listener 4000 không còn chạy, nên bằng chứng GET/hold thành công không được trình bày là cam kết runtime luôn hoạt động.
- Quality gate cuối do QA chạy độc lập đã đạt đủ bốn bước (section 10). Các lần fail ban đầu được giữ nguyên log: đường dẫn generated `build` làm format `.` lỗi; fixture cũ coi unknown status là pending; không bỏ qua hoặc nới gate.
- Không có Android device/AVD. Flutter integration-named tests trong dự án là component fixtures; không đổi tên chúng thành device E2E.

## 6. Database và cấu hình

Người dùng đã xác nhận sao lưu rồi migrate. Backup local: `../mobile-qa-evidence/backups/vexgo-before-develop-8b33925.sql`, **763005 bytes**, SHA256 `4C190D0F34932845001F2E25955E94D717CFC8A7EFA48C53A9211F5B61C4A981`.

`prisma migrate deploy` exit **0**, áp dụng sáu migration đã có trong develop; không reset/seed, không xóa lịch sử migration chat riêng. Migration promotion chuyển dữ liệu cũ sang `LEGACY_UNCONFIGURED` đúng như nội dung đã xin quyết định. Xem `BACKEND_DATABASE_UPGRADE_REVIEW.md` và `../mobile-qa-evidence/backend-migrate-deploy.log`.

Tài khoản nhận VietQR public trong cấu hình web đã được đối chiếu bằng chuỗi với `SEPAY_ACCOUNT_NUMBER` của Backend. Chỉ ba public receiving-account fields và `DEMO_MODE=false` được đưa vào `.dart_tool/vietqr-defines.json` (gitignored), không sao chép webhook secret. APK dùng `--dart-define-from-file=.dart_tool/vietqr-defines.json`. Máy Android thật cần ADB reverse port 4000 hoặc API_BASE_URL phù hợp.

## 7. Task ledger và việc còn lại

| Task | Status | Acceptance / bằng chứng |
|---|---|---|
| API-01 | DONE | Audit + re-audit latest dev; live GET probes |
| BP-01 | DONE trong phạm vi component | Staged IDs, full tickets, no duplicate/fake success; regressions và independent review |
| BP-02 | DONE trong phạm vi component | Clock/resume/hold race/release/max-seat tests |
| FE-01 | DONE trong phạm vi component | Profile hydrate + session isolation + route cleanup |
| FE-02 | DONE trong phạm vi component | OTP/error/retry/nullable fields/read/review tests |
| NET-01 | DONE trong phạm vi component | Concurrent refresh, terminal/transient error, storage failure, logout/account switch probes |
| SEARCH-01 | DONE trong phạm vi component | Async ordering regression + honest date prices/policy; vòng 1 có đủ gate |
| QA-01 | DONE | Format/analyze/236 tests/debug APK PASS; device E2E BLOCKED |
| SEC-01 | DONE | Independent reviewer reports no remaining confirmed P0/P1 within reviewed scope |
| FE-03 | DONE trong phạm vi component | Sửa QR/refund tại `0a58e3f`, 46 scoped tests; review lại cùng 3 probe gốc và nhóm 31 tests PASS |
| AUTH-03 | DONE trong phạm vi component | 7 regression + review độc lập 29 PASS |
| BP-03 | DONE trong phạm vi component | `c1a47f0`; 15 regression, suite tích hợp 278 PASS và review độc lập 20 PASS |
| QA-02 | DONE cho mandatory gates | Runtime hold/migration PASS, quote local 404; final format/analyze/283 tests/APK PASS; device/provider E2E chưa xác minh |
| SEC-02 | DONE | Hai P1 được sửa trong 1 vòng; 3 probe gốc cùng 3 probe mới +25 FE regression PASS, financial source hashes giữ nguyên so với review BP |
| DOC-01 | DONE | Final matrix, task states, findings, 77-file source manifest, commits, four gates and readiness recorded |

Lead cần xác nhận/phân công các bước còn lại: production wallet providers; API/client idempotency recovery; durable guest checkout recovery qua app restart; live auth/OTP/booking/provider/device E2E; membership redemption/push/localization/biometric và nội dung chính sách đầy đủ. Guest lookup UI, search paging/detail và password API đã được triển khai trong vòng 2; không tiếp tục đánh dấu những mục này là Backend chưa hỗ trợ.

## 8. Đánh giá

**NOT READY FOR MERGE đối với mục tiêu hoàn thiện toàn bộ ứng dụng.** Các P0/P1 đã xác nhận trong phạm vi bản sửa đã được xử lý và reviewer kiểm tra độc lập, nhưng chưa có device/provider E2E và còn các mục PARTIAL/BLOCKED nêu trong matrix. Kết quả quality gate build/test không tự biến các mục này thành COMPLETE. Không merge, deploy hoặc tự resolve review threads.

## 9. Commits và danh sách file

Các commit triển khai kể từ baseline:

- `51040ae` — refresh rotation/session races.
- `ca42017` — regression refresh/replay/logout/account switch.
- `313d588` — tích hợp booking/payment agent.
- `4cb1d78` — tích hợp auth/profile/notifications agent.
- `80849c1` — latest-dev guest/VietQR, transaction/security fixes, search và test contracts.
- `47e34d3` — truyền danh sách vé qua success route, không gom chỉnh sửa tìm kiếm của người dùng vào commit.
- `a266508` — assertion unknown payment status theo contract fail-closed.
- `feab302` — đổi mật khẩu qua Backend, BLoC/repository/datasource và regression.
- `c9682d7` — ẩn thông tin/hành vi membership chưa cấu hình trong Real profile.
- `f50b230` — tích hợp search đủ pages, fresh trip/ticket detail và guest lookup.
- `c1a47f0` — tích hợp quote/khuyến mãi thật và zero-total recovery.
- `372bc6d` — chỉ hiển thị badge xác thực theo boolean thật trong hồ sơ.
- `0a58e3f` — QR modal/card theo vòng đời phiên/reader và thông báo hoàn tiền chưa xác nhận.
- `a7fba6f` — chốt riêng bốn thay đổi search/navigation có sẵn, nội dung khớp patch đã kiểm thử.

Danh sách file implementation/regression: [MOBILE_CHANGED_FILES.md](MOBILE_CHANGED_FILES.md). Vòng implementation có 74 file; sau commit riêng bốn thay đổi search/navigation có sẵn, tổng cộng 77 file source/regression khác baseline (routes xuất hiện ở cả hai nhóm). Tài liệu/bằng chứng được liệt kê riêng; không commit source Backend, SQL backup, cấu hình bí mật hoặc APK.

## 10. Quality gate cuối — source 0a58e3f và bốn thay đổi có sẵn

QA độc lập đã hoàn tất bốn gate. Lần format đầu gặp lại `PathNotFoundException` khi duyệt thư mục build sinh ra, đã giữ log thất bại. Sau khi reviewer dùng xong test assets, QA dùng `flutter clean`, `flutter pub get --enforce-lockfile` và khôi phục cấu hình public VietQR, không sửa source hoặc nâng dependency để né gate.

| Lệnh đã thực thi | Kết quả cuối | Exit |
|---|---|---:|
| `dart format --output=none --set-exit-if-changed .` | PASS: 150 files, 0 changed | 0 |
| `flutter analyze` | PASS: No issues found | 0 |
| `flutter test` | PASS: 283 tests | 0 |
| `flutter build apk --debug --dart-define-from-file=.dart_tool/vietqr-defines.json` | PASS: Gradle 195.3 giây | 0 |

Kotlin daemon incremental cache báo lỗi đường dẫn C:/D:, sau đó build fallback tự phục hồi và kết thúc exit 0; giữ nguyên log, không chỉnh Gradle/settings để bỏ qua lỗi.

APK cuối: `build/app/outputs/flutter-apk/app-debug.apk`; bản sao ổn định `../mobile-qa-evidence/final-round2/app-debug-final.apk`; **157963377 bytes**. SHA256: **`189C493BB9F7ACE3BCB738002DAF11682294D53E09301658898B30D1B05F8E21`**.

QA xác minh bốn thay đổi có sẵn byte-identical trước/sau: patch SHA256 `09BCE155D78C2BC4350E1456091DED68628BA2438BF5EC3D5F7C782CA30A6EF1`. Patch lưu ngoài repository tại `../mobile-qa-evidence/final-round2/original-user-diff.patch`.

Báo cáo QA: `../mobile-qa-evidence/final-round2/QA_FINAL_REPORT.md`; runtime hold/migration: `../mobile-qa-evidence/qa02/QA02_LIVE_REPORT.md`. Final source/security hashes và review: `C:/Users/HP/.codex/visualizations/2026/10/18/01a14ddf-2d2f-7903-beba-a6d51b96f7ff/security-review/FINAL-0a58e3f-REVIEW.md`.

API local không còn listener ở kiểm tra cuối của QA. Orchestrator thử khởi động Node nền bằng `Start-Process -WindowStyle Hidden`; bộ kiểm duyệt tự động từ chối trước thực thi với lý do `blocked by policy`, không cung cấp chi tiết thêm. Không thử lách chính sách hoặc báo runtime đang chạy. Điều này không thay đổi kết quả Mobile gates; các probe live trước đó vẫn là bằng chứng lịch sử, không phải E2E hiện tại. Không có Android device/AVD, không chuyển khoản thật hoặc giả lập webhook để tạo bằng chứng thanh toán.

## 11. Bàn giao PR #5 cho Lead review

Xem [PR5_REVIEW_HANDOFF.md](PR5_REVIEW_HANDOFF.md) để đối chiếu sáu thread đang mở với source/test mới, kết quả trên commit sạch và điều kiện merge. Người dùng đã cho phép push cập nhật PR hiện có; không merge và không resolve thread thay Lead. Kết luận cho toàn bộ ứng dụng vẫn **NOT READY FOR MERGE**; việc gửi review không đồng nghĩa đã xác minh device/provider E2E.
