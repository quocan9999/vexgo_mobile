# Gửi hàng kèm vé: core Flutter

## Phạm vi

Triển khai trên nền khứ hồi a3cf0ba; đối chiếu Backend/Web develop d4ad3d1.
Chỉ tích hợp API/state/validation cho hàng kèm booking một chiều hoặc từng chiều khứ hồi.
Chưa có UI cargo, chưa có dịch vụ gửi hàng độc lập. Không sửa Backend hoặc DB.

## Contract cho presentation

- Model: `lib/data/models/booking_cargo_model.dart`.
- API: `lib/data/repositories/cargo_repository.dart`, mặc định RealCargoRepository.
- Một chiều: gửi `SetBookingCargoEnabledEvent(true)`, `RefreshBookingCargoEvent()`,
  `UpdateBookingCargoEvent(BookingCargoDraft(...))` đến BookingFlowBloc.
- Khứ hồi: dùng `RoundTripCheckoutCubit.dispatch(leg, event)`; không gọi trực tiếp child BLoC.
- Đọc `state.cargo`: enabled, loading, options, draft, error, validationError, isValid.
  `options` chứa categories, capacity, points của đúng trip; không dùng điểm đón hành khách thay thế.
- Tắt cargo bằng event false xóa draft. Không tự tắt khi metadata lỗi.
- `ticketFinalAmount` là tiền vé sau ưu đãi. `finalAmount` là tổng đơn:
  **null khi có cargo trước tạo đơn**, sau đó lấy tổng Backend. Không biến null thành 0.
- `canSubmitDraft` kiểm tra dữ liệu; vẫn giữ busy/session/hold/order locks của luồng hiện tại.
  UI cần bỏ điều kiện bắt buộc tổng tiền biết trước khi tạo đơn có cargo.
- Các mặt hàng/điểm gửi nhận bị khóa sau khi bắt đầu tạo đơn hoặc đã có booking.
  Khứ hồi chỉ sửa chiều còn thiếu; giữ nguyên khóa contact của đơn đã tạo.

## API và tiền

GET /shipments/categories, GET /trips/:id/cargo-capacity,
GET /shipments/trips/:id/route-points cung cấp metadata thật.
POST /bookings gửi cargoItems + senderPointId + receiverPointId trong cùng request vé.
Không POST /shipments riêng. Backend tạo booking/shipment nguyên tử.
Không có endpoint báo phí cargo trước tạo đơn; không sao chép bảng giá hardcode của Web.
Quote và expectedPromotionQuote chỉ tính vé. QR dùng totalAmount của đơn đã xác minh.

Create trả shippingFee và shipment {shipmentId, shipmentCode, shippingFee, itemCount}.
Read trả cargoFee và cargoItems; parser chấp nhận hai tên phí nhưng từ chối mâu thuẫn.
Phải có ticketSubtotal + shippingFee = totalAmount, ưu đãi chỉ trừ tiền vé.
Read không trả shipment summary; giữ summary đã nhận ở create khi đối soát cùng phiên.
Không suy diễn waybill theo tên/số điện thoại. Khôi phục quan hệ waybill sau khởi động lại
vẫn cần contract Backend bổ sung; không tuyên bố đã hỗ trợ.

## Validation và recovery

Loại hàng/nhóm sức chứa: XE_MAY, HANG_CONG_KENH, HANG_NHE. Sức chứa đếm quantity.
Hàng thường tối đa 40kg hiệu dụng; max(actual, L×W×H/5000 làm tròn half-up 1 chữ số).
Kích thước tối đa 150×80×80cm, nhập kích thước phải đủ ba chiều.
Xe máy/xe đạp dùng payload weight 100/15 như Web; không áp quy tắc 40kg cho xe.
Điểm gửi/nhận phải thuộc danh sách đúng vai trò/chuyến, khác nhau.
Metadata lạ, thiếu phí, sai tổng tiền, sai mặt hàng: fail closed, không tạo QR cho chuyển tiền.
Đã biết bookingId thì giữ lại để đọc lại; mất phản hồi POST không tự POST lần nữa.
Đăng xuất/đổi phiên hủy hiệu lực callback metadata cũ. Demo không giả lập cargo.
Vé có ACTIVE_SHIPMENT không cho hủy qua luồng hủy vé; QR lên xe vẫn có thể hợp lệ.

## Kiểm chứng

`test/booking_cargo_core_test.dart` dùng MockClient với repository/BLoC/coordinator thật:
payload nguyên tử, tiền/ưu đãi, sức chứa, metadata sai/chậm, phiên, khóa draft,
mất phản hồi POST, retry khứ hồi không tạo lại đơn, vé đã trả có ACTIVE_SHIPMENT.
Đây là test tự động với HTTP fixture, không phải live API/DB/SePay hay máy thật.
Ngày 29/10/2026: 26/26 test cargo riêng qua; toàn bộ 712/712 test qua;
flutter analyze --no-pub không có vấn đề; git diff --check sạch.
Log ở mobile-qa-evidence/booking-cargo-focused.log, booking-cargo-full-final.log,
booking-cargo-analyze-final.log trong workspace. Chưa build APK cargo hoặc chạy máy thật.
