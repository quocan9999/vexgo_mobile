# Khứ hồi Mobile — API và điều phối cốt lõi

Ngày triển khai: 28/10/2026. Base: integration/mobile-complete-ui@d77a844 (PR #15).
Nhánh: feature/mobile-round-trip-core. Không đổi Backend/schema/migration/.env.

## Contract đã đối chiếu

Backend/Web origin/develop@ce84991. Web RoundTripBooking tạo hold và booking riêng cho từng chặng;
payment-page theo dõi hai booking và chuyển sang kết quả chung khi cả hai đã thanh toán.
Đây không phải transaction khứ hồi nguyên tử, không có một QR chung và không có liên kết hai đơn bền vững ở DB.

| API tái sử dụng | Trách nhiệm Flutter |
|---|---|
| GET /trips/search | Tìm tuyến đi và tuyến đảo chiều, ngày tương ứng; giữ kết quả/lỗi riêng |
| GET /trips/:id/seats | Đọc sơ đồ/status/ID ghế thật cho từng xe |
| POST /seat-holds; DELETE /seat-holds | Token và expiresAt riêng, optional auth hiện có; release theo capability |
| POST /bookings/quote | Giá/ưu đãi riêng từng chặng và đúng số điện thoại |
| POST /bookings | Hai request tuần tự, mỗi request tối đa 5 ghế; không replay kết quả chưa xác định |
| GET /bookings/:id hoặc /:id/detail | Reconcile đúng đơn; datasource giữ guest code/phone riêng từng booking |
| GET /tickets/:id hoặc POST /tickets/lookup | Hydrate vé đầy đủ sau khi xác nhận payment; giữ QR/session guards |

Tạo đơn có promotionCode phải gửi expectedPromotionQuote (originalTotal, discountAmount, finalTotal dạng chuỗi).
Đã bổ sung tham số tùy chọn qua BookingRepository/BookingRemoteDataSource và truyền quote đã chấp nhận từ BookingFlowBloc.
Không tính lại giá hay ưu đãi trong UI. Server vẫn là nơi quyết định tiền thu.

## Điểm tích hợp cho UI

- `round_trip_request.dart`: TripLeg, RoundTripRequest.fromRoute và RoundTripSelection typed payload.
  Giữ ngày về, giới hạn 1–5 vé; chuẩn hóa mã/tên thành phố bằng CitySearchAdapter hiện có.
  Kiểm tra đúng tuyến/ngày, khác tripId và chuyến về phải sau giờ đến chiều đi, kể cả qua đêm.
- `RoundTripSearchCubit`: search, select, clearSelection; revision bỏ response cũ; hai chiều lỗi/loading độc lập.
  State selection chỉ khác null khi có cặp chuyến hợp lệ. Không fallback dữ liệu giả.
- `RoundTripCheckoutCubit`: sở hữu hai BookingFlowBloc. Chỉ xuất snapshot state; UI không lấy BLoC con để mutate.
  dispatch(leg,event), updatePassenger(event), submit(), recheck(leg), invalidateSession(), close().
- `state.leg(leg)` chứa dữ liệu từng chiều; `state.totalAmount` nullable; `state.phase` chỉ là tổng hợp.
  `state.canDisplayTransfer(leg, DateTime.now())` là gate trước khi hiển thị QR/hướng dẫn chuyển khoản.
  Không dùng totalAmount chung để tạo QR. Copy riêng orderCode/amount của đúng chặng.
- Các edit/quote có completion barrier. `busy` bao gồm edit đang chạy; submit/recheck không được chạy trên draft cũ còn trong queue.
  bool từ dispatch/updatePassenger nghĩa là lệnh đã được nhận, không có nghĩa API đã hoàn tất.
- Đóng coordinator giải phóng các hold chưa gửi tạo đơn. Không tự hủy đơn hoặc hoàn tiền chiều đã tạo/thanh toán.
- TokenStorage.sessionChanges thu hồi đồng bộ cả hai snapshot; phản hồi cũ không mở tiếp chiều về dưới tài khoản mới.
- Cấu hình VietQR công khai có value object VietQrReceivingAccount để inject fixture khi test.
  Production mặc định dùng VietQrConfig.account từ dart-define hiện có; không thay tài khoản trong UI.

## Trạng thái bắt buộc trình bày

| Phase | Hành vi |
|---|---|
| editing | Hoàn tất ghế/đón/trả/hành khách/quote của cả hai chiều |
| submitting | Khóa mutation và thoát; không tạo thao tác song song |
| partiallyCreated | Giữ mã đơn đã tạo, cho sửa/tiếp tục chiều chưa tạo khi đủ điều kiện |
| paymentPending | Hai mã/số tiền/QR/thời hạn riêng |
| partiallyPaid | Chỉ chiều đã xác nhận có vé; chưa báo cả hành trình thành công |
| verificationRequired | Hiện lỗi từng chặng và mã đơn đã biết; chỉ recheck đơn đã biết, không tạo lại đơn mất phản hồi |
| success | Cả hai paymentConfirmed và cả hai đã hydrate vé thành công |
| invalidated | Xóa UI payload cũ và yêu cầu quay lại sau đổi phiên |

Nếu đọc đơn đã tạo lỗi, phải recheck chặng đó trước khi submit phần còn thiếu.
Nếu POST mất phản hồi, giữ bookingOutcomeUnknown, chặn submit toàn cặp; hướng dẫn Vé của tôi/tra cứu/hỗ trợ.
Một mã đơn/orderCode bị trả trùng giữa hai chiều sẽ khóa hướng dẫn chuyển khoản và kết quả thành công chung.
Hết hạn ẩn QR theo wall clock, vẫn cho kiểm tra lại đơn đã biết để đối soát chuyển sát hạn.

## Kiểm chứng và giới hạn

Kiểm thử mới nằm ở test/round_trip_core_test.dart: production HTTP adapters/repositories/parsers và BLoC thật,
transport MockClient/clock fixture. Bao phủ tạo hai đơn, partial failure/retry, unknown POST, single-flight,
hai bộ quote/giá, expectedPromotionQuote, expiry, session thay đổi, ticket hydration và dọn hold muộn.
Các log quality gate lưu ngoài Git: mobile-qa-evidence/round-trip-core-*.log.
Kết quả cuối được ghi trong file handoff cùng workspace sau khi các gate hoàn tất.

Chưa nối route/UI nên chưa phát hành tính năng cho người dùng, chưa build APK khứ hồi và chưa device/live SePay E2E.
Không cần Docker cho các fixture tests; không ghi thêm booking/hold/payment vào DB chung trong lượt triển khai này.
Recovery context đang ở vòng đời coordinator/repository trong RAM như nền một chiều, chưa có restore sau process death.
Sau restart, tài khoản dùng Vé của tôi; khách dùng mã/số điện thoại đã giữ để tra cứu. Không tự tạo lại checkout.
Muốn tự phục hồi cặp chặng sau restart/đổi máy cần hạng mục persistence/API riêng, không để Agent UI tự thêm.

## Phạm vi bước UI kế tiếp

UI/route mới chỉ nằm trong round_trip/presentation, app/routes.dart và nhánh điều hướng khứ hồi của Home.
Giữ đường một chiều, các route vé/chứng từ/chat và các guard đang có.
Không sửa lớp core/API để đổi nghiệp vụ theo giao diện. Cần đổi contract phải báo lại người phụ trách core.
