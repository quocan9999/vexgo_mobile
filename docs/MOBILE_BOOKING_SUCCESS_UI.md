# Tài liệu Bàn giao — UI Màn hình Đặt vé thành công (`BookingSuccessScreen`)

**Ngày cập nhật**: 27/10/2026  
**Worktree**: `vexgo_booking_success_ui_worktree`  
**Branch**: `feature/mobile-booking-success-ui`  
**Base HEAD**: `410ba93890766c600fd65e2823037b16f914c14a` (Nền PR #12)  
**Baseline tests**: 418 tests passing -> **Hiện tại: 425 tests passing (+7 new comprehensive regression tests)**  

---

## 1. Phạm vi triển khai & Mục tiêu thiết kế

1. **Bản chất màn hình**: `BookingSuccessScreen` là màn hình receipt / xác nhận vé điện tử đích sau khi thanh toán thành công. Màn hình **không phải là Step 7** (không hiển thị Stepper, không có nút back tương tác quay lại luồng đặt vé hay thanh toán).
2. **Quy chuẩn Design System**:
   - Sử dụng thống nhất bộ token từ `DiscoveryTheme` (`DiscoveryColors`, `DiscoveryTextStyles`, `DiscoveryButton`).
   - AppBar màu đỏ thương hiệu VexGo (`DiscoveryColors.header` - `#DC2626`) với nút đóng `X` điều hướng về Trang chủ (`/`).
   - Font chữ hệ thống `VexGoJakarta` bo tròn, độ tương phản cao, bo góc tiêu chuẩn (`AppDimensions.radiusLg` 16dp, `radiusMd` 12dp), viền nhạt `DiscoveryColors.neutral200` và đổ bóng nhẹ `Offset(0, 2)`.
   - Responsive hoàn hảo trên các kích thước màn hình hẹp (`320dp`, `360dp`), màn hình tiêu chuẩn (`390dp`), và chế độ chữ lớn (`textScaler: 1.5x - 2.0x`).

---

## 2. Chi tiết các thành phần UI (Component Architecture)

### Card 1: Header Xác nhận thành công & Banner Mã vé chính
- **Icon Trạng thái**: Badge tròn xanh lá `DiscoveryColors.successLight` với icon `Icons.check_circle_rounded` màu `DiscoveryColors.success` (42dp).
- **Tiêu đề**: "Đặt vé thành công!" (`DiscoveryTextStyles.h2`, `DiscoveryColors.successDark`).
- **Nội dung xác nhận**: "Giao dịch đã được hệ thống xác nhận" — văn phong trung tính, chuẩn xác; tuyệt đối không cam kết sai về việc đã gửi email/SMS hay xuất hóa đơn GTGT.
- **Banner Mã vé chính**: Nền xám dịu `DiscoveryColors.neutral50`, viền `DiscoveryColors.neutral200`. Hiển thị mã vé chính `ticket.ticketCode` (softWrap cho các mã dài $>40$ ký tự) kèm nút `IconButton` sao chép (touch target $\ge 48\times 48\text{dp}$, tooltip `'Sao chép mã vé'`, feedback qua `SnackBar: 'Đã sao chép mã vé vào bộ nhớ tạm!'`).

### Card 2: Tóm tắt chuyến đi (Trip & Route Summary)
- **Header Hãng xe & Trạng thái**: Icon xe bus `Icons.directions_bus_rounded`, tên nhà xe `trip.operatorName` (`DiscoveryTextStyles.titleMedium`), badge "Đã thanh toán" nằm riêng biệt phía dưới tránh overflow trên màn hẹp.
- **Tuyến đường & Loại xe**: `${trip.fromCity} -> ${trip.toCity} • ${trip.vehicleType}`.
- **Chi tiết hành trình**:
  - `Ngày đi`: `${trip.departureDate}`
  - `Giờ đón`: `${trip.departureTime}`
  - `Điểm đón`: `${trip.pickupPoint} (${trip.pickupAddress})`
  - `Điểm trả`: `${trip.dropoffPoint} (${trip.dropoffAddress})`
  - `Chỗ ngồi`: Hiển thị gộp tất cả các ghế của toàn bộ danh sách vé `widget.tickets` (ví dụ: `A01, A02, A03`), không chỉ hiển thị ghế của vé đầu tiên.
  - `Giá tiền / Số lượng vé`: Đối với đơn 1 vé, hiển thị `Tổng thanh toán: <finalAmount>`. Đối với đơn nhiều vé, hiển thị `Số lượng vé: <count> vé`, giá chi tiết từng vé hiển thị riêng ở từng thẻ vé bên dưới để tránh hiểu nhầm số tiền của vé đầu là tổng đơn.

### Card 3: Danh sách vé điện tử & Mã lên xe QR (Boarding Pass Cards)
- Hỗ trợ đầy đủ trường hợp 1 vé hoặc nhiều vé (`widget.tickets`).
- Với mỗi vé đã phát hành:
  - Header thẻ vé: Badge ghế `Ghế <seats>` (`DiscoveryColors.primaryLight`, icon `event_seat_rounded`) và số tiền của vé đó (`CurrencyFormatter.format(issued.finalAmount)`).
  - **Mã QR lên xe**: Chỉ render khi `issued.canShowQr == true`.
    - Payload chuẩn: `VEXGO:<ticketCode>:<ticketId>`.
    - Kích thước: `160dp`, nền trắng sạch, mã hiển thị rõ nét.
    - Chú thích: `${issued.ticketCode} • ${issued.seats.join(', ')}` và hướng dẫn "Đưa mã này cho phụ xe khi lên xe".
  - **Trạng thái chưa đủ điều kiện QR**: Khi `issued.canShowQr == false` (chưa thanh toán, đã hủy, vé lỗi...), hiển thị banner thông báo trung tính: "Chưa có xác nhận thanh toán để hiển thị mã lên xe."

### Card 4: Thông tin hành khách (Passenger Contact Recap)
- Chuẩn hóa đồng bộ theo cấu trúc 2 cột của Step 5: Cột nhãn cố định `90dp`, cột giá trị mở rộng tự do, không bao giờ gây `RenderFlex` overflow trên 320dp - 390dp.
  - `Họ tên`: `${ticket.passenger.fullName}`
  - `Số điện thoại`: `${ticket.passenger.phone}`
  - `Email`: `${ticket.passenger.email}` (chỉ hiển thị khi có dữ liệu, không có nhãn/text mang tính cam kết email).

### Card 5: Hướng dẫn tra cứu (Information Notice)
- Container màu xanh dịu `DiscoveryColors.primaryLight` viền nhẹ.
- Icon `Icons.confirmation_number_outlined`.
- Nội dung: "Lưu mã vé và số điện thoại đã dùng khi đặt vé để tra cứu vé không cần đăng nhập."

### Dock CTAs (Điều hướng cuối trang)
- **Primary CTA**: `DiscoveryButton` "Xem vé của tôi" (icon `Icons.confirmation_number_outlined`, màu xanh `DiscoveryColors.primary`) -> điều hướng `context.go('/my-tickets')`.
- **Secondary CTA**: `DiscoveryButton(type: ButtonType.outline)` "Về trang chủ" (icon `Icons.home_rounded`) -> điều hướng `context.go('/')`.
- **PopScope & Leading AppBar**: Chặn pop về màn hình thanh toán trước đó (`canPop: false`), điều hướng an toàn về `/`.

---

## 3. Các bất biến dữ liệu, tài chính & QR (Invariants)

1. **Mã QR lên xe (Boarding QR)**:
   - Là mã định danh hành khách lên xe, hoàn toàn tách biệt với VietQR chuyển khoản ngân hàng.
   - Payload tuân thủ nghiêm ngặt: `VEXGO:<ticketCode>:<ticketId>`.
   - Gate hiển thị: Phải thỏa mãn `issued.canShowQr == true` (xác minh cả trạng thái thanh toán `isPaid` và trạng thái hợp lệ). Tuyệt đối không render QR cho vé cancelled, completed, unknown hoặc thiếu ID.
2. **Multi-ticket Mapping**:
   - Khi `widget.tickets` có nhiều vé, duyệt từng vé và render thẻ vé tương ứng; mỗi vé mang mã vé, ghế và mã QR độc lập. Tuyệt đối không nhân bản mã QR vé đầu cho các vé sau.
3. **Quản lý BLoC & Session**:
   - `AddNewTicketEvent` chỉ được dispatch 1 lần duy nhất trong callback `WidgetsBinding.instance.addPostFrameCallback` ở `initState` kèm kiểm tra `if (!mounted) return;`.
   - Tuyệt đối không dispatch event trong hàm `build` hoặc khi widget rebuild.
4. **Điều hướng an toàn**:
   - Ngăn chặn triệt để việc người dùng bấm Back hệ thống để quay lại màn hình thanh toán, tránh gây hiểu lầm là chưa thanh toán.

---

## 4. Kết quả kiểm thử & Quality Gates

| Kiểm thử / Tiêu chí | Kết quả | Ghi chú |
| --- | --- | --- |
| `dart format` | **PASS** | Đã format sạch sẽ `lib/.../booking_success_screen.dart` và `test/.../booking_success_ui_comprehensive_test.dart`. |
| `flutter analyze --no-pub` | **PASS** | `No issues found! (ran in 5.4s)` — 0 warnings, 0 errors. |
| `booking_success_ui_regression_test.dart` | **5/5 PASS** | Pass toàn bộ test hồi quy hiện hữu: mã dài 320/360dp, copy đầy đủ, textScaler 1.5x. |
| `booking_success_ui_comprehensive_test.dart` | **7/7 PASS** | 7 tests mới bổ sung: Multi-ticket 5 vé, ticket cancelled không QR, navigation callbacks, AddNewTicketEvent 1 lần duy nhất, responsive 390x844 (1x), 320x740 (2x), 640x360 landscape (2x). |
| `booking_integrity_regression_test.dart` | **PASS** | Toàn bộ các guard nghiệp vụ đặt vé nguyên vẹn. |
| `payment_integrity_test.dart` | **PASS** | Các quy tắc an toàn tài chính và thanh toán nguyên vẹn. |
| `my_tickets_flow_test.dart` | **PASS** | Quy trình vé của tôi và lưu vé nguyên vẹn. |
| `phase2_tickets_and_cancellation_test.dart` | **PASS** | Quy trình hủy vé và trạng thái vé nguyên vẹn. |
| **Full Test Suite** | **425/425 PASS** | Vượt qua toàn bộ 425 tests của codebase (tăng từ baseline 418). |
| `git diff --check` | **PASS** | Không có lỗi whitespace hay conflict marker. |
| **Debug APK Build** | **PASS** | `mobile-qa-evidence/booking-success-ui/app-debug-booking-success-ui.apk` (159,310,329 bytes, SHA256: `14B4D695DC14E4BEB90B36D76364554A82780D5F8F011FCA3E54862F6E3EABB6`). |

---

## 5. Điểm lưu ý bàn giao & Quy định

- **Nhánh & Base**: Triển khai độc lập trên branch `feature/mobile-booking-success-ui` (base PR #12). Không đè hay xóa mã nguồn của các worktree khác.
- **Tuân thủ quy định**: **Không tự ý commit, push hoặc merge.** Đợi review và phê duyệt từ lead / điều phối viên.

## 6. Sửa sau independent review — 27/10/2026

- R1: Success screen giữ token session version và MyTicketsBloc session generation lúc mở. Khi đăng nhập thay phiên, đăng xuất hoặc thay phiên cache, màn chuyển sang thông báo trung tính, không giữ QR/PII hay nút sao chép cũ. Refresh rotation giữ nguyên phiên nên không đóng vé.
- TokenStorage thêm `sessionChanges` riêng cho login/logout; không thay semantics `sessionInvalidations` đang dùng bởi các luồng khác.
- Callback post-frame chỉ thêm vé khi màn còn mounted và phiên còn đúng. `AddNewTicketEvent` nhận generation/version tùy chọn; handler kiểm tra lại lúc xử lý để chặn event cũ đã nằm trong hàng đợi. Các caller cũ vẫn tương thích.
- R2: Từng thẻ boarding QR có nút sao chép mã riêng, dùng chính `issued.ticketCode`, vùng bấm tối thiểu 48dp. Callback kiểm tra phiên trước khi gửi clipboard và trước khi hiện feedback; không hiện feedback trễ sau khi đổi phiên. Nội dung clipboard đã sao chép trước khi đổi phiên không bị xóa tự động.
- Thêm `test/booking_success_session_test.dart`: 7 ca cho đổi token/cache session, logout, refresh rotation, clipboard vé thứ hai, callback clipboard trễ và event thêm vé cũ.
- Full suite đã thực thi: **432/432 PASS** (32 giây). Analyzer: **No issues found** (8.7 giây). Format các file sửa: 0 thay đổi. Logs tại `../mobile-qa-evidence/booking-success-independent-review/fixed-full-tests.log` và `fixed-analyze.log`.
- Đây là kiểm thử tự động với fixture; chưa xác nhận Android thật/live payment E2E sau sửa. APK/hash trong mục 4 thuộc bản Agent trước sửa, chưa chứa các sửa tại mục này.
- Chưa commit/push/merge; Backend, DB và contract QR không thay đổi.
