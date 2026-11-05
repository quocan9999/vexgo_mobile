# Gửi hàng độc lập — Core Mobile

Cập nhật 05/11/2026. Tài liệu này thay thế snapshot PR #53 SHA 64efe16.
Backend nguồn đã merge: develop e50a928412289a2ea77e392780a8c518ddae40e6.

## Workspace và phạm vi

Worktree vexgo_standalone_shipments_worktree; feature/mobile-standalone-shipments,
base 762764e (nhánh PR #19). PR gửi hàng cần review sau PR cha và retarget develop
khi PR cha được merge. Giữ nguyên thay đổi Agent hiện có. Đợt core không sửa Backend, migration,
DB, dependency hoặc khởi động API. Không tạo booking/ghế hay vật phẩm kèm vé.

## Contract đã nối

- GET /shipments/options: from/to/sendDate DD-MM-YYYY, theo hết các trang; đọc routeId,
  nhà xe, tuyến và minimumEstimatedFee. Không dùng /trips/search/cargo-capacity.
- GET /shipments/categories + GET /shipments/routes/:routeId/route-points.
- POST /shipments/quotes: routeId/sendDate/điểm/items; chỉ gửi dữ liệu cần tính cước,
  không gửi PII người gửi/nhận trong request quote.
- POST /shipments: routeId, sendDate, người gửi/nhận, điểm, items, người trả cước,
  paymentMethod TAI_BEN; Idempotency-Key được sinh tại repository.
- POST /shipments/lookup qua body; GET /shipments và /shipments/:id có auth.

## Invariants

- Draft chỉ tạo mới TAI_BEN, người gửi hoặc người nhận trả cước. Enum ONLINE/SEPAY
  chỉ phục vụ đọc lịch sử; không phát QR chuyển tiền, kể cả đơn lịch sử.
- Trạng thái chọn tuyến và ngày gửi phải khớp draft. Không tạo sức chứa giả để ghép
  CargoOptions của chuyến vào luồng độc lập.
- Quote gắn fingerprint toàn draft, mất hiệu lực khi sửa/tìm/chọn lại, đổi phiên,
  có request mới hoặc quá 2 phút theo đồng hồ local. Đây là giới hạn freshness của
  client, không phải cam kết khóa giá từ Backend; Backend vẫn quyết định cước.
- Request epoch chặn quote/options trễ thay thế state mới. Báo giá lỗi xóa giá cũ.
- Khóa idempotency giữ nguyên với cùng session và JSON payload. Timeout/5xx/409 hoặc
  2xx không xác minh được -> uncertain. create thường bị chặn; retryUncertainCreation
  là hành động rõ ràng phát lại cùng khóa và payload, không tạo khóa mới để né uncertain.
- Khóa/payload/recovery chỉ trong bộ nhớ. Chưa có phục hồi qua kill app; sau kill phải
  tra cứu/hỗ trợ trước khi tạo lại. Không lưu PII bằng SharedPreferences.
- Response được so identity, tuyến/nhà xe đã chọn, ngày gửi, hai điểm, tên/số điện thoại,
  người trả/phương thức, các kiện (tên/số lượng/khối lượng/loại/kích thước) và tổng tiền.
- Chi tiết hỗ trợ tripId/code/giờ/xe null, không dựng ID hoặc ngày giả. Deadline mang
  hàng lấy dropoffDeadline từ server, tách khỏi paymentExpiresAt. Không lấy deadline
  thanh toán tại bến để tuyên bố khách đã quá hạn mang hàng.
- Model giữ estimatedFee/confirmedAt/paidAmount/outstandingAmount nếu endpoint trả.
  Response tạo có thể chưa chứa các trường này: giữ null, không tự suy luận tiền đã thu.
- Chưa thanh toán chỉ từ một lần tạo đơn. verifiedPayment cần dữ liệu server và còn
  mới; unknown/reconciliation không được chuyển thành đã thanh toán.
- Session invalidation xóa state/PII và bỏ late response. Single-flight bảo vệ POST;
  không gửi request guest bằng credential tài khoản vừa đăng nhập trong lúc chờ storage.

## API của state cho Agent UI

ShipmentRoute, state.routes/selectedRouteId/sendDate; searchRoutes/selectRoute;
state.options chứa routeId/categories/senders/receivers.
updateDraft, refreshQuote, state.quote/quoting/quoteError, hasCurrentQuoteFor(draft),
invalidateQuote, clearRouteSelection, create, retryUncertainCreation.
lookup/loadMine/openDetail/recoverKnownCreation giữ trách nhiệm hiện có.

UI đã được nối tối thiểu: tìm nhà xe, bỏ online, báo cước rồi xác nhận lần hai,
đơn chưa phân chuyến. Agent tiếp tục tinh chỉnh trải nghiệm theo handoff UI.

## Kiểm chứng và giới hạn

Đã thực thi 34/34 test trong standalone_shipments_core_test.dart và
standalone_shipments_ui_test.dart: 24 core/HTTP fixture và 10 widget test.
Bao gồm counter-only, null trip, quote hết hạn/lỗi/sai loại/trả trễ,
đổi tuyến/phiên, single-flight, retry cùng khóa/payload và khóa mới khi payload
thay đổi sau lỗi từ chối rõ ràng. Các test VietQR cũ được đổi sang kiểm tra
không có hành động chuyển tiền theo contract mới, không bỏ kiểm tra tiền.

Test và analyzer của lần cập nhật được lưu ngoài Git ở:
mobile-qa-evidence/standalone-shipments-develop-tests.log và
mobile-qa-evidence/standalone-shipments-develop-analyze.log.
Test HTTP fixture/widget, không gọi đó là API/MySQL live hoặc device E2E.
Cần đối chiếu/nâng DB local đúng migration và chạy API develop trước khi live test.
Không chạy migration/seed hoặc tạo vận đơn thật trong đợt cập nhật này.
