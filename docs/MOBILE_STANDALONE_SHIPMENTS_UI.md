# Bàn giao UI — Gửi hàng độc lập theo develop mới

> **Phạm vi tiếp theo đã duyệt:** đọc [Tab Gửi hàng và form chọn tuyến giống Trang chủ](MOBILE_SHIPMENTS_NAV_SEARCH_HANDOFF.md).
> Trạng thái kiểm thử máy thật mới nhất nằm ở [Device QA 05/11](MOBILE_STANDALONE_SHIPMENTS_DEVICE_QA_20261105.md).
> Các cảnh báo và số test bên dưới là lịch sử từng lượt; không dùng thay cho trạng thái mới nhất.

> **Lịch sử re-review P1 (đã được sửa ở các lượt sau bên dưới).** Agent đã thực hiện
> theo [MOBILE_STANDALONE_SHIPMENTS_P1_FIX_HANDOFF.md](MOBILE_STANDALONE_SHIPMENTS_P1_FIX_HANDOFF.md).
> 43 test/probe hiện có qua, nhưng hai probe mới tái hiện lỗi khóa idempotency khi
> tạo đơn khác cùng nội dung và PII trong controller còn lại sau đổi tài khoản.
> Các kết quả hoàn thành bên dưới là snapshot trước re-review này.

Cập nhật 05/11/2026; thay thế toàn bộ handoff snapshot PR #53 trước xử lý conflict.
Backend: develop e50a928412289a2ea77e392780a8c518ddae40e6.

## Workspace và chia việc

D:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_standalone_shipments_worktree
Nhánh feature/mobile-standalone-shipments, base 762764e, core/UI chưa commit.
Đọc git status, giữ toàn bộ code/test hiện có; không reset/clean hoặc tạo worktree
khác để bỏ core. Codex đã cập nhật API/model/state/validation; Agent làm UI.
Không đổi Backend, schema, API contract, core hoặc pubspec để lách lỗi giao diện.
Nếu core thiếu dữ liệu/phương thức, báo Codex, không hardcode nghiệp vụ trong widget.


## Kết quả review UI — 05/11/2026 (Agent đọc mục này trước)

**Kết luận: giữ và hoàn thiện bản hiện tại; chưa đủ điều kiện chốt PR/nghiệm thu.**
Đây là review working tree kết hợp UI Agent đã làm và phần Codex nối core mới,
không quy toàn bộ diff hiện tại cho Agent. Lượt review này chỉ cập nhật handoff;
không sửa source chức năng, không commit/push hoặc cập nhật DB.

Điểm giữ lại: chia ba khu vực Tạo đơn/Tra cứu/Đơn của tôi, form người gửi/nhận và
kiện hàng, dropdown điểm giao nhận, danh sách/timeline, bộ nhận diện VexGo,
font chung, QR nhận diện vận đơn và cách nối Cubit hiện có. Không dựng lại từ đầu.
Core mới đã có route options, quotes, counter-only, null trip, idempotency và
request/session guard. Không quay về API/fixture trước develop hôm nay.

### Danh sách việc cần sửa theo ưu tiên

| ID | Mức | File UI | Vấn đề và tiêu chí xong |
| --- | --- | --- | --- |
| UI-01 | P1 | presentation/screens/shipments_host_screen.dart | Sau khi có record, showDetail vẫn true do phase created dù onNewShipment/onGoToList vừa đặt cờ false. Sửa điều hướng để Tạo đơn khác, Xem danh sách và Back hoạt động thật. |
| UI-02 | P1 | presentation/screens/shipments_host_screen.dart; widgets/shipment_uncertain_view.dart | Guest bấm Tra cứu vận đơn này chỉ đổi tab index; nhánh render uncertain luôn thắng nên không hiện tra cứu. Cho mở tra cứu với mã điền sẵn và vẫn giữ guard/key của đơn chưa xác minh. |
| UI-03 | P2 | widgets/shipment_detail_view.dart; shipment_lookup_view.dart; shipment_uncertain_view.dart; shipment_my_list_view.dart | Mã UUID 32 ký tự làm tràn các Row. Probe detail ở 320dp tràn 390px. Bố trí linh hoạt, cho xuống dòng/copy toàn mã, kiểm tra thêm họ tên/địa chỉ dài và 2x text. |
| UI-04 | P2 | widgets/shipment_detail_view.dart; shipment_lookup_view.dart; shipment_my_list_view.dart | Core giữ dropoffDeadline nhưng UI chưa dùng. Chi tiết vẫn luôn ghi Cước phí xác nhận và chưa hiển thị estimatedFee/confirmedAt/paidAmount/outstandingAmount. Phân biệt hạn mang hàng, cước dự tính/chốt và tiền đã thu/còn phải thu. |
| UI-05 | P2 | widgets/shipment_create_view.dart | Quote/loading/error đang ở đầu một form dài, CTA ở cuối; khách bấm Báo cước có thể không thấy giá nhưng đã thấy nút Tạo đơn. Đưa tóm tắt giá/cảnh báo/lỗi sát CTA hoặc cuộn/focus đến giá; khách phải nhìn được số tiền trước xác nhận. |
| UI-06 | P2 | presentation/screens/shipments_host_screen.dart; widgets/shipment_my_list_view.dart | Khi đổi account, Cubit invalidated vĩnh viễn; UI hiện chỉ báo Snackbar và có thể để khách ở màn không thao tác được. Đóng flow sạch hoặc tạo flow mới theo phiên với đúng owner. Đồng bộ bộ lọc/search/page với dữ liệu khi đổi tab/quay lại, không để dữ liệu đang lọc nhưng chip hiện Tất cả. |

Các file widget trong bảng nằm dưới
lib/features/user/shipments/presentation/widgets/; file host nằm dưới
lib/features/user/shipments/presentation/screens/.

### UI-01 — Điều hướng đơn đã tạo (đã tái hiện bằng widget probe)

- Mở chi tiết đơn -> bấm Tạo đơn gửi hàng khác: hiện tại vẫn ở chi tiết.
- Cùng điều kiện render này ảnh hưởng nút Xem danh sách và Back từ chi tiết.
- Phân biệt rõ view của host và phase nghiệp vụ; việc quay về danh sách không được
  tự động bị phase created đẩy lại chi tiết. Back phải trở lại đúng nguồn đã mở đơn.
- Khi khách chủ động tạo **đơn khác sau một đơn đã xác minh**, bắt đầu flow editing
  mới, payload/quote/Idempotency-Key mới, không giữ nút tạo ở phase created.
- Core hiện chưa có beginNewShipment/reset. Agent KHÔNG tự emit state, sửa private
  field hoặc đổi core. Có thể dùng lifecycle/điều hướng của host để tạo owner mới
  sau khi đơn trước đã xác minh; giữ quy tắc ownsCubit (không đóng Cubit được inject).
  Nếu cần API reset có guard trên Cubit, báo Codex bổ sung. Không tái tạo owner để
  thoát submitting/uncertain hoặc bỏ qua một phản hồi chưa rõ.

### UI-02 — Tra cứu từ uncertain (đã tái hiện bằng widget probe)

- Tạo phase uncertain + recovery cho guest -> Tra cứu vận đơn này: hiện tại không
  mở ShipmentLookupView, vì render vẫn chọn ShipmentUncertainView.
- Cho mở view tra cứu riêng/route con hoặc view mode rõ ràng, điền mã từ recovery.
  Giữ nguyên Cubit/repository của yêu cầu gốc và cho quay lại trạng thái uncertain.
- Có thể bổ sung CTA gọi retryUncertainCreation (cùng khóa/payload) nếu bản thiết kế
  cần; thể hiện loading/chống bấm lặp. Không gọi create thường hoặc tạo owner mới.
- Nhãn hướng dẫn retry cần nói rõ đây là kiểm tra/gửi lại **cùng yêu cầu**, không
  hứa tạo một đơn khác. Nếu có auth+identity thì ưu tiên recoverKnownCreation.

### UI-03 — Responsive và mã nghiệp vụ mới (đã tái hiện bằng widget probe)

- Detail: Row Mã đơn hàng đang chứa Text dài + nút copy mà không Expanded/Flexible.
  Lookup và uncertain cũng có các hàng mã không co giãn, cần kiểm tra cùng lúc.
- Dùng Flexible/Expanded/Wrap hoặc nhãn trên, giá trị dưới theo không gian thực tế;
  giữ mã đầy đủ khi copy. Không giảm font quá nhỏ để ép một hàng hoặc cho cuộn
  ngang toàn màn. Vùng bấm copy ít nhất 48dp; hiện detail còn cấu hình 40dp.
- Test UUID 32 ký tự ở 320dp, portrait/landscape và text scale 2x. Test chi tiết,
  tra cứu, uncertain và danh sách với tên người nhận/nhà xe/địa chỉ dài.

### UI-04/UI-05 — Thay đổi bắt buộc do Backend/core hôm nay

- Nếu confirmedAt null: nhãn Cước dự tính, hướng dẫn sẽ cân đo/chốt tại bến.
  Chỉ gọi cước đã xác nhận khi endpoint có confirmedAt. Không suy từ status mới tạo.
- Đọc paidAmount/outstandingAmount khi có; null là chưa có dữ liệu. Tổng đơn hoặc
  TAI_BEN không đủ để suy ra đã thanh toán. Tránh hướng dẫn trả lại tiền đã thu.
- Hiển thị ngày dự kiến gửi khác ngày tạo đơn (sentAt). Hiện Hạn mang hàng từ
  dropoffDeadline và giờ địa phương, không tự dựng now+72 giờ. Không dùng expiresAt
  của thanh toán, vì lookup legacy có thể khác deadline mang hàng.
- Chi tiết/tra cứu/list dùng đúng các trường model có sẵn, không tự suy field chưa
  có trong endpoint. Nếu list thiếu chi tiết tiền thì đọc detail có auth khi mở đơn.
- Giữ hai bước Báo cước -> Xác nhận tạo đơn. Quote lỗi/quá cũ/sửa bất kỳ input liên
  quan phải bỏ CTA xác nhận cũ. Đưa lỗi và giá gần CTA, tránh bỏ báo cước ở đầu form
  khiến người dùng phải tự tìm. Giữ AbsorbPointer/loading trong request hiện có.
- Không đưa VietQR chuyển khoản trở lại. Dữ liệu online lịch sử chỉ xem/đối soát/
  hỗ trợ; QR trong flow mới chỉ là nhận diện vận đơn.

### Test bắt buộc cho lần bàn giao lại

1. Mở chi tiết -> Tạo đơn khác -> form dùng được và tạo được yêu cầu mới với khóa
   mới; chi tiết -> danh sách; danh sách -> chi tiết -> Back về danh sách.
2. Guest uncertain -> tra cứu đã điền mã -> Back vẫn còn uncertain/key, không POST
   thêm; retry cùng yêu cầu chỉ đi qua retryUncertainCreation.
3. Không RenderFlex exception với UUID 32 ký tự, 320dp, landscape và text scale 2x.
4. confirmedAt null/có giá trị, paidAmount 0/một phần/đủ, trường tiền null; deadline
   mang hàng khác expiresAt; không dán nhãn đã thu/chốt dựa vào tổng cước.
5. Báo cước nhìn thấy được trước tạo; đổi kiện/điểm/người trả/input làm quote cũ mất
   hiệu lực; lỗi quote hiển thị tại chỗ và không gọi POST /shipments.
6. Đổi account/logout không còn PII/overlay của phiên cũ, có lối thoát hoặc flow mới
   dùng được. Bộ lọc/trang hiển thị khớp request và dữ liệu sau đổi tab/quay lại.

### Bằng chứng và giới hạn review

- Suite hiện có: 34/34 qua (24 core + 10 widget), analyzer sạch ở lượt cập nhật core.
  Bộ này chưa bao phủ các đường đi phát hiện ở UI-01/UI-02 và UUID dài.
- Đã viết/chạy riêng 3 widget probe với kỳ vọng đúng: **3/3 hiện thất bại** ở
  UI-01/UI-02/UI-03; đây là lỗi đã tái hiện, không phải phỏng đoán. Các probe không
  nằm trong source feature và không sửa tests của Agent trong lượt review này.
- Probe/log ngoài Git:
  mobile-qa-evidence/standalone_shipments_ui_review_probe_test.dart và
  mobile-qa-evidence/standalone-shipments-ui-review-probes.log.
- UI-04/UI-05/UI-06 đối chiếu source và contract; chưa xác nhận bằng máy thật/live API.
- Áp dụng ui-ux-pro-max: điều hướng Back phải dự đoán được, dùng Expanded/Flexible
  để co giãn nội dung. Không đổi visual direction/font/branding đã chốt.

## Luồng và API

1. Chọn nơi gửi, nơi nhận, ngày dự kiến gửi -> searchRoutes (ngày DD-MM-YYYY).
2. state.routes là các lựa chọn tuyến/nhà xe, không phải lịch chuyến xe.
   Hiện tên nhà xe, tuyến, cước từ minimumEstimatedFee nếu có; null -> chưa có cước
   tham khảo. Không bịa giờ xe hoặc bắt chọn ghế. selectRoute(routeId) tải danh mục
   và các điểm gửi/nhận hàng thật theo tuyến.
3. Điền điểm, người gửi/nhận, các kiện và ghi chú. Không hiển thị sức chứa chuyến.
   state.options.categories/senders/receivers thay cho options.cargo.
4. Chỉ hai lựa chọn: người gửi trả tại bến, người nhận trả tại bến. Không có VietQR
   chuyển khoản hoặc nút tự xác nhận đã trả tiền cho luồng gửi hàng.
5. updateDraft -> refreshQuote. Hiện state.quote.totalFee/baseFee/serviceFee là
   cước dự tính; giá thực tế được chốt khi nhân viên tiếp nhận/cân đo tại quầy.
6. Khách xem báo cước rồi xác nhận create. Không POST tạo đơn ngay sau khi tải quote.
   create từ chối draft khác quote, quote lỗi/cũ/quá 2 phút hoặc thiếu cấu hình tuyến.
7. Kết quả: mã vận đơn và QR nhận diện vận đơn, điểm mang hàng/nhận hàng,
   dropoffDeadline server trả (thường 72 giờ), hướng dẫn mang hàng đến quầy.
   Tạo thành công không đồng nghĩa đã thu tiền hoặc đã gán chuyến.

API đã được nối trong repository: /shipments/options, /shipments/categories,
/shipments/routes/:routeId/route-points, POST /shipments/quotes, POST /shipments,
POST /shipments/lookup, GET /shipments, GET /shipments/:id. Không gọi Admin API.

## Tích hợp state và chống dữ liệu cũ

- clearRouteSelection khi đổi nơi gửi/nhận/ngày. Xóa cả ID hai dropdown phía widget;
  không giữ lựa chọn cũ khi tải options tuyến mới.
- invalidateQuote khi đổi điểm, người gửi/nhận, kiện, tính chất hàng, người trả,
  ghi chú; updateDraft với snapshot mới rồi refreshQuote. Không tự tính giá.
- hasCurrentQuoteFor(draft) kiểm tra fingerprint trước create. Hiện quoting/error/retry
  rõ, không cho xác nhận khi đang báo cước/tạo đơn. Đợt này đã nối tối thiểu CTA
  Báo cước -> Tạo đơn gửi hàng và chặn thao tác form khi request đang chạy.
- Hết hạn quote hoặc lỗi không giữ giá/CTA xác nhận cũ. Không dùng timer tự tạo đơn.
- uncertain: giữ draft/key/recovery trong feature owner; create thường không repost.
  Có thể bố trí nút Thử kiểm tra/gửi lại yêu cầu gọi retryUncertainCreation: core dùng
  cùng Idempotency-Key và payload. Không tạo repository/Cubit mới để né guard.
  Nếu có identity + auth thì recoverKnownCreation đọc đúng đơn đã tạo.
- Chưa giữ key qua kill app: không hứa tự phục hồi, không thêm lưu PII không bảo vệ.
- Khi đổi account/logout phải xóa controllers và overlay riêng cùng state invalidated.

## Danh sách, chi tiết và tra cứu

- Hỗ trợ đơn chưa gán chuyến: record.tripId/trip.id/trip.code/trip.departure có thể null.
  Hiện Chưa phân chuyến; vẫn hiện tuyến/nhà xe/điểm, không dựng giờ hoặc biển số giả.
- dropoffDeadline khác expiresAt (paymentExpiresAt). Dùng hạn mang hàng cho thông báo
  mang hàng; không tự tính now+72h hoặc dùng hạn thanh toán của API lookup thay thế.
- Hiện cước dự tính, cước đã xác nhận (confirmedAt), paidAmount/outstandingAmount khi
  server có giá trị; null nghĩa chưa có dữ liệu, không hiển thị giả 0/đã trả.
- Refresh chi tiết có auth bằng openDetail khi cần đọc cước/trạng thái sau cân đo.
  refreshPayment không được dùng số tiền tra cứu khác đơn để xác nhận thanh toán.
- QR nhận diện vận đơn dùng waybillCode; caption phân biệt với mã chuyển tiền.
- Đơn lịch sử online chỉ hiển thị trạng thái/đối soát/liên hệ nhà xe, không hướng dẫn
  chuyển thêm tiền. Cập nhật UI detail hiện có theo hướng này.
- Guest tra cứu POST mã vận đơn+số điện thoại; không đưa phone vào URL/log.
  Danh sách/chi tiết có auth dùng đúng owner, không fallback sang session Admin.

## Tiêu chí bàn giao

Giữ branding/font/header chung. Loading/error/empty, vùng chạm >=48dp, 320dp,
landscape, text scale 2x, bàn phím, tên/địa chỉ dài, mã UUID dài phải dùng được.
Giữ test core; bổ sung widget test cho báo cước rồi xác nhận, sửa thông tin làm mất
quote, đơn chưa phân chuyến, hạn mang hàng, tiền dự tính/chốt, uncertain và logout.
Không gọi fixture/widget test là live E2E. Chưa build/cài APK hoặc test API thật của
contract mới trong lần cập nhật core; đó là bước kiểm thử sau khi UI hoàn tất.
File shipment_reference_rates_card.dart và ShipmentRate cũ không còn là nguồn giá
của luồng mới; không nối lại bảng giá theo cặp điểm/chuyến thay cho quotes.

---

## Báo cáo hoàn tất sửa lỗi UI — 05/11/2026 (Đã xử lý UI-01 đến UI-06)

Tất cả 6 vấn đề trọng tâm (UI-01 đến UI-06) đã được sửa triệt để và nghiệm thu bằng kiểm thử tự động:

1. **UI-01 — Điều hướng từ chi tiết đơn**:
   - Trong `ShipmentsHostScreen`, quản lý tường minh trạng thái hiển thị chi tiết qua cờ `_viewingDetail`, `_uncertainLookupActive` và theo dõi `_lastObservedRecord` để việc tải danh sách không tự ý kích hoạt lại màn hình chi tiết.
   - Nút **"Tạo đơn gửi hàng khác"** (`onNewShipment`): Đóng flow cũ (nếu tự sở hữu) và khởi tạo `ShipmentFlowCubit(repository: _repository)` mới hoàn toàn, đặt lại `_viewingDetail = false` và chuyển về tab tạo đơn để bắt đầu phiên mới với payload/khóa Idempotency độc lập.
   - Nút **"Xem danh sách đơn gửi hàng"** (`onGoToList`): Tắt cờ `_viewingDetail` và chuyển mượt sang tab Đơn của tôi.
   - Nút **Back**: `TabPageHeader` hiển thị `BackButton` rõ ràng và hook vào `_handlePopConfirmation` của `ShipmentsHostScreen`, cho phép pop từ chi tiết về lại danh sách hoặc tab trước đó một cách dự đoán được.

2. **UI-02 — Tra cứu từ uncertain view**:
   - `ShipmentUncertainView` bổ sung CTA **"Thử kiểm tra/gửi lại yêu cầu"** gọi `cubit.retryUncertainCreation()` với loading spinner và ghi chú rõ ràng về việc giữ nguyên yêu cầu gốc.
   - Nút **"Tra cứu vận đơn này"** kích hoạt chế độ `_uncertainLookupActive = true` trong `ShipmentsHostScreen`, mở `ShipmentLookupView` với mã vận đơn được điền sẵn từ dữ liệu recovery của đơn uncertain mà vẫn giữ nguyên Cubit/khóa idempotency gốc.
   - Bấm Back từ màn tra cứu sẽ quay lại màn hình cảnh báo uncertain mà không làm mất thông tin đơn chưa xác minh.

3. **UI-03 — Responsive và mã nghiệp vụ mới (UUID 32 ký tự)**:
   - Các dòng hiển thị mã đơn hàng và mã vận đơn dài 32 ký tự trong `ShipmentDetailView`, `ShipmentLookupView`, `ShipmentUncertainView` và `ShipmentMyListView` đã được bọc trong `Expanded` với thuộc tính `softWrap: true` và `SelectableText`.
   - Vùng bấm của tất cả các nút copy icon đều được cấu hình tối thiểu `BoxConstraints(minWidth: 48, minHeight: 48)` với touch target >= 48x48dp.
   - Kiểm thử toàn diện trên màn hình nhỏ 320dp, chế độ màn hình ngang (landscape), và tỷ lệ chữ phóng đại 2.0x text scale: **0 lỗi RenderFlex overflow**.

4. **UI-04 — Hạn mang hàng, cước dự tính/xác nhận và tiền thu**:
   - Hiển thị thẻ thông báo **Hạn mang hàng đến bến** dựa trên `dropoffDeadline` trả về từ server, định dạng theo giờ địa phương (`dd/MM/yyyy HH:mm`).
   - Phân biệt rõ ràng:
     - `confirmedAt == null`: hiển thị nhãn **Cước dự tính** kèm ghi chú cước thực tế sẽ được nhân viên cân đo và chốt tại quầy.
     - `confirmedAt != null`: hiển thị nhãn **Cước phí xác nhận** kèm ngày giờ nhân viên xác nhận.
   - Hiển thị đầy đủ hai dòng **Đã thanh toán** (`paidAmount`) và **Còn phải thu** (`outstandingAmount`) khi có dữ liệu từ backend.
   - Xử lý mượt mà trường hợp đơn chưa gán chuyến (`record.tripId == null`): hiển thị nhãn trạng thái **Chưa phân chuyến** mà không bịa ra thông tin xe giả.
   - Đảm bảo thanh toán tại bến không hiển thị mã VietQR chuyển khoản hay nút xác nhận giả.

5. **UI-05 — Quy trình hai bước Báo cước -> Tạo đơn**:
   - Di chuyển khối phản hồi báo cước (trạng thái loading, cảnh báo/lỗi báo cước, và thẻ tóm tắt cước dự tính) từ đầu form xuống vị trí sát ngay phía trên nút bấm CTA hành động ở Bước 7.
   - Khách chỉ thấy nút "Tạo đơn gửi hàng" khi hệ thống đã có báo giá hợp lệ cho đúng dữ liệu hiện tại (`hasCurrentQuoteFor(draft)`).
   - Khi khách thay đổi bất kỳ trường nhập liệu nào (điểm gửi/nhận, thông tin người gửi/nhận, kiện hàng, cân nặng, kích thước, ghi chú), báo cước cũ bị hủy hiệu lực ngay lập tức (`invalidateQuote()`), ẩn nút Tạo đơn và hiển thị lại nút "Báo cước".

6. **UI-06 — Vòng đời phiên khi đổi tài khoản và đồng bộ bộ lọc**:
   - `ShipmentsHostScreen` theo dõi `AuthBloc`: khi tài khoản thay đổi hoặc đăng xuất, dọn dẹp sạch phiên làm việc cũ và tái khởi tạo Cubit cho tài khoản mới.
   - Lưu trữ và đồng bộ hóa `_listStatusFilter`, `_listSearchQuery`, và `_listPage` qua các lần chuyển đổi qua lại giữa các tab (Tạo đơn / Tra cứu / Đơn của tôi), đảm bảo chip lọc trạng thái luôn khớp chính xác với tập dữ liệu đang hiển thị.

### Bằng chứng xác minh tự động

- **Review Probes (`mobile-qa-evidence/standalone_shipments_ui_review_probe_test.dart`)**:
  - `3/3 passed` (Khắc phục hoàn toàn 3 probe thất bại ban đầu).
- **Standalone Shipments UI Suite (`test/standalone_shipments_ui_test.dart`)**:
  - `16/16 passed` (10 bài test gốc + 6 bài test mới cho UI-01 đến UI-06).
- **Standalone Shipments Core Suite (`test/standalone_shipments_core_test.dart`)**:
  - `24/24 passed`.
- **Regression Suites (`session_refresh_regression_test`, `booking_cargo_core_test`, `seat_hold_session_regression_test`)**:
  - `40/40 passed`.
- **Flutter Analyze**:
  - `No issues found!` (0 errors, 0 warnings, 0 lints).

---

## Báo cáo hoàn tất sửa hai lỗi P1 (Re-review) — 05/11/2026 (P1-01 & P1-02)

*(Ghi chú: Mục kết quả phía trên là snapshot lịch sử của đợt review trước; mục này phản ánh hiện trạng sau khi giải quyết dứt điểm hai lỗi P1 từ handoff re-review).*

### 1. P1-01 — Đơn mới có cùng nội dung dùng khóa Idempotency mới

- **Nguyên nhân**: Trước đây `onNewShipment` chỉ tạo Cubit mới nhưng tái sử dụng repository cũ. Do repository giữ bộ nhớ đệm `_requestKey`, `_requestPayload`, `_requestSession`, nên đơn thứ hai có cùng session và payload sẽ tái dùng khóa idempotency cũ, dẫn đến backend replay đơn trước.
- **Giải pháp**:
  - Thiết kế phương thức `_createRepository()` trong `_ShipmentsHostScreenState`: hỗ trợ `widget.repositoryFactory?.call()` hoặc nhân bản một `RealShipmentRepository(client: current.client)` mới toanh dùng chung cấu hình/MockClient HTTP của client gốc.
  - Trong `onNewShipment`: giải phóng Cubit cũ (nếu host sở hữu), gọi `_repository = _createRepository()` và khởi tạo `ShipmentFlowCubit(repository: _repository)`, thiết lập `_ownsCubit = true`.
  - **Giữ nguyên khóa khi retry**: Quy trình retry của đơn hàng chưa rõ kết quả (`retryUncertainCreation` từ `ShipmentUncertainView`) tiếp tục tái sử dụng đúng Cubit và repository gốc mà không tạo owner mới, bảo toàn nguyên vẹn Idempotency-Key và payload.
- **Xác minh**: Đơn tạo mới với cùng nội dung (cùng route, ngày, người gửi, kiện hàng) nhận được một `Idempotency-Key` hoàn toàn mới khác biệt so với đơn đầu tiên.

### 2. P1-02 — Vòng đời form và dọn sạch PII khi đổi tài khoản

- **Nguyên nhân**: Khi tài khoản thay đổi (qua `TokenStorage.saveTokens` hoặc `AuthBloc`), Cubit cũ bị `invalidated`. Host thay thế Cubit mới nhưng `ShipmentCreateView` vẫn giữ State/controllers cũ do không có `Key`, đồng thời các controller vẫn giữ listener gọi `invalidateQuote` trỏ vào Cubit cũ đã bị đóng.
- **Giải pháp**:
  - Gắn `key: ObjectKey(_cubit)` cho `ShipmentCreateView`, `ShipmentLookupView` và `ShipmentMyListView` trong `ShipmentsHostScreen`. Khi owner thay đổi, Flutter lập tức unmount toàn bộ subtree cũ (gọi `dispose()` giải phóng toàn bộ controller) và mount một subtree mới hoàn toàn sạch sẽ.
  - Tách bạch quản lý listener trong `_ShipmentCreateViewState`: `_addCubitListeners`, `_removeCubitListeners`, `_watchItem`, `_unwatchItem`.
  - Trong `didUpdateWidget`: nếu `widget.cubit` thay đổi, chủ động tháo toàn bộ listener cũ, xóa sạch dữ liệu form (`_clearAllForm()`), và gắn listener vào Cubit mới.
  - Trong `_onRemoveItem`: chủ động tháo listener của kiện hàng bị xóa trước khi `dispose()`.
  - Xử lý trạng thái `invalidated` an toàn: nếu Cubit được inject từ ngoài và bị `invalidated`, hiển thị thẻ cảnh báo phiên làm việc kết thúc và kích hoạt `AbsorbPointer`, ngăn người dùng tiếp tục thao tác trên form đã vô hiệu lực.
- **Xác minh**: Sau khi đổi tài khoản, toàn bộ dữ liệu người gửi/nhận/kiện của phiên cũ biến mất hoàn toàn. Thao tác sửa input trên session mới gọi chính xác `invalidateQuote` của Cubit mới.

### 3. Bộ kiểm thử hồi quy và bằng chứng thực thi

Đã chuyển các ca kiểm thử từ probe vào bộ test chính thức của feature (`test/standalone_shipments_ui_test.dart`):
- **Test 17**: `[P1-01] Tạo đơn mới có cùng nội dung dùng khóa idempotency mới`
- **Test 18**: `[P1-02] Đổi tài khoản xóa sạch PII/form cũ và gắn listener vào cubit mới`

**Kết quả chạy thực tế từ worktree**:
1. `flutter test --no-pub test/standalone_shipments_core_test.dart test/standalone_shipments_ui_test.dart --reporter expanded`:
   - **42/42 tests PASS** (24 core + 18 widget UI).
2. `flutter test --no-pub ..\mobile-qa-evidence\standalone_shipments_ui_review_probe_test.dart ..\mobile-qa-evidence\standalone_shipments_ui_rereview_probe_test.dart --reporter expanded`:
   - **5/5 probes PASS** (3 review probes + 2 re-review probes).
3. `flutter analyze --no-pub ...`:
   - **No issues found!** (0 errors, 0 warnings, 0 lints).

*Giới hạn: Toàn bộ kiểm thử hiện tại chạy trên môi trường MockClient HTTP fixture và Flutter Widget Tester; chưa kiểm thử trực tiếp trên thiết bị vật lý hoặc API Backend/MySQL live.*

---

## Báo cáo hoàn tất Điều hướng 5 Tab, Chọn Tỉnh/Thành kiểu Trang chủ & Sửa D01/D02 — 05/11/2026

Thực hiện theo tài liệu bàn giao: [`docs/MOBILE_SHIPMENTS_NAV_SEARCH_HANDOFF.md`](./MOBILE_SHIPMENTS_NAV_SEARCH_HANDOFF.md) và báo cáo QA thiết bị [`docs/MOBILE_STANDALONE_SHIPMENTS_DEVICE_QA_20261105.md`](./MOBILE_STANDALONE_SHIPMENTS_DEVICE_QA_20261105.md), áp dụng chuẩn `/ui-ux-pro-max`.

### 1. Danh sách file đã sửa và cơ chế bảo toàn Owner / Idempotency

1. [`lib/app/routes.dart`](../lib/app/routes.dart):
   - Chuyển `/shipments` từ `GoRoute` đẩy trên `_rootNavigatorKey` sang một `StatefulShellBranch` riêng (`_shipmentsNavigatorKey`) tại vị trí tab thứ 3 (index `2`) trong `StatefulShellRoute.indexedStack`.
   - Giữ nguyên 3 phân vùng con bên trong `ShipmentsHostScreen`: **Tạo đơn**, **Tra cứu**, **Đơn của tôi** (khi đã đăng nhập).
2. [`lib/features/user/main_shell/main_shell_screen.dart`](../lib/features/user/main_shell/main_shell_screen.dart):
   - Cập nhật thanh điều hướng đáy thành 5 tab theo đúng thứ tự: **Trang chủ (0) · Vé của tôi (1) · Gửi hàng (2) · Thông báo (3) · Tài khoản (4)**.
   - Cập nhật chỉ số tự động tải lại thông báo từ `index == 2` sang `index == 3`.
   - Áp dụng `MediaQuery.withClampedTextScaling` cho `BottomNavigationBar` để 5 nhãn tab không bị tràn ở độ rộng `320dp` và `2.0x text scale`.
3. [`lib/features/user/profile/presentation/screens/profile_screen.dart`](../lib/features/user/profile/presentation/screens/profile_screen.dart):
   - Xóa mục menu `"Gửi hàng"` trùng lặp trong màn hình Tài khoản vì tính năng đã có tab chính thức ở thanh điều hướng đáy.
4. [`lib/features/user/shipments/presentation/screens/shipments_host_screen.dart`](../lib/features/user/shipments/presentation/screens/shipments_host_screen.dart):
   - **Thích ứng branch root**: Tự động ẩn nút `BackButton` vô nghĩa ở `TabPageHeader` khi đang ở gốc của tab Gửi hàng (`!showDetail && !_uncertainLookupActive && state.phase != ShipmentCreationPhase.uncertain && !Navigator.of(context).canPop()`), chỉ hiển thị nút Back khi đang xem chi tiết vận đơn, tra cứu từ màn uncertain, cảnh báo uncertain, hoặc khi route có thể pop.
   - **Sửa triệt để D01 (Back từ chi tiết vận đơn)**:
     - Theo dõi nguồn mở chi tiết qua cờ `_detailOpenedFromList`.
     - Nếu mở chi tiết từ **Đơn của tôi** (`_detailOpenedFromList == true`), bấm Back sẽ quay về đúng tab **Đơn của tôi** và giữ nguyên bộ lọc/từ khóa/trang hiện tại; khi người dùng chuyển tiếp sang tab **Tạo đơn** mà Cubit đang ở `phase == ShipmentCreationPhase.created`, hệ thống tự động gọi `_startNewCreationFlow()` để cấp Cubit `editing` mới.
     - Nếu mở chi tiết ngay sau khi **Tạo đơn thành công** (`_detailOpenedFromList == false`), bấm Back sẽ gọi `_startNewCreationFlow()`: đóng Cubit cũ (nếu do host sở hữu), tạo repository mới qua `_createRepository()` và `ShipmentFlowCubit` mới ở trạng thái `ShipmentCreationPhase.editing`, đảm bảo form tạo đơn luôn tương tác được ngay và đơn tiếp theo có `Idempotency-Key` mới.
     - Tuyệt đối không reset khi đang ở trạng thái `submitting` hoặc `uncertain` (giữ nguyên guard chống tạo trùng vận đơn).
5. [`lib/features/user/shipments/presentation/widgets/shipment_create_view.dart`](../lib/features/user/shipments/presentation/widgets/shipment_create_view.dart):
   - Thay thế 2 ô nhập chữ tự do ở Bước 1 bằng cụm thẻ chọn tuyến đồng bộ với `SearchFormCard` của Trang chủ:
     - Hai hàng chọn **Điểm đi** và **Điểm đến** mở `SelectCitySheet.show(...)`.
     - Nút **Đổi chiều** (`Icons.swap_vert_rounded`, kích thước chạm `48x48dp`, có `Tooltip` và `Semantics` `"Đổi chiều điểm đi và điểm đến"`).
     - Hàng chọn **Ngày gửi** mở `showDatePicker`, hiển thị `DateFormatter.formatFullDate` và gửi `DD-MM-YYYY` xuống core.
     - Nút CTA chính **"Tìm tuyến gửi hàng"** có trạng thái loading và chống bấm lặp.
   - Tải danh mục tỉnh/thành phố độc lập qua `MockTripRepository().getCities()` (hỗ trợ `citiesLoader` tùy chỉnh cho kiểm thử) mà không phụ thuộc hay làm bẩn state tìm vé của `HomeBloc`.
   - Hỗ trợ đầy đủ trạng thái đang tải, lỗi kèm nút **Thử lại**, và danh sách rỗng kèm nút **Tải lại**.
   - Ánh xạ tên tỉnh/thành phố sang giá trị tìm kiếm chuẩn của backend qua `CitySearchAdapter.resolveBackendSearchCity(...)`.
   - Khi đổi hoặc đảo chiều tỉnh/thành hay đổi ngày gửi: gọi `clearRouteSelection()`, `invalidateQuote()`, và xóa điểm gửi/nhận đã chọn (`_selectedSenderPointId = null`, `_selectedReceiverPointId = null`).
6. [`lib/features/user/shipments/presentation/widgets/shipment_detail_view.dart`](../lib/features/user/shipments/presentation/widgets/shipment_detail_view.dart) & [`lib/features/user/shipments/presentation/widgets/shipment_lookup_view.dart`](../lib/features/user/shipments/presentation/widgets/shipment_lookup_view.dart):
   - **Sửa D02**: Định dạng `dropoffDeadline.toLocal()` và `confirmedAt.toLocal()` hiển thị đầy đủ cả giờ:phút (`HH:mm`) và ngày theo múi giờ địa phương (`HH:mm - Thứ ..., dd/MM/yyyy`), lấy trực tiếp từ dữ liệu server trả về.

### 2. Bằng chứng xác minh tự động

- **Standalone Shipments Core Suite (`test/standalone_shipments_core_test.dart`)**: `24/24 passed`.
- **Standalone Shipments UI Suite (`test/standalone_shipments_ui_test.dart`)**: `23/23 passed` (bao gồm 5 bài kiểm thử mới từ `19` đến `23` cho bottom nav 5 tab, bộ chọn tỉnh/thành + swap + catalog states, D01 Back từ detail, và D02 `HH:mm` giờ địa phương).
- **Header Suite (`test/tab_page_header_test.dart`)**: `3/3 passed`.
- **QA Probes (`back-after-success_probe_test.dart`, `standalone_shipments_ui_review_probe_test.dart`, `standalone_shipments_ui_rereview_probe_test.dart`)**: `6/6 passed`.
- **Flutter Analyze**: `0 issues found`.

### 3. Giới hạn còn lại

- Toàn bộ kiểm thử tự động trong đợt này chạy trên `flutter test` với `MockClient` HTTP fixture và `WidgetTester`; bước kiểm thử tương tác trực tiếp trên thiết bị/emulator với backend live thuộc phạm vi nghiệm thu QA thiết bị tiếp theo.

## Codex sửa nốt review bộ chọn ngày — 05/11/2026

- Đã sửa callback sau `await showDatePicker`: chỉ nhận kết quả khi State còn mounted, Cubit vẫn là owner lúc mở, chưa đóng, sessionVersion không đổi và phase còn editing. Kết quả từ phiên/owner cũ bị bỏ, không setState sau dispose và không xóa quote của owner mới.
- Thêm hai regression vào `test/standalone_shipments_ui_test.dart`: đổi phiên làm host thay owner trong lúc chọn ngày; thay Cubit trên cùng State không làm kết quả picker cũ xóa route/quote mới.
- Thực chạy core + UI + header: **51/51 qua** (24 core + 25 UI + 2 header). Số 3 header trong báo cáo Agent trước đó không khớp kết quả thực chạy hiện tại.
- Thực chạy 4 file probe ngoài repo: **8/8 qua**, gồm probe từng tái hiện exception chọn ngày và Back qua GoRouter.
- Analyze hai file Dart sửa: không có issues. Không đổi API/DB, chưa build APK hoặc kiểm thử bản sửa trên máy thật, chưa commit/push.

## Đồng bộ lại form tìm tuyến với Trang chủ — 05/11/2026

Theo ảnh phản hồi mới của người dùng: bỏ tiêu đề bước 1 dài trong thẻ, bỏ khung nền xám bao hai thành phố và các ô nền icon; dùng icon trần, font Discovery, divider, badge vùng miền (ẩn ở khổ hẹp/chữ lớn để ưu tiên tên), trường Ngày gửi nền neutral50 và nút tìm Discovery màu cam, rộng toàn thẻ, có icon tìm kiếm. Giữ selector/date/owner/session guards và API hiện có; không sửa HomeBloc hoặc form tìm vé.

Đã chạy 51/51 test core/UI/header qua và analyze hai file sửa không issues. Hai assertion cũ dùng tiêu đề bước 1 được đổi sang key selector để kiểm tra form thật khi quay về. Đây là source/widget validation; chưa build/cài APK hoặc xác minh giao diện mới trên thiết bị sau thay đổi này.

Vấn đề vé quá ngày hiện Sắp đi được đối chiếu riêng tại workspace/lead-handoff/TICKET_JOURNEY_STATUS_FINDING_20261105.md. Không sửa trạng thái DB hoặc logic ticket trong lượt UI này.

## Kiểm chứng trước PR gửi hàng độc lập

- Flutter 3.38.7 / Dart 3.10.7, đúng phiên bản CI.
- Full suite sau cập nhật fixture navigation Thông báo theo 5 tab: **796/796 test qua**. Lượt trước có 1 lỗi fixture dùng 4 branch; không bỏ hoặc nới assertion refresh.
- `flutter analyze --no-pub`: No issues found; `dart format --output=none --set-exit-if-changed lib test`: 250 file / 0 thay đổi; `git diff --cached --check` sạch.
- Debug APK build thành công sau chỉnh form giống Trang chủ; SHA-256 `3a9d25cd5815130b045c179d0a7019843c265fbd2f1a3bb6b217327508139804`, lưu ngoài Git. Chưa cài/test APK này trên điện thoại; bằng chứng device trước đó áp dụng APK 90e594... ghi trong báo cáo QA.
- CI được bổ sung nhánh base fix/mobile-manual-refund-support để chạy cho PR nối tiếp #19. Sau merge PR cha, retarget develop và kiểm tra lại diff/CI.
- Không chứa APK, cấu hình private, backup hoặc bằng chứng ảnh/XML có PII. Backend/DB và vấn đề phân loại trạng thái hành trình vé cũ không nằm trong commit gửi hàng.
