# Bàn giao Agent — sửa hai lỗi P1 sau re-review gửi hàng

Ngày bàn giao: 05/11/2026. Đây là phạm vi cần thực hiện tiếp; ưu tiên hơn các
kết luận nghiệm thu cũ trong MOBILE_STANDALONE_SHIPMENTS_UI.md.

## Workspace và ranh giới

- Worktree đã tồn tại:
  `D:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_standalone_shipments_worktree`.
- Nhánh `feature/mobile-standalone-shipments`, HEAD `762764e`; feature hiện còn
  uncommitted/untracked. Đọc git status và giữ tất cả thay đổi của người dùng/Agent.
- Backend contract: develop `e50a928412289a2ea77e392780a8c518ddae40e6`.
- Chỉ sửa hai lỗi vòng đời flow dưới đây và test hồi quy trực tiếp. Giữ giao diện,
  route options/quotes/counter-only/null trip và các sửa UI-01…UI-06 đã làm.
- Không đổi Backend, DB, migration, dependency, API payload hoặc luật tính cước.
  Không commit/push/merge trong nhiệm vụ này. Không reset/clean, định dạng hàng loạt,
  hoặc sửa các suite độc lập. Các file generated và thay đổi chỉ xuống dòng không
  phải phạm vi cần gom thêm vào bản sửa.

## Bằng chứng review hiện tại

- Codex đã chạy 24 core + 16 widget + 3 probe cũ: **43/43 qua**.
- Analyzer đúng feature và TabPageHeader: **No issues found**.
- Hai probe mới bên dưới: **2/2 thất bại**, xác nhận hai lỗi P1 còn tồn tại.
  Không dùng 43 test xanh trước đó để kết luận hai tình huống này đã được kiểm tra.
- Đây là kiểm thử repository HTTP fixture + widget; chưa test Backend/MySQL thật
  hoặc điện thoại. Nhiệm vụ sửa và widget test này không cần Docker/API/máy thật.

Probe và log nằm ngoài Git, tại workspace cha:

`mobile-qa-evidence/standalone_shipments_ui_rereview_probe_test.dart`

`mobile-qa-evidence/standalone-shipments-ui-rereview-new-probes.log`

Đọc probe để hiểu setup, rồi chuyển các ca hồi quy cần thiết vào test của feature
với import package/relative phù hợp. Không commit import file:/// tuyệt đối hoặc
phụ thuộc thư mục bằng chứng ngoài repo vào test CI.

## P1-01 — Đơn mới có cùng nội dung bị dùng lại khóa idempotency

### Tái hiện và nguyên nhân

1. Tạo thành công một đơn gửi hàng bằng RealShipmentRepository + HTTP fixture.
2. Mở host ở chi tiết đơn đó, bấm **Tạo đơn gửi hàng khác**.
3. Nhập/chọn đúng cùng route/ngày/người/điểm/kiện/người trả như đơn trước và tạo.
4. Hai POST /shipments vẫn có cùng Idempotency-Key. Probe đã xác nhận header bằng nhau.

Host tạo Cubit mới nhưng tiếp tục truyền `_repository` cũ. Repository giữ
`_requestKey`, `_requestPayload`, `_requestSession`; cùng session/payload thì tái dùng
khóa. Backend dùng khóa và hash payload để trả lại kết quả đơn trước, nên có thể
hiển thị thành công nhưng thực tế không tạo được đơn thứ hai.

Đọc:

- `lib/features/user/shipments/presentation/screens/shipments_host_screen.dart`:
  `_repository`, `onNewShipment`, `_ownsCubit` (vị trí review khoảng dòng 277).
- `lib/data/repositories/shipment_repository.dart`:
  `_requestKey/_requestPayload/_requestSession`, `create` (khoảng dòng 239).
- Backend tham chiếu: `apps/api/src/shipments/shipments.service.ts` xử lý replay
  Idempotency-Key; chỉ đọc, không sửa Backend.

### Kết quả cần đạt

- Sau một đơn **đã xác minh**, khách chủ động chọn đơn khác phải nhận creation
  scope mới. Với cùng session và cùng payload, header mới phải khác header đơn trước.
- Retry của một yêu cầu chưa rõ kết quả phải giữ nguyên repository/scope, khóa và
  JSON payload. Không giải quyết lỗi bằng cách sinh khóa mới cho mọi lần POST.
- Không tái tạo owner hoặc xóa guard trong submitting/uncertain. Không tự chuyển
  uncertain về editing. `retryUncertainCreation` vẫn là đường retry có chủ đích.

### Phạm vi và hướng triển khai

Ưu tiên sửa lifecycle/factory của host để tạo **cả repository và Cubit mới** khi
bắt đầu một đơn khác đã được xác minh. Factory phải dùng đúng cấu hình API và cho
phép test inject repository có HTTP MockClient; không âm thầm dùng API thật trong test.
Giữ rõ quyền sở hữu: không đóng Cubit được truyền vào từ ngoài, không bỏ rơi owner
mà host có trách nhiệm dispose, và không giữ late response của owner cũ.

Không reset private field hoặc gọi emit từ UI. Không sửa core idempotency để bỏ
kiểm tra payload/session. Nếu cần API vòng đời mới trong core thay vì factory ở
host, nêu rõ nhu cầu cho Codex; không tự nới guard để vượt test. Cách factory ở
host có thể giải quyết trong phạm vi UI/lifecycle hiện được giao.

### Test bắt buộc

- Dùng **RealShipmentRepository**, không chỉ FakeShipmentRepository: tạo đơn A,
  bấm đơn khác, gửi lại cùng payload -> hai khóa khác nhau, cả hai flow dùng được.
- Mô phỏng server replay/dedupe: cùng khóa trả cùng shipmentId; khóa mới trả ID mới.
  Xác minh đơn khác có shipmentId khác, không chỉ kiểm tra số lần gọi POST.
- Timeout rồi retry **cùng yêu cầu** -> cùng khóa và body; không tạo scope mới.
- Bấm lặp CTA không tạo nhiều owner hoặc POST đồng thời. Giữ các ca session/single-flight.

## P1-02 — Đổi tài khoản nhưng form vẫn giữ thông tin khách cũ

### Tái hiện và nguyên nhân

1. Mở `ShipmentsHostScreen(repository: ...)` **không inject Cubit**, để host tự sở hữu.
2. Tải tuyến/options, điền tên người gửi của phiên trước.
3. Đổi tài khoản bằng TokenStorage/session thật trong test.
4. Host thay Cubit mới nhưng ShipmentCreateView vẫn dùng State/controllers cũ.
5. Tải tuyến cho phiên mới: tên khách cũ vẫn xuất hiện. Probe đã tái hiện bằng chuỗi
   fixture `Previous account private name`.

Host thay owner ngay khi nhận invalidated. Widget con có thể chỉ thấy state editing
của Cubit mới, nên didUpdateWidget chờ phase invalidated không xóa form. Ngoài ra,
các controller đã addListener(widget.cubit.invalidateQuote) trong initState vẫn
giữ callback của Cubit cũ sau khi owner đổi.

Đọc:

- `presentation/screens/shipments_host_screen.dart`: listener invalidated và builder.
- `presentation/widgets/shipment_create_view.dart`: initState, `_watchItem`,
  didUpdateWidget, `_clearAllForm`, dispose (khoảng dòng 125–156).
- Các view lookup/list và overlay do feature mở, nếu cùng giữ dữ liệu/controller
  qua lần đổi owner.

### Kết quả và hướng sửa

- Dữ liệu của owner trước phải biến mất ngay khi đổi account/logout; chọn tuyến
  lại không được làm dữ liệu cũ xuất hiện trở lại.
- Đồng bộ vòng đời UI với owner/session, ví dụ dùng key riêng theo identity owner
  để dispose/tạo lại toàn subtree có controller. Hoặc xử lý đổi Cubit đầy đủ trong
  didUpdateWidget: tháo listener cũ, xóa dữ liệu, gắn listener mới và quản lý item mới.
- Không chỉ xóa payload trong Cubit hoặc hiển thị Snackbar. Phải kiểm tra controller,
  draft cục bộ, focus và overlay thuộc flow; không pop các route không thuộc feature.
- Các input sau đổi owner phải invalidate quote của **Cubit mới**, không gọi callback
  đã bị đóng. Item được thêm/xóa/tạo lại cũng phải gắn/tháo listener đúng.
- Cân nhắc cả production owner tự quản lý và Cubit được inject. Không tự đóng Cubit
  không thuộc quyền sở hữu; với inject không thể thay owner thì đóng flow sạch hoặc
  báo callback cho bên sở hữu, không để màn hình trông dùng được nhưng Cubit đã invalidated.

### Test bắt buộc

- Host tự tạo Cubit, đang điền PII -> đổi account -> tải tuyến lại: tên/phone/email/
  CCCD/ghi chú/kiện cũ đều trống, không xuất hiện lại sau rebuild.
- Báo giá trong owner mới -> sửa người/kiện: quote mới mất hiệu lực ngay. Test này
  bắt callback vẫn trỏ tới owner cũ, ngay cả khi giao diện đã xóa text thành công.
- Logout khi đang đọc options/quote/detail -> late response không hồi sinh dữ liệu.
- Test inject Cubit: không đóng nhầm Cubit bên ngoài, không để flow bị kẹt âm thầm.

## Lệnh xác minh và bàn giao lại

Chạy từ đúng worktree:

```powershell
flutter test --no-pub test/standalone_shipments_core_test.dart test/standalone_shipments_ui_test.dart --reporter expanded

flutter test --no-pub ..\mobile-qa-evidence\standalone_shipments_ui_review_probe_test.dart ..\mobile-qa-evidence\standalone_shipments_ui_rereview_probe_test.dart --reporter expanded

flutter analyze --no-pub lib/data/models/shipment_model.dart lib/data/repositories/shipment_repository.dart lib/features/user/shipments lib/core/widgets/tab_page_header.dart test/standalone_shipments_core_test.dart test/standalone_shipments_ui_test.dart
```

Chỉ chạy test feature/caller trực tiếp cần thiết; không tự chạy hoặc sửa toàn bộ suite.
Hai file probe ngoài Git chỉ để tái kiểm tra local; CI cần các regression nằm trong repo.

Bàn giao gồm file đã sửa, thiết kế owner/factory, cách giữ khóa khi retry và đổi khóa
khi tạo đơn mới, kết quả test thực thi cùng giới hạn còn lại. Cập nhật mục mới trong
MOBILE_STANDALONE_SHIPMENTS_UI.md, đánh dấu các kết luận/test cũ là snapshot lịch sử
nếu không còn phản ánh bản hiện tại. Không báo PASS cho live API/device khi chưa chạy.
