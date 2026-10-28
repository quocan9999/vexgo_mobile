# Tài liệu Bàn giao — UI Bottom Sheet Hủy vé & Thông tin hoàn tiền (`CancelTicketSheet` & `GuestCancelTicketSheet`)

**Ngày cập nhật**: 28/10/2026  
**Worktree**: `vexgo_cancellation_ui_worktree`  
**Branch**: `feature/mobile-cancellation-ui`  
**Base branch**: `feature/mobile-ticket-detail-ui`  
**Base commit (HEAD)**: `774450aac36e105d5b0463a0a9a87d57788bf73a`  
**Baseline tests**: 472/472 -> Agent 485/485 -> **Sau review/sửa: 498/498 tests PASS**. Kết quả mới nhất và phạm vi sửa logic Mobile tại mục 5.

---

## 1. Phạm vi triển khai & Mục tiêu thiết kế

1. **Chuẩn hóa Design System (`DiscoveryTheme`)**:
   - Sử dụng thống nhất hệ thống design token của VexGo (`DiscoveryColors`, `DiscoveryTextStyles`, `AppDimensions`).
   - Giao diện Bottom Sheet hiện đại, sạch sẽ với bo góc trên 20dp, thanh kéo drag handle, padding an toàn với `SafeArea` và `MediaQuery.viewInsets.bottom` (chống che khuất khi mở bàn phím).
   - Kiểm thử responsive nghiêm ngặt trên 3 profile màn hình:
     - **390×844 chữ 1x** (chuẩn điện thoại portrait).
     - **320×740 chữ 2x** (màn hình hẹp, font siêu lớn trợ năng).
     - **640×360 landscape chữ 2x** (xoay ngang màn hình kèm bàn phím ảo).
     - **Kết quả**: Không có bất kỳ lỗi `RenderFlex overflow` nào.

2. **Các file triển khai chính**:
   - `lib/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart`: Bottom sheet xác nhận hủy vé cho người dùng đã đăng nhập (authenticated flow) kết nối với `MyTicketsBloc`.
   - `lib/features/user/my_bookings/presentation/widgets/guest_cancel_ticket_sheet.dart`: Bottom sheet xác nhận hủy vé cho khách tra cứu công khai (guest lookup flow) kết nối với `TicketReadCubit`.
   - `.github/workflows/flutter-ci.yml`: Bổ sung nhánh `feature/mobile-ticket-detail-ui` vào danh sách `pull_request.branches`.
   - `test/cancellation_ui_comprehensive_test.dart`: 13 ca cho các luồng UI được liệt kê; không bao phủ mọi race. Sau review bổ sung `test/cancellation_lifecycle_regression_test.dart` và sửa wiring/state Mobile tại mục 5.

---

## 2. Chi tiết các thành phần UI (Component Architecture)

### 2.1. Bottom Sheet Hủy vé Người dùng Đăng nhập (`CancelTicketSheet`)

- **Header & Nhận diện**:
  - Drag handle trung tâm màu xám nhẹ bo tròn.
  - Icon tròn nhận diện trạng thái: đỏ nhạt `DiscoveryColors.errorLight` với icon hủy khi vé được phép hủy; cam nhạt `DiscoveryColors.warningLight` khi không đủ điều kiện hủy.
  - Tiêu đề: `"Hủy vé xe"` hoặc `"Không thể hủy vé"`.
  - Phụ đề hiển thị mã vé thực tế (`Mã vé: <ticketCode>`).
  - Nút đóng nhanh `IconButton(Icons.close_rounded)`.

- **Dải tóm tắt vé (`Ticket Summary Strip`)**:
  - Hiển thị thông tin hành trình: Nhà xe · Loại xe, tuyến đường từ A đến B, thời gian khởi hành (giờ · ngày).
  - Sử dụng `Wrap` linh hoạt cho dải giờ khởi hành và số ghế (`Chỗ ngồi: A01, A02`), đảm bảo không tràn màn hình khi font phóng to 2x trên màn hình hẹp.

- **Trường hợp vé Đủ điều kiện hủy (`canCancel == true`)**:
  - **Bảng phân tích tài chính (`Refund Breakdown Card`)**:
    - `Tiền vé đã thanh toán`: Giá vé gốc định dạng tiền tệ VNĐ chuẩn (`CurrencyFormatter.format`).
    - `Phí hủy theo quy định (<rate>%)`: Số tiền phí hủy khấu trừ hiển thị màu đỏ có dấu trừ (`- <amount>`). Sử dụng giá trị từ `CancellationQuote` thật của API backend.
    - Đường phân cách viền mỏng `DiscoveryColors.divider`.
    - `Số tiền dự kiến hoàn lại`: Giá trị dự kiến từ quote, in đậm; không phải xác nhận tiền đã được hoàn.
    - **Dải lưu ý tài chính bắt buộc**: Khung ghi chú nền xám nhạt với icon `info_outline` và câu chữ minh bạch:
      > *"Hủy vé không đồng nghĩa đã hoàn tiền ngay. Trạng thái hoàn tiền cần được đối soát và xử lý theo chính sách hoàn tiền."*
    - **Đáp ứng giao diện hẹp (`LayoutBuilder`)**: Tự động chuyển đổi từ bố cục 2 cột sang dạng cột xếp tầng khi bề rộng thẻ < 260dp, loại bỏ triệt để lỗi tràn pixel.
  - **Lựa chọn lý do hủy vé**:
    - Tiêu đề: `"Chọn lý do hủy vé"`.
    - Sử dụng `RadioGroup<String>` theo SDK đang khóa của dự án, hỗ trợ 5 tùy chọn:
      1. Thay đổi kế hoạch cá nhân (mặc định)
      2. Đặt nhầm ngày/giờ khởi hành
      3. Tìm được phương tiện di chuyển khác
      4. Lý do sức khỏe / việc bận đột xuất
      5. Khác
    - Khi chọn `"Khác"`: Hiển thị ô `TextField` nhập lý do cụ thể (giới hạn 250 ký tự, `onChanged` kích hoạt cập nhật trạng thái nút bấm ngay lập tức). Nút xác nhận chỉ sáng lên khi người dùng đã nhập nội dung.
  - **Hộp kiểm đồng ý điều khoản (`CheckboxListTile`)**:
    - Nội dung ghi rõ mức phí và số tiền trừ: *"Tôi đồng ý hủy vé và chấp nhận mức khấu trừ phí hủy <rate>% (<amount>) nêu trên."*.
    - Bắt buộc phải tích chọn mới kích hoạt nút xác nhận hủy vé.
  - **Thanh nút bấm hành động (`Actions Dock`)**:
    - Nút Primary `FilledButton`: Nền đỏ `DiscoveryColors.error`, chữ trắng `"Xác nhận hủy vé"`. Hiển thị `CircularProgressIndicator` khi đang gửi yêu cầu (`_isSubmitting`).
    - Nút Outlined: `"Giữ vé / Đóng"` giúp người dùng an tâm quay lại xem vé.
    - `LayoutBuilder`: Tự động xếp chồng dọc 2 nút khi chiều rộng < 280dp.

- **Trường hợp vé Không đủ điều kiện hủy (`canCancel == false`)**:
  - Khung cảnh báo màu đỏ nhạt với viền đỏ mờ.
  - Tiêu đề: `"Không đủ điều kiện hủy vé trực tuyến"`.
  - Nội dung lý do: Lấy trực tiếp từ `quote.reason` của API backend, không chứa bất kỳ nhãn kỹ thuật nội bộ nào (`sub_uc_huy_ve`), không có mốc 12h giả định, không có hotline bịa đặt (`1900 6067`).
  - Ghi chú thời gian khởi hành thực tế của chuyến xe.
  - **Hộp liên hệ nhà xe/tài xế**: Nếu vé có số điện thoại (`ticket.driverPhone`), hiển thị hộp thông tin liên hệ và nút Outlined `"Sao chép"`. Khi bấm, copy số điện thoại vào clipboard và hiển thị SnackBar xác nhận *"Đã sao chép số liên hệ."*.
  - Nút bấm `"Đã hiểu và Đóng"` chiếm trọn chiều rộng để đóng sheet.

---

### 2.2. Bottom Sheet Hủy vé Khách vãng lai (`GuestCancelTicketSheet`)

- **Bảo toàn Contract và Tương thích Ngược**:
  - Lắng nghe trạng thái từ `TicketReadCubit` qua `BlocBuilder`.
  - Giữ vững contract chuỗi kiểm thử đã cam kết trong `test/lead_round_20261019_test.dart`:
    - Dòng hiển thị phí: `'Phí hủy (${(quote.cancelFeeRate * 100).round()}%)'`
    - Dòng số tiền hoàn: `'Số tiền dự kiến hoàn'`
    - Lưu ý: `'Hủy vé không đồng nghĩa đã hoàn tiền. Trạng thái hoàn tiền cần được xác nhận riêng.'`
    - Nút bấm: `FilledButton` với text `'Xác nhận hủy vé'`.
    - Checkbox: `CheckboxListTile` với title `'Tôi đồng ý hủy vé với mức phí trên.'`.
- **Nâng cấp Design System & UX**:
  - Áp dụng nền và bo góc `DiscoveryColors.surface` bo tròn 20dp.
  - Áp dụng `Wrap` cho thông tin hành trình tránh tràn chữ.
  - Ô nhập lý do hủy vé `TextField` với `maxLength: 500`.
  - Xử lý trạng thái bận (`busy` = `cancelling` hoặc `loading`): hiển thị `CircularProgressIndicator`, vô hiệu hóa checkbox và nút xác nhận.
  - Xử lý thông báo lỗi nếu có `state.error`: hiển thị khung đỏ cảnh báo.
  - Khi `!canCancel`: Hiển thị lý do không đủ điều kiện từ `quote.reason` và ẩn phần xác nhận phí hủy.

---

## 3. Các Ràng buộc & Bất biến Bảo mật (Invariants)

1. **Phân tách luồng dữ liệu minh bạch**:
   - Luồng Authenticated: Dispatch `CancelTicketEvent(ticketId, reason, refundAmount)` lên `MyTicketsBloc`.
   - Luồng Guest: Gọi `reader.cancelTicket(quotedTicket, reason)` qua `TicketReadCubit`, đối soát với phiên tra cứu công khai hiện hành.
2. **Không commit cam kết hoàn tiền tức thì**:
   - Toàn bộ copywriting khẳng định rõ quy trình hủy vé chỉ là bước khởi đầu đối soát hoàn tiền, không phát sinh thông điệp sai lệch "Đã hoàn tiền thành công vào tài khoản".
3. **Phòng chống tấn công và lỗi giao diện**:
   - Double-tap guard: Chặn triệt để duplicate submission khi người dùng chạm nhanh nhiều lần liên tiếp.
   - Session safety: Hủy luồng gửi mutation nếu phiên đăng nhập thay đổi hoặc tài khoản bị đăng xuất.
   - Keyboard insets handling: Toàn bộ sheet bọc trong `SingleChildScrollView` với padding `MediaQuery.viewInsets.bottom`, cho phép cuộn mượt mà ngay cả khi bàn phím ảo bật lên trên màn hình ngang.

---

## 4. Kết quả Kiểm thử & Quality Gates

Các kết quả mục 4 là snapshot Agent trước review. Mục 5 ghi kết quả sau sửa mới nhất.

### 4.1. Bộ test Hồi quy Toàn diện Mới (`test/cancellation_ui_comprehensive_test.dart`)
Bao gồm 13 test cases (100% PASS):
- `Displays full ticket summary, quote fee breakdown and disclaimer`: Kiểm tra đầy đủ thông tin vé, bảng phí quote, lưu ý tài chính, trạng thái ban đầu của nút bấm.
- `Submits cancellation with selected reason after ticking policy checkbox`: Kiểm tra chọn lý do hủy thường, tick đồng ý, submit dispatch đúng `CancelTicketEvent`, đóng sheet.
- `Selecting "Khác" requires typing custom text before submit is enabled`: Kiểm tra chọn lý do "Khác", hiện ô nhập, chặn submit khi ô trống, mở submit khi đã nhập chữ, gửi đúng lý do nhập vào.
- `Ineligible ticket displays real quote reason, no fake hotline/12h rules, copies phone`: Kiểm tra giao diện vé không đủ điều kiện, lý do API thật, không nhãn kỹ thuật, sao chép SĐT vào clipboard, SnackBar phản hồi.
- `Double-tap guard prevents duplicate submission events`: Kiểm tra chạm nhanh 2 lần chỉ phát sinh duy nhất 1 sự kiện.
- `Tapping "Giữ vé / Đóng" dismisses sheet without submit`: Kiểm tra nút đóng đóng sheet và không phát sinh sự kiện mutation.
- `Guest cancellation shows quote fee rate, agreement enables FilledButton, submits cleanly`: Kiểm tra đầy đủ contract luồng khách, checkbox mở nút, gọi API hủy thành công.
- `Guest sheet renders loading/busy indicator during cancelling`: Kiểm tra hiển thị loading khi cubit đang bận.
- `Guest sheet renders error alert when state.error is present`: Kiểm tra hiển thị khung báo lỗi mạng/API.
- `Guest sheet displays ineligible reason when canCancel is false`: Kiểm tra hiển thị lý do không đủ điều kiện đối với khách.
- `Standard phone (390x844, 1.0x text scale) renders cleanly`: Không có overflow trên thiết bị chuẩn.
- `Compact phone (320x740, 2.0x text scale) wraps buttons without overflow`: Không có overflow trên màn hình hẹp với cỡ chữ người cao tuổi (2.0x).
- `Landscape phone with open keyboard (640x360, 2.0x text scale) scrolls without overflow`: Không có overflow trên màn hình ngang kèm bàn phím ảo.

### 4.2. Toàn bộ Quality Gates
- **`dart format --output=none --set-exit-if-changed lib/ test/`**: **PASS** (181 files kiểm tra, 0 files thay đổi định dạng).
- **`flutter analyze --no-pub`**: **PASS** (0 issues found).
- **`git diff --check`**: **PASS** (Không có whitespace conflict).
- **`flutter test` (Full Test Suite)**: **485/485 TESTS PASS** (Tăng từ 472 lên 485 tests).

## 5. Independent review và sửa logic Mobile — 28/10/2026

Review tái hiện 4 lỗi bằng repository fixture/BLoC/UI thật: authenticated sheet đóng khi POST còn pending; guest đóng khi hủy thất bại; sheet còn mã vé cũ sau đổi tài khoản; phí người dùng đồng ý 10% nhưng cache đổi sang 20% làm POST gửi 20%. Các lỗi này phần lớn kế thừa wiring cũ, không phải đều là regression UI do Agent tạo.

Đã sửa:

- Authenticated sheet đọc lại vé/quote trước hiển thị, chỉ dùng phí/refund từ quote hợp lệ. Không dùng công thức 12h hoặc tỷ lệ mặc định khi quote thiếu. Quote thay đổi cần xem và đồng ý lại; lựa chọn ban đầu được gắn vào event cùng session generation/token version.
- MyTicketsBloc có trạng thái cancellation riêng (submitting/succeeded/failed/uncertain), single-flight và kiểm tra quote mới trước POST. Không đóng sheet trước kết quả. Phản hồi phải đúng id/code/status và các số tiền/rate/phạm vi vé nếu được cung cấp; generic `success:true` không đủ để xác nhận hủy.
- Timeout/lỗi mạng/response không khớp sau POST được đối soát bằng GET; nếu chưa xác minh thì giữ trạng thái uncertain, không gửi lại mutation. Nút Kiểm tra trạng thái chỉ đọc API. Trạng thái này được giữ theo vé trong vòng đời Bloc/reader và qua đóng/mở lại sheet cùng Bloc, không phải lưu trữ phục hồi sau restart.
- Guest chỉ đóng sheet sau kết quả vé đã hủy được đọc lại; giữ lỗi để xử lý. Consent gắn với quote; đổi quote hoặc thất bại phải đồng ý lại. Kết quả POST chưa rõ chặn retry mutation, kể cả khi reader tra cứu vé khác rồi quay lại.
- Sheet authenticated và các callback ràng buộc phiên; logout/login thay phiên thu hồi nội dung cũ, queued event/response cũ không cập nhật tài khoản mới. TokenStorage thêm stream sessionChanges riêng; refresh rotation giữ nguyên phiên. Các listener invalidations cũ giữ nguyên semantics.
- TicketReadCubit thu hồi payload hiện tại khi owner cache xác nhận HUY, chặn fresh read cũ paid/upcoming khôi phục QR; đọc mới đúng trạng thái cancelled vẫn hiển thị chi tiết bình thường.
- Copy trạng thái hoàn tiền luôn phân biệt dự kiến/đang xử lý với đã settled. Mã lý do Backend như LESS_THAN_4_HOURS được chuyển thành thông báo tiếng Việt, không bịa hotline/thời hạn. Nút liên hệ chỉ sao chép số thực có.

Phạm vi ngoài hai file UI được mở rộng có chủ đích để sửa lỗi vừa review: cancellation_policy.dart, MyTicketsBloc/event/state, TicketReadCubit, TokenStorage. Không sửa Backend, schema/DB, quote contract hoặc QR payload. Nhánh Demo cũ của BLoC vẫn được giữ để tương thích mode đó; luồng Real dùng xác minh quote/response mới.

Kiểm chứng:

- **13 test hồi quy mới** tại `test/cancellation_lifecycle_regression_test.dart`; **50/50 focused tests PASS** cùng các suite cancellation/lead cũ.
- **498/498 full tests PASS** (27 giây), analyzer **No issues found** (8.6 giây), format toàn checkout **184 files / 0 thay đổi**, diff check không lỗi whitespace (có cảnh báo LF→CRLF).
- Hai fixture cũ trong phase2/lead review được cập nhật ID số, quote và response id/code/HUY đúng Backend; vẫn kiểm tra payload phí và kết quả thiếu refundAmount chưa khẳng định settled. Không nới gate để giữ fake `success:true`.
- Evidence: `../mobile-qa-evidence/cancellation-independent-review/before-tests.log`, `before-probes.log`, `focused-tests.log`, `fixed-full-tests.log`, `fixed-analyze.log`.
- Chưa hủy vé thật, chưa Android/live API E2E, chưa build/cài APK mới. Chưa commit/push/mở PR/merge.
