# Chuẩn bị gửi hàng kèm vé Mobile

Chốt phạm vi ngày29/10/2026 theo yêu cầu người dùng. Core API/state đã triển khai;
tài liệu kết quả và contract callback hiện tại: [MOBILE_BOOKING_CARGO_CORE.md](MOBILE_BOOKING_CARGO_CORE.md).
Các mục dưới đây lưu nền và phạm vi đã thống nhất; phần UI vẫn là công việc tiếp theo.

## Nền đã chốt và đồng bộ

- Mobile khứ hồi: `feature/mobile-round-trip-ui@a3cf0ba33c1659bd1530db9aca7568268bb90c77`.
  Gồm UI, core8c022b8, sửa F01–F04; gate code gần nhất686/686 tests, analyzer sạch.
  Chưa có device/live SePay khứ hồi; không dùng việc chốt commit để thay cho bằng chứng này.
- Mobile remote `team/develop`: `7981d22aa932794cd8d4e63f2f1ba37fbc590864`, không có commit mới;
  nền khứ hồi đã chứa develop này. Không kéo local develop cũ vào để mất tính năng chưa merge.
- Backend/Web `origin/develop`: `d4ad3d1d5ff12a49ae34b85287e29deb93570e6a` (PR47, địa điểm).
  Đã fast-forward cả vexgo_web/develop và vexgo_chat_worktree/integration/develop-mobile-20261026.
  Không đổi migration/schema/package manifest/lockfile trong cập nhật này.
- File local `vexgo_web/prisma/seed_future_trips.mjs` giữ nguyên, SHA256:
  `660BE4053081D04650CE532D0D1AABDBFF4404550CE5DD31E1B8A0CAEBFEF304`.
- Backend22/22 targeted location/routes tests qua, Prisma generate + Nest build thành công.
  Build dùng loader env sẵn có mobile-qa-evidence/backend-sync-20261026/build-api.mjs,
  chỉ truyền env vào process; không copy/in env/secrets. Lệnh npm build trực tiếp thiếu MIGRATION_URL
  đã thất bại ở prebuild trước đó; retry qua loader cấu hình chuẩn hoàn tất.
- Không migrate/reset/seed DB, không khởi động API, không push/tạo PR/merge trong lượt chuẩn bị.

## Worktree và trách nhiệm

Core mới: `vexgo_booking_cargo_core_worktree`, branch `feature/mobile-booking-cargo-core`,
tách từ a3cf0ba. Bản khứ hồi nguồn được giữ nguyên; scope gửi hàng có commit/PR riêng sau khi triển khai và review.

Codex phụ trách models, datasource/repository, state/BLoC, validation/giá, auth/race/recovery và kiểm thử API/device.
Agent UI phụ trách presentation: form kiện hàng, điểm gửi/nhận, tóm tắt, trạng thái lỗi/loading, responsive/widget tests.
Core callback/state cargo đã có; worktree UI được tách từ commit core đã kiểm thử,
kèm MOBILE_BOOKING_CARGO_UI_AGENT_HANDOFF.md ở workspace. Agent UI không tự gọi API.

## Phạm vi sản phẩm

- Hàng gửi kèm trong lúc đặt vé, cho cả một chiều và từng chặng khứ hồi.
- Tùy chọn không gửi hàng phải giữ nguyên luồng hiện tại, không làm hỏng đặt vé thường.
- Mỗi chặng có cargo draft và điểm gửi/nhận riêng, chỉ gửi theo chuyến tương ứng.
- Cùng một booking/order/payment của chặng bao gồm vé và hàng; không POST /shipments lần hai.
- Người nhận của hàng kèm hiện được Backend lấy từ booking contact; chưa thêm người nhận độc lập.
- Không gồm dịch vụ gửi hàng độc lập, một QR gộp khứ hồi, tự hủy hàng/hoàn tiền hoặc Admin UI.

## API có sẵn và các giới hạn contract

| Endpoint | Vai trò |
|---|---|
| GET /shipments/categories | categoryId/name/description/capacityGroup thật từ DB |
| GET /trips/:id/cargo-capacity | acceptsShipments và total/used/remaining theo motorcycles/bulkyGoods/parcels |
| GET /shipments/trips/:tripId/route-points | senderPoints/receiverPoints với id/name/address; rates/minFee nếu có |
| POST /bookings/quote | Chỉ báo giá vé/ưu đãi vé, không phải quote cargo |
| POST /bookings | Gửi cargoItems + senderPointId + receiverPointId cùng trip/seatIds/holdToken/contact |
| GET /bookings/:id, /:id/detail | Đọc lại trạng thái/tổng tiền/cargoFee/cargoItems qua cơ chế owner/guest hiện có |
| GET /shipments/:id; POST /shipments/lookup | Đọc phiếu đã biết ID/code với quyền/capability hợp lệ nếu cần |

Payload cargoItems: name, type, loaiHangHoaId, quantity, weight; length/width/height;
category normal/fragile/valuable; note/motorbikeModel/bicycleType/licensePlate khi phù hợp.
Không nhầm senderPointId/receiverPointId với StopPointModel.id của ghế/đón/trả.

Backend khóa sức chứa chuyến, kiểm tra hàng/cước/hold và tạo booking + shipment trong cùng transaction.
Tổng tiền create response là totalAmount; phân tách originalTicketSubtotal/discountAmount/ticketSubtotal/shippingFee;
shipment summary có shipmentId/shipmentCode/shippingFee/itemCount. Detail read dùng tên cargoFee/cargoItems.
Parser phải phân biệt các alias có thật và không ghi đè thông tin hợp lệ bằng default0 khi field bị thiếu.

Chưa có endpoint quote cargo riêng. Giữ hướng Web: phí trước tạo đơn được ghi rõ ước tính/chờ server;
chỉ dùng tổng server đã xác minh để dựng QR/chuyển khoản. Không copy bảng giá hardcode ở Web thành giá thu.
Nếu dùng rates từ API để ước tính, phải gắn đúng trip/points/category/dimensions và không coi là giá cam kết.
Nếu muốn cam kết toàn bộ giá trước POST booking thì cần đề xuất mở rộng Backend riêng, không giả lập endpoint.

Fresh booking detail có items/fee nhưng không đảm bảo trả shipmentId/code. Khi triển khai phải kiểm tra cách
đọc lại mã vận đơn bằng API được phép và liên kết orderCode đã xác minh; không suy ra phiếu chỉ từ tên/phone.
GET /shipments hiện có search/status/pagination, không tự thêm query bookingId/orderId không có trong DTO.
Nếu không thể phục hồi capability hợp lệ sau restart, báo rõ giới hạn, không bịa mã hoặc bypass quyền.

## Hạng mục core cần triển khai

1. Models: CargoCategory, CargoCapacity, CargoRoutePoint/RoutePoints/Rate, CargoItemDraft,
   BookingCargoDraft, ShipmentSummary, kết quả phí ước tính và phí server.
2. CargoRemoteDataSource/CargoRepository: đọc danh mục, capacity và points qua ApiClient hiện có;
   DTO/parser fail-closed khi response thiếu/sai. Không silent mock fallback Real Mode.
3. BookingFlowState/events và coordinator khứ hồi: cargo riêng từng chặng, tùy chọn thêm/sửa/xóa;
   revision/session fence cho các request; edit completion barrier giữ submit không dùng draft cũ.
4. BookingRepository/BookingRemoteDataSource: truyền cargo payload trong cùng createApiBooking;
   có hàng mà thiếu điểm hoặc khai báo sai phải chặn/hiện lỗi, không lặng lẽ bỏ hàng rồi tạo vé thường.
5. BookingModel và payment/summary data: tách tiền vé/phí hàng/tổng đơn, shipment identifiers;
   BookingQuoteModel/expectedPromotionQuote vẫn chỉ là quote vé theo Backend, không cộng phí hàng vào đó.
6. Khi đã POST/unknown hoặc có bookingId, khóa cargo của đúng chặng; partial khứ hồi vẫn sửa được chặng thiếu,
   giữ contact chung đã khóa theo F04. Không thay hàng trong đơn đã tạo qua thao tác UI local.
7. Success/chứng từ/chi tiết: hiện cargo summary và vận đơn khi có dữ liệu đã xác minh;
   giữ QR vé và QR thanh toán đúng mục đích, không dùng mã vận đơn làm boarding QR.

Các vị trí nền cần sửa có kiểm soát:
- lib/data/models và datasources/remote, repositories cho cargo/booking.
- lib/features/user/booking/bloc/booking_flow_state.dart, booking_flow_event.dart, booking_flow_bloc.dart.
- lib/features/user/round_trip/round_trip_checkout_cubit.dart (dispatch/guard cho cargo per-leg).
- lib/features/user/booking/presentation và round_trip/presentation chỉ sau khi public core API được chốt.

## Quy tắc kiểm tra và lỗi

- Chuyến không nhận hàng hoặc không tải được capability: không nhận cargo draft như dữ liệu đã xác minh;
  vẫn cho đi tiếp với vé thường nếu người dùng chủ động bỏ gửi hàng.
- Nhóm capacity đếm số lượng theo nhóm, không nhầm remaining là số kg.
- Điểm gửi/nhận lấy từ API đúng chuyến/nhà xe/vai trò, bắt buộc khác nhau.
- Kiện thường: khối lượng tính cước là max(weight thực, L×W×H/5000) với làm tròn theo Backend;
  giới hạn40kg/kiện hiệu dụng và150×80×80cm. Không áp giới hạn kiện thường sai cho xe máy/xe đạp.
- Danh mục categoryId thật; không lấy nhãn tự đặt làm ID và không gán nhầm capacityGroup.
- Khuyến mãi chỉ giảm phần vé theo quote; shippingFee/cargoFee do server chốt riêng.
- Hết slot hoặc đổi bảng cước trong lúc submit: hiển thị lỗi có thể sửa, refresh đúng dữ liệu;
  POST mất phản hồi: giữ unknown, không tự replay tạo booking/shipment.
- Vé có phiếu hàng hoạt động đang bị Backend chặn hủy với ACTIVE_SHIPMENT;
  dùng cancellation policy hiện có, không hứa hủy vé đồng nghĩa hủy phiếu hàng.

## Luồng UI dự kiến cho handoff sau core

Sau hành khách, trước xác nhận: mục “Gửi hàng kèm chuyến” tùy chọn, không cần đổi toàn bộ stepper ngay.
Các subview: bật gửi hàng → danh sách kiện → thêm/sửa → điểm gửi/nhận → tóm tắt.
Khứ hồi chọn rõ lượt đi/lượt về và giữ draft độc lập. Màn xác nhận tách tiền vé, ưu đãi, phí hàng và tổng.
Trong payment, amount/orderCode/QR vẫn theo từng chặng và lấy đúng tổng server; hàng không có QR thanh toán thứ hai.
Agent không tự xử lý validation tài chính, tính giá cuối, retry POST hoặc gọi ApiClient trực tiếp.

## Kiểm thử phải có trước PR

- Parser/HTTP contract: acceptsShipments=false, capacity0/unknown, categories/points thiếu, ID khác tenant/trip,
  quantity/weight/dimensions lỗi và ranh giới40kg/khối lượng quy đổi.
- Regression một chiều không có hàng và khứ hồi không có hàng phải giữ nguyên.
- Payload mỗi chiều đúng cargo/points/hold; bỏ hàng xóa payload cũ; đổi chặng/phiên bỏ response trễ.
- Quote vé/expectedPromotionQuote không bị cộng cargo; QR dùng grand total server, thiếu phí không mặc định0.
- Submit một lần, unknown không replay; partial booking giữ chặng thành công và vận đơn đã biết.
- Widget: hàng loading/error/rỗng, giá pending/estimate, partial create, fields khóa sau POST,320dp/text2x/keyboard.
- Live sau khi UI xong: chỉ target QA được cho phép, booking + shipment + hàng/sức chứa + SePay Test Mode,
  kiểm chứng DB chỉ đọc và ACTIVE_SHIPMENT. Không coi fixture tests là E2E.

## Bước tiếp theo

Codex triển khai model/repository/state/payload và tests core trên nhánh mới này trước.
Khi contract callback/state ổn định mới tạo handoff/worktree cho Agent UI; sau UI sẽ review và test thiết bị.
PR gửi hàng độc lập với PR15 và bản khứ hồi; các nhánh cũ không bị ghi đè.
