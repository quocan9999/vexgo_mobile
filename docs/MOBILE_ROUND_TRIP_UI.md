# Báo cáo Triển khai UI Đặt vé Khứ hồi Mobile (Flutter)

**Ngày triển khai:** 29/10/2026
**Nhánh:** `feature/mobile-round-trip-ui` (Worktree: `vexgo_round_trip_ui_worktree`)
**Base commit:** `8c022b8e642c26b7cc72d12a7aa0890e17a838c4`
**Trạng thái Quality Gates:**
- `dart format lib/ test/`: **Pass 100%**
- `flutter analyze --no-pub`: **No issues found (0 errors, 0 warnings)**
- `flutter test test/round_trip_ui_comprehensive_test.dart`: **19/19 passed**
- `flutter test test/round_trip_core_test.dart`: **29/29 passed**
- `flutter test` (toàn dự án): **684/684 passed**

---

## 1. Tổng quan Nghiệp vụ & Kiến trúc UI

Dựa trên core logic đã hoàn thiện ở PR core (`RoundTripSearchCubit`, `RoundTripCheckoutCubit`, `round_trip_request.dart`), giao diện đặt vé khứ hồi Mobile tuân thủ chặt chẽ mô hình nghiệp vụ của hệ thống Web:
- **Hai chuyến, hai đơn hàng riêng biệt, thanh toán riêng từng chiều.**
- **Không gộp chung thành một đơn**, **không tạo một mã QR tổng**, **không cộng dồn tiền để chuyển khoản một lần**.
- Tái sử dụng các UI components hoàn thiện từ PR #15 (`SeatMapView`, `StopPointSelection`, `TripDetailSheet`, `DiscoveryButton`, token thiết kế chuẩn `DiscoveryColors`, `DiscoveryTextStyles`, `AppDimensions`).
- Tách bạch rõ ràng: Coordinator (`RoundTripCheckoutCubit`) sở hữu hai `BookingFlowBloc` con, UI chỉ lắng nghe stream snapshot và dispatch lệnh điều phối (`dispatch`, `updatePassenger`, `submit`, `recheck`), không mutate trực tiếp các BLoC con.

---

## 2. Danh mục Files Mới & File Thay đổi

### 2.1. Cấu trúc Presentation Mới (`lib/features/user/round_trip/presentation/`)
1. [`widgets/round_trip_trip_card.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/widgets/round_trip_trip_card.dart):
   - Thẻ chuyến xe chuyên dụng cho tìm kiếm khứ hồi.
   - Hiển thị badge "Đã chọn" khi chuyến đang được chọn trong selection.
   - Hiển thị giá `discountPrice` (kèm `originalPrice` gạch ngang nếu có ưu đãi), loại xe, số ghế trống, timeline khởi hành - đến nơi.
   - Nút "Chi tiết" mở `TripDetailSheet.show` để xem điểm đón/trả và tiện ích.
2. [`screens/round_trip_search_screen.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/screens/round_trip_search_screen.dart):
   - Màn hình tìm kiếm hai chiều độc lập với `DefaultTabController(length: 2)`.
   - Hai tab "Lượt đi" và "Lượt về" có trạng thái loading, error, danh sách chuyến độc lập.
   - Lựa chọn chuyến được lưu giữ khi chuyển qua lại giữa hai tab.
   - Hỗ trợ đổi chiều hiển thị chuyến về theo chiều đến chuyến đi (`inboundAfterOutboundArrival`).
   - Bottom bar tóm tắt hai chuyến đã chọn và kích hoạt nút "Tiếp tục" khi cả hai chuyến hợp lệ (`canContinue == true`).
3. [`widgets/round_trip_leg_header.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/widgets/round_trip_leg_header.dart):
   - Header chuyển đổi chặng Lượt đi / Lượt về dạng segment/tab.
   - Hiển thị chip tóm tắt số ghế đã chọn (`s.name`) cho từng chiều ngay trên header.
4. [`widgets/round_trip_passenger_step.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/widgets/round_trip_passenger_step.dart):
   - Form thông tin hành khách đại diện dùng chung cho cả 2 chặng.
   - Tự động gọi `coordinator.updatePassenger(...)` để đồng bộ thông tin hành khách sang cả hai `BookingFlowBloc` con.
5. [`widgets/round_trip_summary_step.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/widgets/round_trip_summary_step.dart):
   - Xác nhận thông tin chi tiết từng chặng (nhà xe, tuyến, thời gian, điểm đón, điểm trả, số ghế).
   - Ô nhập mã giảm giá (voucher) riêng biệt cho từng chặng kèm báo lỗi quote trực tiếp.
   - Bảng tóm tắt tiền: Chi phí lượt đi, chi phí lượt về, tổng tiền dự kiến.
   - Chống tràn layout với `Wrap` và `Expanded` trên màn hình hẹp 320dp và font scale 2.0x.
6. [`widgets/round_trip_payment_view.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/widgets/round_trip_payment_view.dart):
   - Giao diện thanh toán khứ hồi chuẩn hóa theo 2 đơn hàng riêng:
     + Mỗi chặng một Card riêng hiển thị mã đơn hàng `#bookingId`, nội dung chuyển khoản `orderCode`, số tiền chuyển khoản riêng.
     + Mã VietQR riêng cho từng chặng qua `VietQrConfig.imageUrl(amount, orderCode)` (hoặc `pendingQrCodeUrl`).
     + Đếm ngược thời gian thanh toán theo wall-clock riêng từng đơn.
     + Kiểm soát hiển thị chuyển khoản qua gate `state.canDisplayTransfer(leg, now)`. Ẩn QR khi hết hạn, giữ nút kiểm tra lại.
     + Nút "Kiểm tra thanh toán" riêng cho từng chặng (`onRecheck(leg)`).
     + Trình bày rõ ràng trạng thái `partiallyPaid` (một chặng đã thanh toán, một chặng chờ thanh toán).
     + Cảnh báo an toàn khi gặp `ordersConflict` hoặc `verificationRequired` mà không bao giờ gộp tiền hay tạo QR chung.
7. [`widgets/round_trip_success_view.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/widgets/round_trip_success_view.dart):
   - Giao diện hoàn tất khứ hồi chỉ hiển thị khi `isComplete == true` (cả hai chặng đều `paymentConfirmed` và đã hydrate vé thành công).
   - Hiển thị danh sách vé đầy đủ từ `createdTickets` của cả hai chặng kèm thông tin mã vé, tuyến, giờ đi và số ghế.
8. [`screens/round_trip_booking_screen.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart):
   - Màn hình điều phối booking chính sở hữu `RoundTripCheckoutCubit`.
   - Hỗ trợ DI tùy chọn `cubit` phục vụ testing/mocking.
   - Tự động hydrate thông tin tài khoản đang đăng nhập từ `AuthBloc`.
   - Dẫn dắt người dùng qua các bước tuần tự cho từng chặng: Chọn ghế (`SeatMapView`) → Điểm đón (`StopPointSelection`) → Điểm trả (`StopPointSelection`) → Hành khách (`RoundTripPassengerStep`) → Xác nhận (`RoundTripSummaryStep`) → Thanh toán (`RoundTripPaymentView`).
   - Xử lý back/pop an toàn (`PopScope`): cảnh báo người dùng khi đã có đơn hàng được tạo.

### 2.2. File Tuyến đường & Entrypoint được cập nhật
1. [`lib/app/routes.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/app/routes.dart):
   - Bổ sung hằng số `AppRoutes.roundTripSearch = '/round-trip/search'`.
   - Bổ sung hằng số `AppRoutes.roundTripBooking = '/round-trip/booking'`.
   - Đăng ký GoRoute với query parameters và extra payload theo chuẩn contract.
2. [`lib/features/user/home/presentation/widgets/search_form_card.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_round_trip_ui_worktree/lib/features/user/home/presentation/widgets/search_form_card.dart):
   - Phân nhánh điều hướng: Khi `state.isRoundTrip == true`, chuyển hướng sang `AppRoutes.roundTripSearch` kèm query parameters (`fromCityId`, `toCityId`, `date`, `returnDate`, `ticketCount`) và extra map (`fromCity`, `toCity`, `date`, `returnDate`).
   - Giữ nguyên 100% luồng tìm kiếm một chiều truyền thống sang `/search-trips`.

---

## 3. Bộ Kiểm thử Toàn diện (`test/round_trip_ui_comprehensive_test.dart`)

Bao phủ 19 test cases trên 5 nhóm yêu cầu cốt lõi và các kịch bản hồi quy từ Codex Review (`F01`–`F03`):
1. **Group 1: Navigation & Route Parameter Preservation**
   - Test 1: Nút tìm chuyến một chiều giữ nguyên route `/search-trips`.
   - Test 2: Bật switch Khứ hồi bảo lưu `returnDate` và điều hướng sang `/round-trip/search`.
   - Test 3: Truy cập `/round-trip/search` với query không hợp lệ (trùng điểm đi/đến) hiển thị thông báo thân thiện, không crash.
2. **Group 2: RoundTripSearchScreen Behavior & Leg Tabs**
   - Test 4: Màn hình tìm kiếm hiển thị 2 tab Lượt đi / Lượt về với kết quả độc lập.
   - Test 5: Một chiều gặp lỗi API vẫn bảo lưu kết quả chiều còn lại và hiển thị nút "Thử lại".
   - Test 6: Chọn chuyến lượt đi và chuyến lượt về tương thích kích hoạt nút "Tiếp tục".
3. **Group 3: RoundTripBookingScreen Step Flow & Passenger Sync**
   - Test 7: Mở màn hình đặt vé mà thiếu payload selection hiển thị màn hình báo lỗi và nút quay lại.
   - Test 8: Bước chọn ghế hiển thị `SeatMapView` và cập nhật tóm tắt ghế trên leg header.
   - Test 9: Cập nhật thông tin hành khách đồng bộ cả hai chặng đi và về.
4. **Group 4: Payment View, Invalidation, Two Separate QRs & Partial Status**
   - Test 10: Trạng thái `paymentPending` hiển thị hai card VietQR riêng biệt với số tiền và mã chuyển khoản riêng, không gộp tổng.
   - Test 11: Trạng thái `partiallyPaid` hiển thị badge "ĐÃ THANH TOÁN" cho một chiều và giao diện chuyển khoản cho chiều còn lại.
   - Test 12: Trạng thái `isComplete` hiển thị `RoundTripSuccessView` với danh sách vé đầy đủ của cả hai chiều.
   - Test 13: Đổi phiên đăng nhập (`invalidateSession`) xóa dữ liệu cũ và hiển thị thông báo yêu cầu đăng nhập lại.
5. **Group 5: Responsive, A11y & Review Regressions (R01–R04)**
   - Test 14: Màn hình hẹp 320dp với font scale 2.0x render mượt mà, không bị tràn viền (zero overflow).
   - Test 15: Màn hình ngang 640x360 với bàn phím che 160dp vẫn cuộn và tương tác bình thường.
   - Test 16 (**R01 / F01**): Khi tạo đơn chiều đi bị từ chối rõ ràng (HTTP 409) hoặc bị chặn trước khi POST (`step == BookingStep.payment`, `pendingBookingId == null`, `phase == editing`), màn hình giữ nguyên `RoundTripSummaryStep` kèm thông báo lỗi cụ thể, nút thử lại (`confirm-and-pay-btn`) và nút đổi ghế (`edit-summary-leg-outbound-btn`); khi thử lại thành công tạo đủ hai đơn hàng.
   - Test 17 (**R02 / F02**): Khi tạo đơn một phần (`partiallyCreated`: chiều đi 200, chiều về 409), thẻ chiều về chưa có đơn hiển thị nút "Thử lại / Tạo đơn chiều này" (`retry-create-inbound-btn` nối với `onRetrySubmitMissing`) và nút "Đổi ghế / điểm đón trả chiều này" (`edit-missing-inbound-btn`); bấm thử lại chỉ tạo bổ sung đơn chiều về mà không POST trùng đơn chiều đi.
   - Test 18 (**R03 / F03**): Khi một chặng đã `paymentConfirmed == true` nhưng đọc chi tiết vé gặp lỗi tạm thời (404/network, `createdTickets` rỗng), thẻ chặng đó không mở lại QR nhưng vẫn giữ nút `recheck-outbound-btn` ("Đồng bộ lại vé") để đồng bộ vé và chuyển sang `RoundTripSuccessView` (`isComplete == true`).
   - Test 19 (**R04**): Dữ liệu hold/quote thực tế từ `RoundTripCheckoutCubit` render trên màn hình 320dp với font scale 2.0x hoàn toàn không bị overflow.

---

## 4. Kết quả Thực thi Quality Gates

```bash
$ dart format lib/ test/
Formatted 218 files (0 changed) in 1.38 seconds.

$ flutter analyze --no-pub
Analyzing vexgo_round_trip_ui_worktree...
No issues found!

$ flutter test test/round_trip_ui_comprehensive_test.dart
00:03 +19: All tests passed!

$ flutter test test/round_trip_core_test.dart
00:00 +29: All tests passed!

$ flutter test
00:35 +684: All tests passed!
```

---

## 5. Lưu ý Bàn giao cho Codex Review

1. **Tuyệt đối không sửa core**: Toàn bộ 3 file cốt lõi (`round_trip_request.dart`, `round_trip_search_cubit.dart`, `round_trip_checkout_cubit.dart`) và các BLoC con một chiều hoàn toàn nguyên vẹn.
2. **Worktree sạch**: Toàn bộ generated plugin registrants (`linux/`, `macos/`, `windows/`) đã được restore nguyên trạng.
3. **Không commit / push**: Giữ toàn bộ changes tại working directory của branch `feature/mobile-round-trip-ui` trong worktree `vexgo_round_trip_ui_worktree` để Codex trực tiếp review và phê duyệt.

## 6. Codex sửa F04 sau re-review — 29/10/2026

Kết quả mới nhất thay cho số liệu snapshot phía trên: **686/686 test qua**, analyzer **No issues found**.

- Khi `state.hasAnyOrder`, BookingScreen truyền `readOnly` cho form hành khách chung.
  Họ tên, số điện thoại, email và ghi chú giữ dữ liệu đã được chấp nhận; UI giải thích thông tin được giữ theo đơn đã tạo.
- Form bỏ callback chỉnh sửa khi chỉ đọc. Nếu form đang mounted chuyển từ editable sang locked,
  các controller được đồng bộ lại với thông tin authoritative, không giữ draft chưa được core chấp nhận.
- Giữ nguyên khả năng sửa ghế/đón/trả và tạo bổ sung chiều chưa có đơn. Không sửa core/API/Backend.
- Thêm `test/round_trip_passenger_lock_test.dart` (2 test): partial create → sửa ghế thực trên UI → form khóa →
  tạo chiều về với đúng contact cũ và seatIds mới, không tạo trùng chiều đi; và editable→locked khi mounted.
- Hai test mới qua; toàn bộ 686 test qua. Probe E01 từng tái hiện F04 được chạy lại riêng sau sửa.
- Chưa build/cài APK hoặc kiểm thử khứ hồi live trên điện thoại trong lượt sửa này; transport test là MockClient.
- Chưa commit/push/tạo PR khứ hồi.

## 7. Chốt snapshot khứ hồi — 29/10/2026

Người dùng đã yêu cầu chốt bản khứ hồi hiện tại để chuẩn bị gửi hàng kèm vé.
Phạm vi commit gồm UI, routes/Home wiring, regression F01–F04 và báo cáo này;
core tại8c022b8 được kế thừa nguyên vẹn. Các mục “chưa commit” phía trên là trạng thái lịch sử trước yêu cầu chốt.
Quality gate gần nhất trên đúng code:686/686 tests qua, analyzer sạch; format lib/test/tool220files/0changed.
Không coi đây là bản đã qua device/live SePay khứ hồi; các giới hạn kiểm chứng phía trên vẫn áp dụng.
Chỉ chốt local; chưa push/tạo PR hoặc merge. Phần gửi hàng kèm vé được làm trên nhánh riêng.
