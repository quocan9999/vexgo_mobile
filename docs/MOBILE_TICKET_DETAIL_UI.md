# Tài liệu Bàn giao — UI Màn hình Chi tiết vé (`TicketDetailScreen` & `BoardingPassCard`)

**Ngày cập nhật**: 28/10/2026
**Worktree**: `vexgo_ticket_detail_ui_worktree`
**Branch**: `feature/mobile-ticket-detail-ui`
**Base branch**: `feature/mobile-my-tickets-ui`
**Base commit (HEAD)**: `b85ff1d9b77e004d6cb2ced87e60deb518451ad1`
**Baseline tests**: 451/451 -> Agent 464/464 -> **Sau sửa review: 472/472 tests qua**. Chi tiết kết quả mới nhất tại mục 6.

---

## 1. Phạm vi triển khai & Mục tiêu thiết kế

1. **Chuẩn hóa Design System (`DiscoveryTheme`)**:
   - Sử dụng thống nhất hệ thống design token của VexGo (`DiscoveryColors`, `DiscoveryTextStyles`, `AppDimensions`).
   - Giao diện hiện đại, sạch sẽ, màu sắc nhận diện Trust Blue (`DiscoveryColors.primary`) và Energy Orange (`DiscoveryColors.secondary`), nền trung tính `DiscoveryColors.background`.
   - Đạt chuẩn tương phản, typography font production `VexGoJakarta`, không crop, méo hay vỡ layout.
   - Có kiểm thử responsive trên 3 profile màn hình sau (không đồng nghĩa bao phủ mọi thiết bị):
     - 390×844 chữ 1x (chuẩn điện thoại hiện đại).
     - 320×740 chữ 2x (màn hẹp, font siêu lớn người già/trợ năng).
     - 640×360 landscape chữ 2x (xoay ngang màn hình).

2. **Các file triển khai chính trong nhiệm vụ UI**:
   - `lib/features/user/my_bookings/presentation/screens/ticket_detail_screen.dart`: Màn hình Chi tiết vé với `CustomAppBar`, nút refresh trên header, quản lý vòng đời `TicketReadCubit`, `didUpdateWidget`, khối thông tin liên hệ chuyến đi với nút Outlined sao chép SĐT vào clipboard, thanh tác vụ (Actions dock) theo trạng thái vé.
   - `lib/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart`: Thẻ vé lên xe phong cách vé máy bay (airline boarding pass) dùng chung giữa `TicketDetailScreen` và `GuestTicketLookupPanel`. Phân tách rõ ràng trạng thái hành trình và thanh toán, đường đứt nét kèm vết cắt bán nguyệt hai bên, khối QR lên xe có quiet zone trắng chuẩn mực và cổng điều kiện nghiêm ngặt.
   - `test/ticket_detail_ui_comprehensive_test.dart`: 13 test cho các ca fresh read, QR gates, clipboard bình thường, action buttons, logout, guest compatibility và responsive được liệt kê. Các race refresh/clipboard bổ sung sau review nằm tại mục 6.

3. **Ghi chú về Patch cha kế thừa**:
   - Nhánh kế thừa commit `b85ff1d` (UI Vé của tôi & 12 test Agent/Responsive/Session) và `fd793ba` (bản sửa F02 sơ đồ ghế 4 cột).
   - Toàn bộ các thay đổi trên đã nằm sẵn trong git history cục bộ của worktree; không copy đè hoặc sửa lại các file danh sách/ghế ngồi trong nhiệm vụ này.

---

## 2. Chi tiết các thành phần UI (Component Architecture)

### 2.1. Thẻ vé lên xe phong cách vé máy bay (`BoardingPassCard`)
- **Tầng trên (Upper Section)**:
  - Header: Icon xe bus `DiscoveryColors.primaryLight`, Tên nhà xe (`trip.operatorName`), Loại xe (`trip.vehicleType`).
  - Huy hiệu trạng thái tách biệt:
    - *Trạng thái hành trình*: `Sắp đi` (xanh dương), `Đã đi` (xanh lá), `Đã hủy` (đỏ).
    - *Trạng thái thanh toán* (cho vé sắp đi): `Đã thanh toán` (xanh lá) hoặc `Chưa thanh toán` (cam), phản ánh đúng `ticket.isPaid`.
  - Lộ trình chuyến đi (`Cities Flow`):
    - Điểm đi: Tên thành phố xuất phát, giờ khởi hành (xanh đậm).
    - Icon mũi tên chuyển tiếp tròn ở giữa.
    - Điểm đến: Tên thành phố đến, giờ đến dự kiến (cam đậm).
- **Đường cắt xé vé (Perforated Tear Line)**:
  - Đường đứt nét ở giữa với 2 vết cắt hình bán nguyệt hai bên mép thẻ có màu nền trùng với màu nền trang (`DiscoveryColors.background`), mang lại trải nghiệm vé máy bay thực thụ.
- **Khối QR lên xe (Boarding Pass QR Box)**:
  - **Khi đủ điều kiện (`ticket.canShowQr == true`)**:
    - Hiển thị QR đen trên nền trắng có quiet zone chuẩn mực (`backgroundColor: Colors.white`, padding 6dp, bo góc 8dp).
    - Format mã QR: `VEXGO:<ticketCode>:<ticketId>`.
    - Tiêu đề: `Mã vé: <ticketCode>`, phụ đề icon phóng to: `Chạm để phóng to mã QR`, chú thích: `Dùng mã này khi lên xe tại điểm đón`.
    - Chạm vào mở `TicketQrModal.show(context, ticket, ticketReader: ticketReader)` phóng to toàn màn hình có nút đóng.
  - **Khi không đủ điều kiện (`ticket.canShowQr == false`)**:
    - Tuyệt đối không để lại khoảng trống giả lớn hay hiển thị QR rỗng.
    - Hiển thị card trạng thái ổ khóa tròn tinh tế:
      - Vé chưa thanh toán: *"Chưa có xác nhận thanh toán"*
      - Vé hoàn thành: *"Chuyến đi đã hoàn thành."*
      - Vé hủy: *"Vé đã bị hủy. Mã QR không khả dụng."*
- **Tầng dưới (Lower Section)**:
  - Khối thông số then chốt (3 cột): `Chỗ ngồi` (xanh đậm highlight), `Ngày khởi hành`, `Biển số xe` (nếu có dữ liệu từ backend).
  - Lộ trình đón/trả chi tiết (`Timeline Point`):
    - Điểm đón: Giờ xuất bến + Tên điểm đón + Địa chỉ thực tế từ API.
    - Điểm trả: Giờ đến + Tên điểm trả + Địa chỉ thực tế từ API.
  - Dải thông tin hành khách & thanh toán:
    - `Hành khách`: Họ tên · Số điện thoại
    - `Email nhận vé`: Email (bọc tự động xuống dòng chống tràn)
    - `Thanh toán qua`: Phương thức thanh toán thật
    - `Tổng tiền vé`: Định dạng VND chuẩn (`CurrencyFormatter.format`), màu cam nổi bật (màu xám nếu vé đã hủy).
    - Trường hợp vé hủy: Hiển thị thêm `Số tiền hoàn (chưa xác nhận)` và `Lý do hủy`.

### 2.2. Khối thông tin liên hệ chuyến đi (Contact Card)
- Card bo góc 16dp với viền phân cách nhẹ.
- Header: *"Thông tin liên hệ chuyến đi"*.
- Icon điện thoại bo tròn `DiscoveryColors.primaryLight`.
- Tên liên hệ nhà xe: *"Liên hệ chuyến đi <operatorName>"*.
- Số điện thoại liên hệ từ backend (`ticket.driverPhone`). Nếu backend chưa có, hiển thị *"Nhà xe chưa cung cấp số liên hệ."*.
- Nút Outlined `"Sao chép số"`:
  - Khi bấm, sao chép chính xác số điện thoại vào clipboard (`Clipboard.setData`).
  - Hiển thị SnackBar thông báo: *"Đã sao chép số liên hệ."*.
  - **Bảo toàn nguyên tắc an toàn**: Không đổi nhãn thành "Gọi điện" hay "Gọi ngay" vì ứng dụng không có chức năng gọi trực tiếp.
  - Sử dụng `LayoutBuilder`: Tự động chuyển layout xuống dòng trên màn hình hẹp (320dp chữ 2x) tránh lỗi tràn RenderFlex.

### 2.3. Thanh tác vụ ngữ cảnh (Actions Dock)
- **Vé sắp đi** (`upcoming`) & người dùng đã đăng nhập:
  - Nút Outlined `"Hủy vé"`: Mở bottom sheet `CancelTicketSheet.show`.
  - Nút Primary `"Tìm chuyến khác"`: Điều hướng sang `/search-trips`.
  - Bọc trong `LayoutBuilder` chuyển đổi linh hoạt hàng / cột trên màn hẹp.
- **Vé đã đi** (`completed`) & người dùng đã đăng nhập:
  - Chưa đánh giá: Nút Primary `"Đánh giá chuyến đi"` kèm icon sao mở `ReviewBottomSheet.show`.
  - Đã đánh giá: Card hiển thị `Đã đánh giá • <rating>/5` kèm icon sao vàng và nút `"Đặt lại chuyến xe này"`.
- **Vé đã hủy** (`cancelled`):
  - Banner cảnh báo màu đỏ nhạt giải thích rõ vé đã hủy và tình trạng hoàn tiền chưa xác nhận.
  - Nút `"Tìm vé mới"` điều hướng sang `/search-trips`.

### 2.4. Trạng thái phản hồi (Loading & Error States)
- **Đang tải (Loading)**: `CircularProgressIndicator` màu xanh `DiscoveryColors.primary` căn giữa kèm thông điệp *"Đang tải thông tin vé..."*.
- **Lỗi tải vé (Error)**: Icon cảnh báo đỏ tròn, hiển thị thông điệp lỗi và nút `"Thử lại"` (`_reader.refresh`).
- **Phiên bị hủy (Invalidated)**: Hiển thị cảnh báo phiên đã thay đổi, ẩn nút thử lại và không để lộ PII của tài khoản cũ.

---

## 3. Các bất biến dữ liệu & Bảo mật (Guards & Invariants)

1. **Vòng đời đọc tươi (Fresh Read Lifecycle)**:
   - `widget.initialTicket` chỉ là seed payload ban đầu để gọi đọc lại dữ liệu tươi từ Backend qua `TicketReadCubit..loadTicket(widget.initialTicket)`.
   - Tuyệt đối không fallback render nội dung vé hay QR từ `widget.initialTicket` khi trạng thái cubit đang `loading`, `error`, hoặc `invalidated`.
   - `_TicketDetailScreenState` triển khai `didUpdateWidget` để reload khi nhận ticket mới từ widget cha.
2. **Cổng kiểm soát mã QR (QR Gate)**:
   - Chỉ render `QrImageView` khi `ticket.canShowQr == true` (thỏa mãn cả 4 điều kiện: `isPaid == true`, `status == TicketStatus.upcoming`, `id > 0`, và `ticketCode.isNotEmpty`).
   - Định dạng payload QR: `VEXGO:<ticketCode>:<ticketId>`.
3. **Kiểm tra quyền hạn & Session Protection (`_authorized`)**:
   - `BoardingPassCard` lắng nghe `TokenStorage.sessionInvalidations`, `ticketReader.stream`, `owner.stream`.
   - Khi token version thay đổi hoặc session generation thay đổi (đổi tài khoản / đăng xuất), card lập tức chuyển sang trạng thái vô hiệu hóa:
     `'Phiên đã thay đổi. Vui lòng mở lại thông tin vé.'`
   - Toàn bộ PII, mã vé và QR của tài khoản cũ bị thu hồi ngay lập tức.
4. **Tính tương thích dùng chung (Shared Compatibility)**:
   - `BoardingPassCard` hoạt động tương thích 100% trong `GuestTicketLookupPanel` (tra cứu công khai không cần đăng nhập) cũng như trong `TicketDetailScreen`.

---

## 4. Kết quả kiểm thử & Quality Gates

Kết quả Agent trước independent review. Mục 6 ghi kết quả mới nhất sau sửa.

### 4.1. Bộ test hồi quy toàn diện mới (`test/ticket_detail_ui_comprehensive_test.dart`)
Bao gồm **13 test cases** chuyên biệt:
1. `Navigation payload and fresh read lifecycle renders authoritative data without flashing initial QR`: PASS.
2. `App bar refresh button triggers fresh read from backend`: PASS.
3. `Displays error view and allows retry when read fails`: PASS.
4. `QR Code gate: Shows QR only for upcoming paid tickets`: PASS.
5. `QR Code gate: Hides QR for unpaid, cancelled and completed tickets`: PASS.
6. `Contact phone copies to clipboard and never shows direct call action`: PASS.
7. `Action buttons: Upcoming ticket offers Cancel and Search`: PASS.
8. `Action buttons: Completed ticket offers Review or Rebook`: PASS.
9. `Action buttons: Cancelled ticket displays notice and rebook`: PASS.
10. `Session safety: Invalidates BoardingPassCard when account changes or logout occurs`: PASS.
11. `Shared BoardingPassCard functions smoothly in GuestTicketLookupPanel`: PASS.
12. `Responsive check: 320x740 narrow screen with 2x text scale does not overflow`: PASS.
13. `Responsive check: 640x360 landscape screen with 2x text scale does not overflow`: PASS.

### 4.2. Toàn bộ Quality Gates xác nhận
- **`dart format --output=none --set-exit-if-changed lib/ test/`**:
  `Formatted 179 files (0 changed) in 0.87 seconds` — SẠCH 100%.
- **`flutter analyze --no-pub`**:
  `No issues found! (ran in 3.0s)` — 0 warnings, 0 errors.
- **`flutter test` (Full Suite)**:
  **464/464 tests PASS** (Toàn bộ 100% qua, thời gian chạy 22 giây).
- **`git diff --check`**: Sạch hoàn toàn, không có whitespace lỗi hay conflict markers.

---

## 5. Giới hạn & Điểm lưu ý

- Màn hình sử dụng `TicketReadCubit` hiện hữu của ứng dụng, không sửa đổi contract BLoC/Cubit.
- Nút liên hệ chỉ sao chép số điện thoại vào clipboard, hiển thị thông báo SnackBar chuẩn; không thực hiện cuộc gọi viễn thông trực tiếp.
- `BoardingPassCard` không nhúng stepper đặt vé, không can thiệp vào modal QR (`TicketQrModal`) ngoài việc gọi `TicketQrModal.show`.
- Tuân thủ nghiêm ngặt quy tắc dự án: Không tự ý commit, push, tạo PR hay merge vào nhánh chính.

## 6. Sửa sau independent review — 28/10/2026

- **R1:** BoardingPassCard tách điều kiện phiên khỏi điều kiện fresh read. Token/session thay đổi, owner/reader đóng hoặc reader invalidated vẫn vô hiệu hóa card vĩnh viễn. Loading/failure hoặc object vé mới trong cùng phiên chỉ ẩn payload cũ tạm thời; card chỉ trở lại khi reader loaded và trùng chính object vé được truyền vào. Không render initialTicket fallback.
- Fast refresh không còn latch nhầm `_invalidated`; didUpdateWidget A→B hiện đúng B. Refresh có chờ frame vẫn không lộ vé/QR cũ khi pending; response A trả muộn sau thay phiên vẫn bị chặn. Không sửa Cubit/Backend hoặc payload/gate QR.
- **R2:** Hai layout liên hệ dùng chung `_contactCopyAction`, chụp generation/token version/read state lúc build. Kiểm tra phiên, ticket identity, reader và mounted trước copy và sau await. Callback cũ không copy nếu phiên đã thay; không hiện feedback nếu refresh/thay vé/đóng màn đã làm read state cũ hết hiệu lực. Không xóa clipboard đã được copy hợp lệ trước đó.
- Thêm `test/ticket_detail_lifecycle_regression_test.dart`: 8 ca cho fast refresh, mounted A→B, offline landscape, clipboard sau đổi phiên, hai ca refresh chậm, clipboard sau dispose và callback cũ trước copy.
- **21/21 focused tests PASS**, **472/472 full tests PASS** (23 giây), analyzer **No issues found** (5.0 giây). Sau bổ sung kiểm tra mounted tường minh để analyzer nhận diện async guard, đã chạy lại 21 focused tests; hành vi guard giữ nguyên.
- Evidence: `../mobile-qa-evidence/ticket-detail-independent-review/fixed-focused.log`, `fixed-full-tests.log`, `fixed-analyze.log`.
- Đây là widget/fixture tests với BLoC/Cubit thật và repository fixture; chưa Android/live API/payment E2E, chưa build/cài APK mới. Chưa commit/push/merge.

## 7. Chuẩn bị publish theo yêu cầu người dùng — 28/10/2026

- Người dùng đã yêu cầu tạo PR cho Chi tiết vé. Base là `feature/mobile-my-tickets-ui` tại `b85ff1d`, head là `feature/mobile-ticket-detail-ui`.
- Nhánh nền được push để GitHub có thể so sánh đúng phạm vi; PR Chi tiết vé không gồm lại diff UI danh sách hay F02 của nhánh nền. Phần Vé của tôi chưa được mở PR riêng trong bước này.
- Workflow CI bổ sung base branch `feature/mobile-my-tickets-ui` vào pull_request trigger; giữ nguyên quality/build gates.
- Kiểm tra format toàn checkout trước commit: 181 files, 0 thay đổi. Full suite 472 tests và analyzer sạch như mục 6; chưa xác nhận CI remote hoặc Android thật tại lúc viết phần này.
- Không merge/approve hoặc resolve review thread khi publish.
