# Sơ đồ ghế cố định và Tinh chỉnh UI Mobile (Spatial Seat Map)

Ngày thực hiện: 26/10/2026
Nhánh: `feature/mobile-passenger-info-ui`
Worktree: `vexgo_passenger_info_ui_worktree`
Mục tiêu: Hiện thực hóa đầy đủ yêu cầu người dùng theo `MOBILE_SEAT_MAP_FIXED_LAYOUT_AGENT_HANDOFF.md`: sơ đồ ghế cố định, tự căn giữa không cho trượt ngang, bố trí hàng đầu xe `[Vô lăng] - Đầu xe - [Cửa]`, triệt tiêu khoảng trắng thừa từ đầu xe đến hàng ghế đầu, hiển thị chú thích `SeatLegend` đầy đủ không bị cắt chữ.

## Phạm vi xác minh và điểm để lại sau review

Reviewer đã chạy lại full suite 399/399, analyzer sạch và format 168 file/0 thay đổi. Người dùng đã thử giao diện trên máy thật; APK cài trên realme 11 khớp SHA-256 artifact bên dưới. Đây không phải xác nhận full E2E thanh toán cho bản UI này.

Hai probe độc lập còn tái hiện: (1) chữ Đầu xe ở text scale 2x cần chiều cao 34dp nhưng hàng đang khóa 24dp nên bị cắt; (2) một cấu hình khác mật độ tầng khiến cùng x dịch tâm ghế 3.75dp khi đổi tầng. Người dùng đã quyết định chưa xử lý hai điểm này trong đợt hiện tại. Không tính hai probe này vào số 399 test của suite chính và không tuyên bố mọi cấu hình đều đã được xác minh.

---

## 1. Phân tích & Giải pháp Kỹ thuật

### 1.1 Sơ đồ cố định và tự căn giữa (Không cuộn ngang)
* **Vấn đề trước đây**: `SpatialSeatMap` hoặc fallback lưới cũ sử dụng `SingleChildScrollView(scrollDirection: Axis.horizontal)`. Khi mở màn hình trên điện thoại, người dùng phải dùng tay kéo ngang để đưa xe về giữa hoặc để thấy các cột bên phải (như xe 2+2 trên màn hình 320dp–360dp).
* **Giải pháp**:
  - Loại bỏ hoàn toàn `SingleChildScrollView` ngang.
  - Sử dụng `LayoutBuilder` để đo `constraints.maxWidth` khả dụng của thiết bị. Giới hạn bề ngang tối đa cabin là `contentWidth = min(constraints.maxWidth, 380.0)`.
  - Căn giữa toàn bộ cabin bằng `Align(alignment: Alignment.topCenter)`.
  - Tính toán `cellWidth = max(48.0, min(64.0, maxCellAllowed))` đảm bảo vùng chạm $\ge 48 \times 48\text{dp}$ theo tiêu chuẩn Accessibility mà không gây chồng lấn cột.
  - Cho phép cuộn dọc tự nhiên để người dùng duyệt hết các hàng ghế cuối cùng mà không bị che khuất bởi bottom dock.

### 1.2 Hàng Đầu xe: Bố trí theo thứ tự và căn giữa tuyệt đối
* **Vấn đề trước đây**: Chữ "Đầu xe" và icon vô lăng nằm cùng hàng ngang nhưng vô lăng nằm bên phải, chữ "Đầu xe" bị lệch sang trái, thiếu icon cửa.
* **Giải pháp**:
  - Thứ tự từ trái sang phải: `[Icon vô lăng] — Chữ "Đầu xe" — [Icon cửa]`.
  - Tạo mới `BusDoorVector` trong `lib/features/user/booking/presentation/widgets/seat_vector.dart` bằng SVG nguyên bản theo đúng tone màu `#64748B`, nét vẽ 2px đồng nhất với `SteeringWheelVector`.
  - Dùng `Stack` trong `lib/features/user/booking/presentation/widgets/seat_map_view.dart`:
    - `Align(alignment: Alignment.centerLeft)` cho `SteeringWheelVector`.
    - `Center` cho text "Đầu xe" (nằm chính giữa toàn bộ khung sơ đồ).
    - `Align(alignment: Alignment.centerRight)` cho `BusDoorVector`.

### 1.3 Triệt tiêu khoảng trắng thừa ở đầu sơ đồ
* **Vấn đề trước đây**: Dữ liệu tọa độ $y$ trong DB kiểm thử bắt đầu từ $1000$. Nếu hiển thị trực tiếp tọa độ $y$, khoảng cách từ divider đầu xe đến hàng ghế đầu tiên bị đội lên một khoảng trắng lớn.
* **Giải pháp**:
  - Chuẩn hóa tọa độ $y$ cấp canvas: $y_{\text{screen}} = (y - \text{minY}) \times \text{yScale}$.
  - Giảm padding dọc quanh divider từ 12dp xuống 6dp.
  - Hàng ghế đầu tiên ($y = \text{minY}$) bắt đầu ngay sát dưới divider (< 20dp), loại bỏ hoàn toàn khoảng trống vô nghĩa.

### 1.4 Hiển thị Chú thích trạng thái (`SeatLegend`) bằng `Wrap`
* **Vấn đề trước đây**: `SeatLegend` nằm trong `SingleChildScrollView(scrollDirection: Axis.horizontal)`, trên các màn hình nhỏ 320dp hoặc chữ to 2x thường bị cắt mất chữ "Đã đặt" hoặc icon trạng thái cuối cùng.
* **Giải pháp**:
  - Chuyển `SeatLegend` sang dùng `Wrap` với `width: double.infinity`, `alignment: WrapAlignment.spaceEvenly`, `spacing: 12`, `runSpacing: 8`.
  - Hiển thị đầy đủ cả 4 trạng thái: "Trống", "Đang chọn", "Đang giữ", "Đã đặt". Tự động xuống dòng khi màn hình hẹp hoặc text scale lớn mà không cần thao tác vuốt ngang.

### 1.5 Responsive & Ngăn ngừa RenderFlex Overflow ở 320dp / Text 2.0x
* Khi text scale = 2.0x và mã ghế dài (vd: `LONG-04`), nhãn sẽ reflow xuống nhiều dòng.
* `SpatialSeatMap` đo kích thước thực tế của text bằng `TextPainter.layout(maxWidth: cellWidth)` để xác định chiều cao tối đa của hàng ghế `maxSeatHeight`.
* Hệ số tỷ lệ dọc `yScale = max(64.0 / 1000.0, (maxSeatHeight + minGapY) / minRowDy)` tự động dãn cách các hàng ghế để tuyệt đối không có sự chồng lấn giữa các hàng.
* `Positioned` không khóa cứng `height`, giúp `SeatItem` tự thích ứng chiều cao tự nhiên mà không gây `RenderFlex overflow`.

---

## 2. Bảo tồn các thay đổi của Codex & Baseline
Toàn bộ thay đổi nghiệp vụ của Codex và hệ thống đã được bảo toàn tuyệt đối:
- Giới hạn 5 ghế: `BookingFlowState.maxSeatsPerTrip = 5`.
- Guard chặn chọn ghế thứ 6 trước khi gửi request HTTP.
- Giữ vững toàn bộ session fence, hold release, quote invalidation, `BookingCompactHeader`, và cấu hình cổng API 4000.

---

## 3. Kết quả Kiểm thử & Quality Gates

| Kiểm tra | Lệnh | Kết quả |
|---|---|---|
| **Format** | `dart format --output=none --set-exit-if-changed lib test tool` | **Clean** (168 files, 0 changed) |
| **Analyze** | `flutter analyze --no-pub` | **0 issues found** |
| **Git Diff Check** | `git diff --check` | **0 conflict / whitespace errors** |
| **Focused Suite** | `flutter test test/spatial_seat_layout_test.dart` | **13/13 passed** |
| **Seat Legend Suite** | `flutter test test/seat_legend_test.dart` | **3/3 passed** |
| **Integrity Suite** | `flutter test test/booking_integrity_regression_test.dart` | **29/29 passed** |
| **Passenger Info Suite** | `flutter test test/passenger_info_ui_test.dart` | **20/20 passed** |
| **Full Test Suite** | `flutter test --no-pub` | **399/399 passed** (tăng từ 395) |

---

## 4. Artifact APK Real Mode

APK được build ở chế độ Debug Real Mode với các tham số sandbox chuẩn kết nối API 4000:
- **Đường dẫn artifact**: `mobile-qa-evidence/ci-followup/app-debug-seat-fixed-layout.apk`
- **Dung lượng**: `185,600,790 bytes` (~177.0 MB)
- **SHA-256**: `AFB533E903DAFBB23F0F4019CD9BB7F7C074805665797E384C14CD146CED53E9`
- **Kiểm tra Kernel Binary**:
  - `http://127.0.0.1:4000/api/v1`: **True**
  - `BusDoorVector`: **True**
  - `maxSeatsPerTrip`: **True**
