# Tài liệu Bàn giao — UI Chat Realtime Hỗ trợ Khách hàng (`SupportChatScreen`)

**Ngày cập nhật**: 28/10/2026
**Worktree**: `vexgo_support_chat_ui_worktree`
**Branch**: `feature/mobile-support-chat-ui`
**Base commit (HEAD)**: `7a726fa8451778f42d352c3d054b1b26ec61e572`
**Baseline tests**: 365/365 → UI đợt 1: 382/382 → sửa F01/F02: 384/384 → **sửa R01/R02 từ re-review: 387/387 tests qua**. Mục 8 là implementation và kết quả mới nhất; các mục trước lưu snapshot của Agent.

---

## 1. Phạm vi Triển khai & Mục tiêu Thiết kế

1. **Chuẩn hóa Design System (`DiscoveryTheme`)**:
   - Sử dụng thống nhất hệ thống design token của VexGo (`DiscoveryColors`, `DiscoveryTextStyles`, `AppDimensions`).
   - Tông màu thương hiệu Trust Blue (`DiscoveryColors.primary`), điểm nhấn Energy Orange (`DiscoveryColors.secondary`), bề mặt `DiscoveryColors.surface`, nền trung tính `DiscoveryColors.background`.
   - Typography font `VexGoJakarta` (Plus Jakarta Sans) hiển thị rõ nét, tương phản đạt chuẩn WCAG AAA/AA, chống tràn và cắt méo chữ.
   - Thử nghiệm ma trận responsive trên các profile màn hình:
     - 390×844 chữ 1.0x (chuẩn điện thoại hiện đại).
     - 320×740 chữ 2.0x (màn hẹp, font siêu lớn người già/trợ năng, kế thừa qua overlay route).
     - 640×360 landscape chữ 2.0x kèm bàn phím ảo (viewInsets 160dp).

2. **Các file triển khai chính trong nhiệm vụ UI**:
   - `lib/features/user/support_chat/presentation/screens/support_chat_screen.dart`: Màn hình điều phối Chat chính. Quản lý trạng thái phiên, lifecycle foreground/background, `PopScope` điều hướng phân cấp (transcript -> company picker -> conversation list), scroll listener & `_queueVisibleRead()`, banner trạng thái kết nối lại và lỗi. Tự động thích ứng kích thước compact khi chiều cao khả dụng thấp hoặc bàn phím mở trong landscape.
   - `lib/features/user/support_chat/presentation/widgets/support_chat_conversation_card.dart`: Thẻ hiển thị hội thoại hiện đại. Avatar nhà xe tròn, tên nhà xe 2 dòng, badge trạng thái bo góc mềm mại xếp dọc an toàn, preview tin nhắn 2 dòng, icon chevron điều hướng.
   - `lib/features/user/support_chat/presentation/widgets/support_chat_message_bubble.dart`: Bong bóng chat tin nhắn. Phân loại chuẩn xác: Khách hàng (bên phải, nền xanh nhạt `primaryLight`, viền mềm, bo góc đuôi tin nhắn), Nhân viên (bên trái, nền trắng, viền nhẹ, huy hiệu "Nhân viên hỗ trợ" với text flexible chống tràn), Hệ thống (ở giữa, nền xám trung tính). Giữ `SelectableText`, nhãn `[Hình ảnh]`, giờ địa phương `HH:mm`, trạng thái gửi ("Đang gửi…", "Đã gửi", "Đã đọc", "Chưa xác nhận gửi" kèm nút "Thử gửi lại").
   - `lib/features/user/support_chat/presentation/widgets/support_chat_composer.dart`: Thanh soạn thảo tin nhắn docking/floating. Hỗ trợ chế độ `isDense` khi màn hình thấp hoặc bàn phím mở trong landscape; ô nhập văn bản bo góc pill (18–22dp), hỗ trợ multiline, nút gửi chuẩn tooltip "Gửi tin nhắn".
   - `lib/core/design/discovery_theme.dart`, `assets/fonts/PlusJakartaSans.ttf`, `assets/fonts/PlusJakartaSans-OFL.txt`: Tái sử dụng từ commit `774450a`, đăng ký scoped font `VexGoJakarta` trong `pubspec.yaml`.
   - `test/support_chat_ui_comprehensive_test.dart`: Bộ 19 ca kiểm thử hồi quy UI toàn diện bao phủ toàn bộ các nhóm yêu cầu nghiệm thu và 2 probe xác minh F01, F02 từ review độc lập.

---

## 2. Chi tiết Kiến trúc Giao diện & Hành vi Người dùng

### 2.1. Danh sách Hội thoại & Chọn Nhà xe (`Conversation List & Company Picker`)
- **Header & Tác vụ**:
  - Tiêu đề ngắn gọn: *"Chat với nhà xe"*, bỏ AppBar đỏ cao, sử dụng nền trắng thanh lịch với đường kẻ phân cách tinh tế.
  - Nút CTA nổi bật *"Hội thoại mới"* (`FloatingActionButton.extended`) với icon `Icons.add_comment_outlined` và màu Trust Blue, đặt với khoảng cách đệm an toàn không che lấp hàng cuối của danh sách.
- **Thẻ Hội thoại (`SupportChatConversationCard`)**:
  - Tên nhà xe hiển thị tối đa 2 dòng, không crop méo.
  - Badge trạng thái trực quan:
    - *Chờ tiếp nhận*: Nền cam nhạt, chữ và icon cam `warningDark`.
    - *Đang hỗ trợ*: Nền xanh nhạt, chữ và icon xanh `primary`.
    - *Đã kết thúc*: Nền xám nhạt, chữ và icon xám `neutral600`.
  - Preview tin nhắn gần nhất tối đa 2 dòng, tự động cắt bằng dấu ba chấm.
  - Tuyệt đối không bịa số unread giả, dấu chấm chưa đọc hoặc ảnh nhân viên giả do model backend hiện tại chưa hỗ trợ.
- **Tải thêm & Làm mới**:
  - Kéo để làm mới (`RefreshIndicator`) gọi `cubit.loadConversations()`.
  - Nút *"Tải thêm hội thoại"* hiển thị khi `state.hasMore == true`, khóa tương tác khi đang loading.
- **Bộ chọn Nhà xe (`Company Picker`)**:
  - Hiển thị danh sách nhà xe thực tế từ `cubit.companies()`.
  - Khóa tap tạo trùng khi `state.creating == true`.
  - Cho phép mở hoặc tiếp tục hội thoại sẵn có một cách mượt mà.

---

### 2.2. Khung chat Transcript & Bong bóng Tin nhắn (`SupportChatMessageBubble`)
- **Phân loại tin nhắn**:
  - *Khách hàng (Tin của tôi)*: Căn phải, nền `DiscoveryColors.primaryLight`, viền xanh nhẹ `0.2 alpha`, bo góc 16dp với góc dưới phải 4dp tạo hiệu ứng bong bóng thoại hiện đại.
  - *Nhân viên hỗ trợ*: Căn trái, nền trắng `DiscoveryColors.surface`, viền `neutral200`, bóng đổ nhẹ, phía trên có nhãn *"Nhân viên hỗ trợ"* bọc `Flexible` chống tràn.
  - *Hệ thống*: Căn giữa, nền xám nhạt `neutral100`, chữ `neutral700`, gọn gàng, không bị nhầm lẫn với tin nhắn của nhân viên.
- **Nội dung & Khả năng truy cập**:
  - Sử dụng `SelectableText` cho phép sao chép nội dung văn bản.
  - Tin nhắn hình ảnh hiển thị tiền tố `[Hình ảnh] [nội dung]`.
  - Không tự ý linkify hay mở URL ngoài phạm vi an toàn.
- **Trạng thái gửi & Dấu thời gian**:
  - Giờ hiển thị theo định dạng `HH:mm` múi giờ thiết bị địa phương (`toLocal()`).
  - Trạng thái tin nhắn khách hàng:
    - `ChatDelivery.sending`: Hiển thị *"Đang gửi…"*.
    - `ChatDelivery.sent`: Hiển thị *"Đã gửi"*; chỉ khi `message.read == true` mới hiển thị *"Đã đọc"*.
    - `ChatDelivery.failed`: Hiển thị copy an toàn *"Chưa xác nhận gửi"*, kèm nút bấm *"Thử gửi lại"* gọi `cubit.retry(message)`.
  - Dòng trạng thái được bọc trong `Wrap` chống tràn ngang 100% trên màn hẹp 320dp và font 2.0x.

---

### 2.3. Thanh Soạn thảo & Điều hướng (`SupportChatComposer`)
- **Thanh nhập liệu (`chat-composer`)**:
  - Giữ nguyên `ValueKey('chat-composer')` trên `TextField`.
  - Giới hạn 2000 ký tự theo contract backend, co giãn tự động từ 1 đến 5 dòng (1 đến 2 dòng khi `isDense`).
  - Gợi ý: *"Nhắn tin cho nhà xe…"*.
  - Nút gửi hình tròn với kích thước cảm ứng chuẩn >= 48dp (40dp khi `isDense`), icon `Icons.send_rounded`, tooltip *"Gửi tin nhắn"*.
  - Bỏ qua các chuỗi rỗng hoặc toàn khoảng trắng; tự động xóa draft và cuộn xuống cuối sau khi gửi thành công.
- **Xác nhận Kết thúc Hội thoại (F01 Fix)**:
  - Nút *"Kết thúc hội thoại"* trên AppBar (icon `Icons.stop_circle_outlined` màu đỏ).
  - Khối xác nhận inline an toàn: *"Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó."*
  - Hàng nút tác vụ sử dụng `OverflowBar(alignment: MainAxisAlignment.end, overflowAlignment: OverflowBarAlignment.end, spacing: 8, overflowSpacing: 8)`: tự động chuyển sang xếp dọc khi màn hình hẹp 320dp với text scale 2.0x, triệt tiêu 100% lỗi tràn 67px.
  - Khi hội thoại đã kết thúc (`DA_DONG` hoặc `!canSend`), composer tự động ẩn đi và thay bằng thông báo hướng dẫn mở hội thoại mới.

---

### 2.4. Khắc phục Thích ứng Chiều cao Hạn chế & Bàn phím Mở Landscape (F02 Fix)
- Khi xoay ngang màn hình (640×360) và mở bàn phím ảo (`viewInsets.bottom = 160dp`), chiều cao khả dụng của cửa sổ chỉ còn 200dp.
- `SupportChatScreen` tự động phát hiện `isShort`:
  - `AppBar.toolbarHeight` chuyển sang `44dp` nhỏ gọn, title và subtitle hiển thị súc tích.
  - Reconnect banner chuyển sang chế độ compact: đệm dọc 3dp, giới hạn 1 dòng kèm dấu ba chấm.
  - `SupportChatComposer` kích hoạt `isDense: true`: đệm dọc 2dp, `TextField` đệm dọc 6dp, nút gửi 40dp.
  - Vùng tin nhắn `Expanded` giữ được tối thiểu 87dp không gian hiển thị và cuộn mượt mà.
  - Nút "Gửi tin nhắn" luôn nằm trọn vẹn trong vùng hiển thị khả dụng (`dy <= 200dp`), triệt tiêu hoàn toàn lỗi tràn 28px phía dưới.

---

## 3. Bảo toàn Tuyệt đối 7 Invariants Cốt lõi của Module Chat

1. **Giao thức & Xác thực**: Giữ nguyên cơ chế REST qua `ApiClient` authenticated và Socket.IO client qua namespace `/chat`, chỉ kích hoạt sẵn sàng sau handshake `support.connected`. Giữ session epoch và foreground connection generation.
2. **Tính định danh của Tin nhắn**: Giữ nguyên `clientMessageId` qua các pha optimistic, ACK, broadcast, REST fallback và explicit retry.
3. **Đồng bộ Lịch sử & Reconnect**: Bảo toàn cơ chế nối tiếp nhiều trang lịch sử khi kết nối lại (`_historyWatermark`), không làm mất tin nhắn cũ.
4. **Cơ chế Đánh dấu Đã đọc Khắt khe (Visible Read)**: Giữ nguyên `_viewportKey`, `_messageKeys` và thuật toán giao cắt khung nhìn `_queueVisibleRead()`. Chỉ gửi yêu cầu `markRead` cho tin nhắn đến có ID máy chủ thật sự nằm trong khung nhìn hiển thị khi màn hình đang ở top và app foreground. Không bao giờ gửi danh sách ID rỗng.
5. **Cô lập Dữ liệu Phiên & Bản thảo**: Khi đăng xuất hoặc chuyển phiên tài khoản, toàn bộ dữ liệu tin nhắn và bản thảo nhập liệu trong composer được xóa sạch (`_composer.clear()`, `_messageKeys.clear()`). Late HTTP/ACK không bị rò rỉ sang phiên mới.
6. **Quản lý Vòng đời (Lifecycle)**: Tự động ngắt kết nối khi chuyển background/rời màn hình, tái đồng bộ khi quay lại foreground. Rebuild widget không tạo socket mới hay gọi kích hoạt lặp vô hạn.
7. **Trạng thái Đóng & An toàn Fail-Closed**: Thao tác đóng hội thoại là single-flight; trạng thái không xác định mặc định khóa gửi tin (fail-closed).

---

## 4. Chi tiết Bộ Kiểm thử Hồi quy Toàn diện (`support_chat_ui_comprehensive_test.dart`)

Bộ kiểm thử mới gồm 19 test cases bao phủ trọn vẹn 5 nhóm chức năng UI & Responsive:

| STT | Nhóm kiểm thử | Tên Test Case | Kết quả |
| :---: | :--- | :--- | :---: |
| 1 | Guest & Login Gate | Guest / unauthenticated view renders greeting, login CTA, and no conversation cards | **PASS** |
| 2 | Guest & Login Gate | Demo mode renders online-service requirement | **PASS** |
| 3 | List & Picker | Empty conversation list displays empty state message and new conversation CTA | **PASS** |
| 4 | List & Picker | Conversation list renders cards with long company name, 2-line preview, and status badge without overflow | **PASS** |
| 5 | List & Picker | Pagination triggers loadConversations(more: true) when tapping load more | **PASS** |
| 6 | List & Picker | Company picker displays companies, taps to start conversation, and closes picker | **PASS** |
| 7 | Transcript & Bubble | Transcript renders own message, staff message with badge, and system message | **PASS** |
| 8 | Transcript & Bubble | Image message type displays [Hình ảnh] prefix correctly | **PASS** |
| 9 | Transcript & Bubble | Sending status displays "Đang gửi…" and failed status displays "Chưa xác nhận gửi" with retry button | **PASS** |
| 10 | Transcript & Bubble | Load older messages button appears when hasOlder is true and triggers fetch | **PASS** |
| 11 | Realtime & Session | Typing indicator displays "Nhân viên đang nhập…" when staff is typing | **PASS** |
| 12 | Realtime & Session | Reconnect banner appears when socket is disconnected | **PASS** |
| 13 | Realtime & Session | Confirm close banner appears on stop action, cancel dismisses, and confirm dispatches close | **PASS** |
| 14 | Responsive Matrix | Standard phone (390x844, 1.0x text scale) renders conversation list and transcript cleanly | **PASS** |
| 15 | Responsive Matrix | Compact narrow phone (320x740, 2.0x text scale) renders without RenderFlex overflow | **PASS** |
| 16 | F01 Review Probe | close confirmation fits 320dp at text scale 2 without overflow | **PASS** |
| 17 | F02 Review Probe | landscape transcript remains usable with actual 160dp keyboard inset at text scale 2 | **PASS** |
| 18 | Responsive Matrix | Landscape phone with open keyboard (640x360, 2.0x text scale) renders without overflow | **PASS** |
| 19 | Responsive Matrix | Composer preserves draft across orientation change (320x740 -> 640x360) | **PASS** |

---

## 5. Báo cáo Kết quả Quality Gates

1. **Kiểm tra Định dạng (`dart format`)**:
   ```bash
   dart format --output=none --set-exit-if-changed lib/features/user/support_chat/ test/support_chat_ui_comprehensive_test.dart
   ```
   - **Kết quả**: 0 files changed — Đạt chuẩn 100%.

2. **Phân tích Tĩnh (`flutter analyze`)**:
   ```bash
   flutter analyze --no-pub
   ```
   - **Kết quả**: `No issues found!` (0 errors, 0 warnings, 0 lints).

3. **Kiểm tra Hồi quy Cục bộ (`Targeted Tests`)**:
   ```bash
   flutter test test/support_chat_widget_test.dart test/support_chat_regression_test.dart test/support_chat_ui_comprehensive_test.dart
   ```
   - **Kết quả**: **58/58 tests qua (100% PASS)**:
     - `support_chat_regression_test.dart`: 34 tests PASS.
     - `support_chat_widget_test.dart`: 5 tests PASS.
     - `support_chat_ui_comprehensive_test.dart`: 19 tests PASS.

4. **Kiểm tra Toàn bộ Ứng dụng (`Full Test Suite`)**:
   ```bash
   flutter test
   ```
   - **Kết quả**: **384/384 tests qua (100% PASS)** — Không phát sinh bất kỳ lỗi hồi quy nào trên toàn codebase hiện tại của worktree.

5. **Kiểm tra Trắng Git (`git diff --check`)**:
   - **Kết quả**: Hoàn toàn sạch, không có trailing whitespace hay conflict markers.

---

## 6. Danh sách Tệp Thay đổi & Tạo mới

- [`pubspec.yaml`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/pubspec.yaml)
- [`lib/core/design/discovery_theme.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/lib/core/design/discovery_theme.dart)
- [`assets/fonts/PlusJakartaSans.ttf`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/assets/fonts/PlusJakartaSans.ttf)
- [`assets/fonts/PlusJakartaSans-OFL.txt`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/assets/fonts/PlusJakartaSans-OFL.txt)
- [`lib/features/user/support_chat/presentation/screens/support_chat_screen.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/lib/features/user/support_chat/presentation/screens/support_chat_screen.dart)
- [`lib/features/user/support_chat/presentation/widgets/support_chat_conversation_card.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/lib/features/user/support_chat/presentation/widgets/support_chat_conversation_card.dart)
- [`lib/features/user/support_chat/presentation/widgets/support_chat_message_bubble.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/lib/features/user/support_chat/presentation/widgets/support_chat_message_bubble.dart)
- [`lib/features/user/support_chat/presentation/widgets/support_chat_composer.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/lib/features/user/support_chat/presentation/widgets/support_chat_composer.dart)
- [`test/support_chat_ui_comprehensive_test.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/test/support_chat_ui_comprehensive_test.dart)
- [`docs/MOBILE_SUPPORT_CHAT_UI.md`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_support_chat_ui_worktree/docs/MOBILE_SUPPORT_CHAT_UI.md)

---

## 7. Bảng Tổng hợp Xử lý 2 Phát hiện Review Độc lập (F01 & F02)

| Mã | Mức độ | Hiện tượng trước sửa đổi | Giải pháp kỹ thuật đã áp dụng | Kết quả kiểm chứng |
| :---: | :---: | :--- | :--- | :---: |
| **F01** | **P2 (Responsive)** | Hàng nút xác nhận kết thúc hội thoại nằm trong `Row` cứng, gây tràn ngang 67px tại 320×740 với font PlusJakartaSans và text scale 2.0x. | Thay `Row` bằng `OverflowBar(alignment: MainAxisAlignment.end, overflowAlignment: OverflowBarAlignment.end, spacing: 8, overflowSpacing: 8)` cho phép tự động xếp dọc nút khi không gian ngang bị hạn chế. | Probe #16 **PASS**; 0 pixel overflow trên màn 320dp với font 2.0x; cả hai nút "Giữ hội thoại" và "Kết thúc" đều có thể chạm tới và hoạt động chính xác. |
| **F02** | **P2 (Responsive)** | Khi xoay ngang 640×360 và mở bàn phím ảo (`viewInsets.bottom = 160dp`) kèm text scale 2.0x và reconnect banner, `Column` bị tràn 28px phía dưới do các khối cố định vượt quá chiều cao còn lại. | Phát hiện trạng thái `isShort`: thu gọn `AppBar.toolbarHeight = 44`, banner kết nối lại padding dọc 3dp và `maxLines: 1`, composer kích hoạt `isDense: true` thu nhỏ padding và icon. Sửa helper test bỏ override cứng kích thước 390x844 để phản ánh đúng `viewInsets` thực tế. | Probe #17 **PASS**; 0 pixel overflow phía dưới; `getBottomRight(sendButton).dy <= 200` đảm bảo toàn bộ composer nằm gọn trên bàn phím ảo. |

## 8. Sửa nốt R01/R02 từ re-review — 28/10/2026

Mục này thay thế các mô tả dense40dp và confirmation luôn chèn vào Column ở snapshot trước.

- **R01:** Confirmation chuyển vào vùng nội dung Expanded với SingleChildScrollView, cùng IndexedStack giữ transcript/scroll state. Không chèn thêm một khối cao cố định phía trên transcript. Composer được giữ state nhưng ẩn trong lúc xác nhận; gửi typing(false) khi mở xác nhận và unfocus editor để keyboard có thể đóng tự nhiên. Vẫn xử lý được khi inset keyboard160dp chưa kịp rút.
- Chọn “Giữ hội thoại” giữ cùng EditableTextState/controller, draft và selection; khôi phục focus sau frame khi composer hiện lại, chỉ nếu vẫn cùng session/conversation. Chọn “Kết thúc” mới gọi closeConversation. Không thay contract hay Cubit/repository/socket.
- Transcript bị confirmation che không được markRead: thêm guard _confirmClose vào visible-read callback. Khi quay lại transcript, các incoming message thực sự hiện trong viewport mới được đánh dấu đọc.
- **R02:** Icon có thể nhỏ trong dense nhưng vùng bấm gửi luôn48x48dp. Composer nhận FocusNode ổn định từ screen; không thu nhỏ hit target để làm test overflow xanh.
- Thêm3test vào support_chat_ui_comprehensive_test.dart (hiện22test): giữ hội thoại với draft/focus/read boundary; xác nhận đóng trên landscape+keyboard; target48dp ở normal/dense.

Kết quả thực chạy sau sửa:

| Gate | Kết quả |
|---|---|
| Full suite: flutter test --no-pub --timeout30s | **387/387 PASS**,19giây |
| Analyzer | **No issues found**,9.7giây |
| Format chat/design/test Agent |7files/0changed |
| git diff --check | Không lỗi whitespace; cảnh báoLF→CRLF ởpubspec |
| Bốn probe gốc | **4/4 PASS** |
| Probe keyboard+close, probe dense target | **Đều PASS**; cả hai harness gồm4ca dùng lại đều4/4PASS |

Logs ở workspace cha: mobile-qa-evidence/chat-ui-final-full.log, chat-ui-final-keyboard.log, chat-ui-independent-probes-final.log, chat-ui-rereview-keyboard-close-probe-final.log và chat-ui-rereview-dense-target-probe-final.log. Các harness dùng font PlusJakarta thật và keyboard inset mô phỏng. File probe tạm đã xóa khỏi checkout.

Lúc hoàn thiện test có ca khôi phục focus chưa qua do requestFocus trước khi Visibility cho editor nhận focus trở lại; đã sửa bằng callback sau frame có guard session/conversation, test giữ draft/focus và full suite hiện qua. Không nới assertion để làm xanh.

Giới hạn: widget/AuthBloc/Cubit thật với FakeRepository/FakeSocket, chưa build/cài APK, chưa kiểm thử Android hoặc Mobile↔Admin/API/DB thật trong lượt sửa. Các khẳng định contrast/WCAG của snapshot Agent chưa được xác nhận bằng audit riêng. Chưa commit/push/tạo PR; giữ nhánh chat UI riêng để điều phối viên tích hợp sau.
