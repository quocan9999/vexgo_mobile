# Mobile Booking Cargo UI ("Gửi hàng kèm vé")

## 1. Thông tin nhánh & Base Commit
- **Worktree**: `vexgo_booking_cargo_ui_worktree`
- **Branch**: `feature/mobile-booking-cargo-ui`
- **Base Commit SHA**: `a99bff4e35b13139bde33af655fe2305a08b5f84`

---

## 2. Danh sách các file thêm mới / cập nhật

### File thêm mới
1. `lib/features/user/booking/presentation/widgets/booking_cargo_section_card.dart`
   - `BookingCargoSectionCard`: Card cấu hình dịch vụ gửi hàng kèm vé dùng chung cho cả đặt vé một chiều (`scopeKey: 'oneway'`) và khứ hồi theo từng chặng (`scopeKey: 'outbound'` / `'inbound'`).
   - `BookingCargoSummaryBox`: Box tóm tắt thông tin kiện hàng gửi, điểm gửi/nhận, phí gửi hàng (`shippingFee`) và mã vận đơn (`shipment.code`) ở các màn hình xác nhận, thanh toán và đặt vé thành công.
2. `test/booking_cargo_ui_test.dart`
   - Bộ widget test kiểm thử đầy đủ các trạng thái Cargo UI một chiều, khứ hồi độc lập 2 chiều và responsive (`320x640` với `2.0x textScale`, `640x360` landscape kèm bàn phím).
3. `docs/MOBILE_BOOKING_CARGO_UI.md`
   - Tài liệu mô tả thiết kế, danh sách file, contract BLoC/Cubit và kết quả kiểm thử.

### File cập nhật (Presentation)
1. `lib/features/user/booking/presentation/screens/booking_flow_screen.dart`
   - Truyền `cargoRepository: context.read<CargoRepository?>()` vào `BookingFlowBloc`.
   - Truyền `'booking': state.checkoutBooking` trong `extra` khi điều hướng sang `BookingSuccessScreen`.
2. `lib/features/user/booking/presentation/steps/step_4_passenger_info.dart`
   - Tích hợp `BookingCargoSectionCard` ngay sau card thông tin liên hệ hành khách, giữ nguyên stepper 6 bước.
3. `lib/features/user/booking/presentation/widgets/booking_passenger_info_view.dart`
   - Cập nhật guard nút `Tiếp tục` tại `BookingPassengerDock`: yêu cầu `state.cargo.isValid` khi bật gửi hàng kèm vé, hiển thị thông báo lỗi hợp lệ từ `state.cargo.validationError`.
4. `lib/features/user/booking/presentation/steps/step_5_trip_summary.dart`
   - Hiển thị `BookingCargoSectionCard` để khách xem/chỉnh sửa trước khi tạo đơn.
   - Tách rõ bảng chi tiết thanh toán: `Giá vé`, `Giảm giá ưu đãi`, `Tiền vé sau ưu đãi`, `Phí gửi hàng` (`Phí gửi hàng được xác định khi tạo đơn` trước tạo đơn; `shippingFee` từ máy chủ sau tạo đơn) và `Tổng tiền cần thanh toán`.
5. `lib/features/user/booking/presentation/widgets/booking_trip_summary_view.dart`
   - Hiển thị tiền vé kèm ghi chú `Phí gửi hàng được xác định khi tạo đơn` ở `BookingTripSummaryDock` khi `state.cargo.enabled && state.finalAmount == null`.
6. `lib/features/user/booking/presentation/widgets/booking_bottom_bar.dart`
   - Đồng bộ guard `state.cargo.isValid` và `state.canSubmitDraft`, hiển thị rõ trạng thái phí gửi hàng chờ xác định khi tạo đơn.
7. `lib/features/user/booking/presentation/widgets/booking_payment_view.dart`
   - Cập nhật `BookingPaymentDock` trước khi tạo đơn: sử dụng `state.canSubmitDraft`, đổi nhãn CTA thành `Tạo đơn & Thanh toán` khi `state.cargo.enabled && state.finalAmount == null`.
8. `lib/features/user/booking/presentation/steps/step_6_payment.dart`
   - Trước tạo đơn (`_buildPreOrderView`): không format `null` thành `0 đ`; hiển thị `Xác định khi tạo đơn`, `Tiền vé sau ưu đãi` và `BookingCargoSummaryBox`.
   - Sau tạo đơn (`_buildPostOrderView`): hiển thị `Tiền vé sau ưu đãi`, `Phí gửi hàng`, `Tổng đơn thanh toán` từ `BookingModel` và `BookingCargoSummaryBox` (kèm mã vận đơn `shipment.code` nếu có).
9. `lib/features/user/booking/presentation/screens/booking_success_screen.dart`
   - Nhận `BookingModel? booking` (từ constructor hoặc `GoRouterState.of(context).extra['booking']`) và hiển thị `BookingCargoSummaryBox` khi đơn có gửi hàng; giữ nguyên mã QR lên xe của vé hành khách.
10. `lib/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart`
    - Truyền `cargoRepository: context.read<CargoRepository?>()` vào `RoundTripCheckoutCubit`.
    - Nối callback `onDispatchCargo: (leg, event) => cubit.dispatch(leg, event)` cho `RoundTripPassengerStep` và `RoundTripSummaryStep`.
11. `lib/features/user/round_trip/presentation/widgets/round_trip_passenger_step.dart`
    - Hiển thị 2 card `BookingCargoSectionCard` độc lập cho `Lượt đi` (`TripLeg.outbound`) và `Lượt về` (`TripLeg.inbound`), tôn trọng trạng thái khóa riêng từng chặng (`isCheckoutLocked`).
12. `lib/features/user/round_trip/presentation/widgets/round_trip_summary_step.dart`
    - Thích nghi guard `canSubmit` với `hasCargoPendingPrice` khi `widget.totalAmount == null` do có chặng bật gửi hàng chưa tạo đơn.
    - Không dùng `?? 0` cho tổng tiền chưa xác định; hiển thị rõ tiền vé và ghi chú `Phí gửi hàng được xác định khi tạo đơn` theo từng chặng.
13. `lib/features/user/round_trip/presentation/widgets/round_trip_payment_view.dart`
    - Hiển thị chi tiết `ticketSubtotal`, `shippingFee`, `totalAmount` và `BookingCargoSummaryBox` riêng cho từng chặng (mỗi chặng giữ nguyên VietQR độc lập).
14. `lib/features/user/round_trip/presentation/widgets/round_trip_success_view.dart`
    - Hiển thị `BookingCargoSummaryBox` trong từng thẻ kết quả chặng đi / chặng về nếu chặng đó có gửi hàng kèm vé.

---

## 3. Sự kiện & Contract Core/BLoC đã sử dụng
- **Một chiều (`BookingFlowBloc`)**:
  - `bloc.add(SetBookingCargoEnabledEvent(bool enabled))`
  - `bloc.add(const RefreshBookingCargoEvent())`
  - `bloc.add(UpdateBookingCargoEvent(BookingCargoDraft draft))`
- **Khứ hồi (`RoundTripCheckoutCubit`)**:
  - `cubit.dispatch(leg, SetBookingCargoEnabledEvent(bool enabled))`
  - `cubit.dispatch(leg, const RefreshBookingCargoEvent())`
  - `cubit.dispatch(leg, UpdateBookingCargoEvent(BookingCargoDraft draft))`
  - Đọc state độc lập qua `state.outbound.cargo` / `state.inbound.cargo` (`state.leg(leg).cargo`).

---

## 4. Các giới hạn & Quy tắc nghiệp vụ được bảo toàn
1. **Không tự tính phí gửi hàng ở Mobile**: Trước khi tạo đơn (`POST /bookings`), `state.finalAmount` là `null` khi bật cargo; UI ghi rõ `"Phí gửi hàng được xác định khi tạo đơn"` và vẫn cho phép tạo đơn khi `canSubmitDraft == true`.
2. **Không tự tắt cargo khi lỗi tải tùy chọn**: Khi `cargo.loading` hoặc `cargo.error != null`, công tắc gửi hàng vẫn giữ trạng thái bật, hiển thị nút `Thử lại` (`RefreshBookingCargoEvent`) và `Bỏ gửi hàng` (`SetBookingCargoEnabledEvent(false)`).
3. **Tự động ánh xạ nhóm sức chứa (`CargoGroup`)**: Khi chọn `CargoKind` hoặc nhập khối lượng/kích thước quy đổi (`D × R × C / 5000 ≥ 20 kg`), danh mục `CargoCategory` được lọc đúng theo `CargoGroup` (`HANG_NHE`, `HANG_CONG_KENH`, `XE_MAY`) và kiểm tra số chỗ còn lại (`slots[group]?.remaining`).
4. **Khóa chỉnh sửa sau khi tạo đơn**: Khi `state.isCheckoutLocked == true` (hoặc từng chặng đã tạo trong `partiallyCreated`), toàn bộ thao tác bật/tắt, chọn điểm gửi/nhận và thêm/sửa/xóa kiện hàng của đơn đó bị khóa hoàn toàn.
5. **Tách biệt QR vé hành khách và mã vận đơn**: Mã vận đơn (`booking.shipment?.code`) chỉ hiển thị dạng văn bản khi Backend trả về; không thay thế QR lên xe của vé hành khách.

---

## 5. Kết quả kiểm định (Verification)

### Follow-up chức năng ngày 29/10/2026

- Trên Android thật, API bản sửa đọc lại đơn #843 đúng: vé 190.000đ + phí hàng
  50.000đ = 240.000đ; một bưu phẩm 5kg, một vận đơn. SePay Test Mode đã gửi một
  giao dịch mô phỏng; webhook thành công và đơn/vé đã thanh toán trong MySQL local.
- App đã mở màn thành công, QR lên xe và chứng từ có tổng 240.000đ. Hủy vé trực
  tuyến bị chặn đúng vì hàng gửi kèm còn hiệu lực; không thực hiện hủy đơn.
- Sửa riêng binding tổng tiền trên màn thành công: dùng booking.totalAmount khi
  booking đã thanh toán và toàn bộ vé thuộc đúng booking; giá riêng từng vé giữ
  nguyên. Không đổi bố cục, API hoặc cách tính phí.
- Assertion hồi quy tổng 240.000đ thất bại trên code cũ và qua sau sửa. Sau sửa:
  cargo UI 8/8, toàn bộ Flutter 720/720, analyze không có issue, build debug qua.
- APK `app-debug-booking-cargo-v2.apk` đã chép vào Download/Vexgo và đối chiếu hash.
  Người dùng đã cài v2; hash base.apk khớp. Mở lại vé #843, QR và chứng từ trên v2
  vẫn đọc đúng 190.000đ + 50.000đ = 240.000đ. Màn thành công chưa được mở lại sau
  cập nhật; nhãn mới được xác nhận bằng widget test, chưa phải visual retest native.

- **Phân tích tĩnh**:
  - `flutter analyze --no-pub`: **0 lỗi, 0 cảnh báo (`No issues found!`)**.
- **Kiểm thử tự động**:
  - `flutter test --no-pub test/booking_cargo_ui_test.dart`: **8/8 tests passed** (bao gồm regression tests cho F01, F02, F03, F04).
  - `flutter test --no-pub test/booking_cargo_core_test.dart`: **26/26 tests passed**.
  - `flutter test --no-pub ../mobile-qa-evidence/cargo_ui_review_probe_test.dart`: **4/4 review probes passed**.
  - `flutter test` (toàn bộ bộ kiểm thử của dự án): **720/720 tests passed**.
