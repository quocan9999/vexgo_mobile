# Tài liệu Bàn giao — UI Màn hình Vé của tôi (`MyTicketsScreen` & `TicketSummaryCard`)

**Ngày cập nhật**: 28/10/2026
**Worktree**: `vexgo_my_tickets_ui_worktree`
**Branch**: `feature/mobile-my-tickets-ui`
**Base HEAD**: `f9dacb36002c27ea21dea7a8a7658cd40919dfa2` (Nền PR #13 `feature/mobile-payment-ui`)
**Baseline tests**: 439 tests -> Agent 446 tests -> **Sau sửa review: 451/451 tests qua**. Chi tiết và giới hạn tại mục 7.

---

## 1. Phạm vi triển khai & Mục tiêu thiết kế

1. **Chuẩn hóa Design System (`DiscoveryTheme`)**:
   - Sử dụng thống nhất hệ thống design token của VexGo (`DiscoveryColors`, `DiscoveryTextStyles`, `AppDimensions`).
   - Giao diện hiện đại, sạch sẽ, màu sắc nhận diện Trust Blue (`DiscoveryColors.primary`) và Energy Orange (`DiscoveryColors.secondary`), nền trung tính `DiscoveryColors.background`.
   - Có kiểm thử các viewport 320dp, 390dp và landscape 640×360, chữ 2x; sau review bổ sung keyboard insets và kiểm tra số tiền/vùng bấm. Không coi các ca đã chạy là bằng chứng bao phủ mọi thiết bị.

2. **Các file triển khai chính trong nhiệm vụ UI**:
   - `lib/features/user/my_bookings/presentation/screens/my_tickets_screen.dart`: Tái thiết kế toàn diện màn hình danh sách, thanh tìm kiếm cục bộ, thanh 3 tabs linh hoạt, các trạng thái Loading, Error, Empty (theo tab và theo từ khóa tìm kiếm), và Guest view.
   - `lib/features/user/my_bookings/presentation/widgets/ticket_summary_card.dart`: Tái cấu trúc thẻ vé tóm tắt với phân cấp thị giác rõ ràng, phân biệt trạng thái chuyến đi với trạng thái thanh toán, và các nút hành động (Hủy vé, Đánh giá, Xem chi tiết / Xem vé & QR).
   - `test/my_tickets_ui_comprehensive_test.dart`: 7 bài test cho các ca tương tác, lọc tab, tìm kiếm, điều hướng, logout và responsive được liệt kê; không bao phủ toàn bộ kịch bản.

3. **Ghi chú về Patch kế thừa F02 (Spatial Seat Map)**:
   - Worktree đồng bộ đúng 2 file sửa lỗi F02 (sơ đồ ghế 4 cột) từ `vexgo_payment_ui_worktree`:
     - `lib/features/user/booking/presentation/widgets/spatial_seat_map.dart`
     - `test/seat_four_column_regression_test.dart`
   - Đây là bản sửa hạ tầng sơ đồ ghế kế thừa từ PR #11/#12/#13, **không tính vào thay đổi giao diện của màn Vé của tôi**.

---

## 2. Chi tiết các thành phần UI (Component Architecture)

### 2.1. Thanh tìm kiếm cục bộ (Local Search Bar)
- Tích hợp ô nhập liệu `TextField` với phong cách phẳng bo góc 10dp (`DiscoveryColors.neutral100`).
- Placeholder rõ ràng: *"Nhập mã vé (VXG-...) hoặc SĐT tra cứu..."*.
- Icon kính lúp `Icons.search_rounded` màu `DiscoveryColors.neutral500`.
- Nút `Clear` (`Icons.clear_rounded`) hiển thị khi có ký tự nhập, có tooltip `'Xóa tìm kiếm'` hỗ trợ accessibility. Khi bấm nút, controller và query được xóa sạch, khôi phục lại danh sách vé đầy đủ của tab hiện tại.
- Tìm kiếm hoàn toàn cục bộ trên danh sách vé đã tải (theo mã vé, SĐT, tên nhà xe, thành phố đi/đến); **tuyệt đối không phát sinh API request mới mỗi khi gõ phím**.

### 2.2. Thanh Tab trạng thái chuyến đi (3 Status Tabs Bar)
- 3 Tabs: **Sắp đi** (`TicketStatus.upcoming`), **Đã đi** (`TicketStatus.completed`), **Đã hủy** (`TicketStatus.cancelled`).
- Đặt trong thanh cuộn ngang `SingleChildScrollView(scrollDirection: Axis.horizontal)` với touch target $\ge 44-48\text{dp}$ (`minHeight: 44, minWidth: 90`).
- Huy hiệu số đếm (`count badge`) tự động cập nhật động theo dữ liệu state (`upcomingTickets.length`, `completedTickets.length`, `cancelledTickets.length`).
- Tab được chọn hiển thị nền xanh `DiscoveryColors.primary`, chữ trắng đậm, badge màu trắng trong mờ. Tab chưa chọn có nền `DiscoveryColors.neutral100`, chữ xám đậm.
- Thiết kế đảm bảo không bao giờ bị tràn hàng (`RenderFlex overflowed`) ngay cả khi màn hình hẹp 320dp và phóng to chữ 2x.

### 2.3. Thẻ vé tóm tắt (`TicketSummaryCard`)
- **Header thẻ**: Icon xe bus bo tròn màu `DiscoveryColors.primaryLight`, Tên nhà xe (`trip.operatorName`), Loại xe (`trip.vehicleType`).
- **Phân tách trạng thái chuyến đi và thanh toán**:
  - Huy hiệu hành trình: `Sắp đi` (xanh dương), `Đã đi` (xanh lá), `Đã hủy` (đỏ).
  - Huy hiệu thanh toán (đối với vé sắp đi): `Đã thanh toán` (xanh lá nhạt) hoặc `Chưa thanh toán` (cam nhạt), phản ánh đúng cờ `ticket.isPaid`. Tuyệt đối không suy diễn đã thanh toán từ tab hay ngày đi.
- **Lộ trình & Lịch trình**:
  - Tuyến đường nổi bật: `${trip.fromCity} ➔ ${trip.toCity}` (`DiscoveryTextStyles.h4`, 16dp, w700).
  - Ngày giờ khởi hành: Icon lịch + `${trip.departureTime} · ${trip.departureDate}`.
  - Điểm đón: Chỉ hiển thị khi `trip.pickupPoint` có dữ liệu (`Đón: <pickupPoint> (<pickupAddress>)`). Tuyệt đối không bịa thời gian hay địa điểm đón.
- **Dải thông tin vé (Meta Strip)**: Nền xám dịu `DiscoveryColors.neutral50`, viền `neutral200`, chia 3 cột cân đối:
  - `Mã vé`: Hiển thị `ticket.ticketCode` (hoặc `bookingCode`), chữ đậm.
  - `Ghế`: Danh sách ghế màu xanh `DiscoveryColors.primary`, chữ đậm.
  - `Tổng tiền`: Định dạng tiền VND chuẩn (`CurrencyFormatter.format`), màu cam `DiscoveryColors.secondary` (hoặc màu xám nếu vé đã hủy).
- **Khu vực hủy vé & hoàn tiền**: Khi vé có trạng thái `cancelled`, hiển thị banner đỏ nhạt với lý do hủy (`ticket.cancelReason`) và số tiền hoàn (`ticket.refundAmount`, nếu có) mà không cam kết sai về việc đã hoàn tiền xong nếu chưa xác nhận.
- **Khu vực đánh giá**: Khi vé hoàn thành và đã có đánh giá, hiển thị badge sao vàng kèm rating `X.0 (Đã đánh giá)`.
- **Hàng nút hành động (Actions Dock)**:
  - Nút phụ trái: Nút `Hủy vé` (màu đỏ, chỉ hiện khi `canCancel == true`) hoặc nút `Đánh giá` (màu cam, chỉ hiện khi vé đã đi và chưa đánh giá). Bấm nút mở bottom sheet tương ứng (`CancelTicketSheet` / `ReviewBottomSheet`) và **tuyệt đối không kích hoạt sự kiện bấm card mở chi tiết**.
  - Nút chính phải: Nút `Xem vé & QR` (nếu `canShowQr == true`) hoặc `Xem chi tiết` (nếu chưa có QR hoặc vé đã hủy).
  - Vùng bấm của thẻ vé và nút chính mở trang chi tiết `/ticket-detail` với payload chính xác của vé được bấm.

### 2.4. Các trạng thái phản hồi (Empty / Error / Guest Views)
- **Trạng thái đang tải (Loading)**: `CircularProgressIndicator` màu xanh `DiscoveryColors.primary` căn giữa.
- **Trạng thái lỗi (Error)**: Icon lỗi tròn đỏ nhạt, thông điệp lỗi rõ ràng, nút `Thử lại` và hỗ trợ kéo để làm mới (`RefreshIndicator`).
- **Trạng thái rỗng do từ khóa tìm kiếm (Search Empty)**:
  - Icon `Icons.search_off_rounded`, thông báo: *"Không tìm thấy vé phù hợp với từ khóa '<query>'"*.
  - Nút bấm `Xóa bộ lọc tìm kiếm`: Xóa sạch ô tìm kiếm và khôi phục lại danh sách vé của tab hiện tại. Tuyệt đối không thông báo người dùng chưa có vé khi chỉ là do bộ lọc không khớp.
- **Trạng thái rỗng của từng Tab (Tab Empty)**:
  - Tab Sắp đi: Thông báo *"Chưa có chuyến xe nào sắp đi"* kèm nút CTA `Tìm chuyến ngay` (`context.go('/search-trips')`) và nút `Tải lại`.
  - Tab Đã đi: Thông báo *"Chưa có lịch sử chuyến đi"*.
  - Tab Đã hủy: Thông báo *"Không có vé nào bị hủy"*.
- **Trạng thái khách chưa đăng nhập (Guest View)**:
  - Render `GuestTicketLookupPanel(key: ValueKey(bloc.sessionGeneration))` tra cứu vé công khai bằng mã vé và SĐT.
  - Nút `Đăng nhập để xem tất cả vé` (`context.go('/profile')`).
  - Toàn bộ thanh tab và thanh tìm kiếm vé tài khoản được ẩn đi hoàn toàn, bảo vệ an toàn PII.

---

## 3. Các bất biến dữ liệu, bảo mật & Session (Invariants)

1. **Mapping trạng thái Backend**:
   - Model giữ nguyên 3 trạng thái `TicketStatus`: `upcoming`, `completed`, `cancelled`.
   - Tuyệt đối không tự thêm tab trạng thái mới ngoài hợp đồng hoặc biến đổi vé unknown thành vé hợp lệ.
2. **Session Guards & Đổi tài khoản**:
   - Khi đăng xuất hoặc chuyển tài khoản (`bloc.setSession(null)`): BLoC xóa sạch vé cũ, reset `sessionGeneration`, `requiresLogin` thành `true`.
   - UI lập tức xóa trắng controller tìm kiếm `_searchCtrl.clear()`, ẩn thẻ vé và số đếm cũ, mở `GuestTicketLookupPanel`.
   - Tuyệt đối không để rò rỉ bất kỳ thông tin vé, số điện thoại hay số đếm nào của tài khoản trước sang phiên sau.
3. **Phân quyền hiển thị QR**:
   - Thẻ vé tóm tắt **không render mã QR trực tiếp trên danh sách** (chỉ có nút dẫn tới chi tiết vé).
   - Nút hiển thị nhãn `Xem vé & QR` chỉ khi `ticket.canShowQr == true` (thỏa mãn cả `isPaid`, trạng thái `upcoming`, ID hợp lệ).

---

## 4. Kết quả kiểm thử & Quality Gates

Kết quả Agent trước review; mục 7 là kết quả sau sửa mới nhất.

| Kiểm thử / Tiêu chí | Kết quả | Ghi chú |
| --- | --- | --- |
| `dart format` | **PASS** | Đã format sạch sẽ `my_tickets_screen.dart`, `ticket_summary_card.dart`, `my_tickets_ui_comprehensive_test.dart`. |
| `flutter analyze --no-pub` | **PASS** | `No issues found! (ran in 3.0s)` — 0 warnings, 0 errors. |
| `git diff --check` | **PASS** | Không có lỗi whitespace hay conflict marker. |
| `my_tickets_ui_comprehensive_test.dart` | **7/7 PASS** | 7 tests hồi quy toàn diện: Tab switching, counts, query filtering & clear, card navigation payload, cancel/review separation, empty/error states, account switch PII safety, responsive 390x844 (1x), 320x740 (2x), 640x360 landscape (2x). |
| `my_tickets_flow_test.dart` | **7/7 PASS** | Toàn bộ luồng nghiệp vụ BLoC vé nguyên vẹn. |
| `phase2_tickets_and_cancellation_test.dart` | **5/5 PASS** | Luồng hủy vé và tính phí hủy nguyên vẹn. |
| `review_contract_regression_test.dart` | **22/22 PASS** | Toàn bộ hợp đồng đánh giá và hiển thị nhãn `(Đã đánh giá)` nguyên vẹn. |
| `feature_completion_regression_test.dart` | **25/25 PASS** | Kiểm tra màn hình khách tra cứu và các hợp đồng API nguyên vẹn. |
| **Full Test Suite** | **446/446 PASS** | **100% test toàn bộ dự án vượt qua** (tăng từ baseline 439 tests). |

---

## 5. Artifact Build Debug APK

APK/hash bên dưới là bản Agent trước sửa review; chưa chứa các thay đổi tại mục 7. Chưa build APK mới trong lượt sửa này.

- **Đường dẫn artifact**: `mobile-qa-evidence/my-tickets-ui/app-debug-my-tickets-ui.apk`
- **Kích thước**: `159,343,941 bytes` (~151.96 MB)
- **SHA-256**: `C30EF9E67E58BA175D13D283B9091D9DF78A26B5CF9AADBFF70CD763846802F1`
- **Manifest metadata**: `mobile-qa-evidence/my-tickets-ui/manifest.json`
- **Lưu ý kiểm thử**: APK được build thành công ở Real Mode trên môi trường Gradle sạch; chưa cài đặt hoặc chạy thử trên thiết bị Android vật lý.

---

## 6. Tuân thủ quy tắc bàn giao

- Toàn bộ mã nguồn và artifacts nằm trong worktree `vexgo_my_tickets_ui_worktree` trên nhánh `feature/mobile-my-tickets-ui`.
- **Tuyệt đối không tự ý `git commit`, `git push`, tạo PR hay merge vào nhánh chính**.
- Bàn giao đầy đủ mã nguồn và tài liệu cho Điều phối viên nghiệm thu trước khi thực hiện các bước tiếp theo.

## 7. Sửa sau independent review — 28/10/2026

- **R1:** Thanh tab cố định phía trên vùng tìm kiếm/danh sách; search nằm trong header cuộn của `NestedScrollView`. Khi bàn phím chiếm chiều cao landscape, có thể cuộn search để dành chỗ cho danh sách. Giữ một hierarchy khi resize, không mất controller/focus/selection; danh sách không nằm dưới vùng bấm tab. Không đổi BLoC/API hay luồng guest.
- **R2:** Dải thông tin tách giá xuống hàng riêng rộng toàn card. Giá, mã và ghế được wrap thay vì cắt dấu ba chấm trong meta strip; không thu nhỏ font để ép số tiền vào cột.
- **R3:** Tab có chiều cao tối thiểu 48dp và selected/button semantics.
- Các mô tả meta strip ba cột và tab 44dp ở mục 2 thuộc thiết kế Agent trước review, được thay bằng bố cục/48dp ở mục này.
- Thêm `test/my_tickets_ui_responsive_regression_test.dart`: 5 ca cho landscape keyboard (bao gồm bounds danh sách so với tab), giá đầy đủ 320dp chữ 2x, tap target, response tài khoản cũ về muộn và controller/focus/selection khi resize.
- **12/12 focused tests PASS**; **451/451 full tests PASS** (23 giây); analyzer **No issues found** (11.6 giây); format 0 thay đổi, diff check không lỗi whitespace.
- Logs: `../mobile-qa-evidence/my-tickets-independent-review/fixed-focused.log`, `fixed-full-tests.log`, `fixed-analyze.log`.
- Chưa build/cài APK mới, chưa chạy Android thật hoặc live API E2E. Các sửa F02 kế thừa và thay đổi Agent có sẵn được giữ nguyên.

## 8. Chốt nền để triển khai Chi tiết vé — 28/10/2026

Người dùng đã đồng ý để điều phối viên commit local phần Vé của tôi đã kiểm thử, rồi tạo nhánh `feature/mobile-ticket-detail-ui` kế thừa. Commit F02 được tách riêng khỏi commit UI danh sách để dễ review; không bao gồm file tự sinh hay APK. Việc này chưa cho phép Agent tự push/mở PR/merge. SHA nền và đường dẫn checkout mới được ghi trong `MOBILE_TICKET_DETAIL_UI_AGENT_HANDOFF.md` ở workspace.
