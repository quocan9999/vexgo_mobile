# Kiểm thử gửi hàng trên Android thật — 05/11/2026

## Môi trường và giới hạn

- Thiết bị realme 11 / RMX3636, ADB; APK debug từ worktree standalone shipments.
- APK đã cài khớp SHA-256:
  `220b89b46467a8d5111c5223f35ca28ea99e37dece60241641a0d168a856b116`.
- Real Mode, API_BASE_URL `http://127.0.0.1:4002/api/v1`, adb reverse 4002 → 4002.
- Backend source develop `e50a928412289a2ea77e392780a8c518ddae40e6`, build thực tế qua
  sau khi đồng bộ dependency từ lockfile tại repo root.
- API nối MySQL cách ly `vexgo-shipments-device-20261105`, localhost:3312,
  phục hồi từ backup DB chính 95 bảng. Không reset/seed/áp migration trên DB chính.
- SMTP, FCM, reminder, Cloudinary và provider hoàn tiền đều tắt trong launcher QA.
  Không chuyển tiền, không giả lập đã thu tiền. Hai đơn QA đều chờ thanh toán tại bến.
- Các thao tác tạo đơn được thực hiện qua giao diện điện thoại → API thật → MySQL.
  Kiểm tra DB chỉ để đối chiếu. Các đơn này không được chèn trực tiếp bằng SQL.

## Điều kiện nâng DB phát hiện trước khi test

Migration route_based_cargo_pricing của develop thất bại P3018/MySQL1452 khi có
127 bảng cước cũ: thêm tuyenXeId NOT NULL nhưng không backfill trước FK.
Để tiếp tục QA, chỉ trên clone: xác minh mỗi mức cước ánh xạ được đúng một tuyến
qua hai điểm và DiemGiaoNhanTuyenXe, backfill 127 row rồi hoàn tất FK/migration.
Hai migration notification đổi tên được đối chiếu SQL checksum sau chuẩn hóa CRLF/LF.

**Lượt test này không chứng minh migration gốc nâng được DB có dữ liệu.** Lead cần
xử lý riêng trước rollout; xem workspace/lead-handoff/SHIPMENTS_DB_UPGRADE_FINDING_20261105.md.

## Kết quả đã thực thi

| Ca | Kết quả và bằng chứng |
| --- | --- |
| Mở feature từ tài khoản | Màn Gửi hàng hiển thị Tạo đơn/Tra cứu/Đơn của tôi; phiên tài khoản thật tải lại được. |
| Discovery | HCM → DL, ngày 06-11-2026 trả 3 nhà xe; Phương Trang cước từ 30.000đ. |
| Điểm gửi/nhận | Chọn Phương Trang: hai dropdown lấy đúng Phương Trang 1 tại TP.HCM và Phương Trang 2 tại Đà Lạt từ API. |
| Báo cước | 1 kiện BƯU PHẨM, 2kg, tiêu chuẩn → 50.000đ. DB chưa có kiện QA này khi chỉ báo cước. |
| Sửa sau báo cước | Sửa ghi chú chung: thẻ báo giá và CTA tạo đơn cũ mất hiệu lực, trở lại Báo cước. |
| Tạo đơn đầu | Tạo qua CTA sau khi xem báo giá; shipment #27/order #862, TAI_BEN, total 50.000đ, trip NULL, route 1. |
| Chi tiết chưa phân chuyến | Hiển thị mã UUID đầy đủ, Chưa phân chuyến, điểm gửi/nhận, ngày tạo/ngày dự kiến gửi; không crash vì null trip. |
| Tiền | Mở lại chi tiết có auth: Cước dự tính, tổng 50.000đ, Đã thanh toán 0đ, Còn phải thanh toán 50.000đ. |
| QR | Chỉ QR nhận diện vận đơn, caption phân biệt với chuyển khoản. Không có VietQR thanh toán. |
| Danh sách | Đơn #27 và #28 xuất hiện đúng tài khoản. Mở chi tiết từ danh sách rồi Back quay lại danh sách hoạt động. |
| Đơn khác cùng nội dung | Từ chi tiết chọn Tạo đơn gửi hàng khác, nhập lại cùng toàn bộ payload, tạo shipment #28/order #863. DB xác minh payloadHash bằng nhau, hash khóa idempotency khác nhau và mã/ID vận đơn khác nhau. |
| Tra cứu đúng | Mã #28 + số điện thoại người gửi qua form trả đúng đơn, cước 50.000đ và thanh toán tại bến. |
| Tra cứu sai | UUID không tồn tại + cùng phone: báo không tìm thấy và bỏ kết quả cũ. Không hiển thị lại dữ liệu đơn trước. |

Hai bản ghi đối chiếu:

- #27: `a293319e942c48be8e2e91df20ea4448`, order #862.
- #28: `2895ed08a1a440979640eaaa06c8c651`, order #863.
- Cùng payload hash: `bd844b494d986c3bfdbcb60933585fcf71b0bcc5ccfe00abe36acc0c9259d237`.
- DB chính: 0 kiện tên QA Parcel Device 20261105 tại thời điểm đối chiếu.

## Hai điểm còn cần sửa

### D01 — P2: Back từ đơn vừa tạo mở form không hoạt động

Sau tạo đơn ở tab Tạo đơn → Back: host chỉ bỏ _viewingDetail, vẫn giữ Cubit phase
created. Form mới mount có controller trống nhưng state còn route/options/quote
cũ. searchRoutes/selectRoute/updateDraft/create đều đòi editing nên không thao tác
tạo tiếp được. Nhánh Tạo đơn khác ở cuối chi tiết đã hoạt động và là đường khác.

Đã quan sát form trống nhưng danh sách nhà xe cũ còn hiển thị trên thiết bị.
Widget probe độc lập tái hiện: kỳ vọng editing khi trả về ShipmentCreateView,
thực tế created; **1/1 probe thất bại**.

Vị trí: shipments_host_screen.dart/_handlePopConfirmation; tạo view sau khi
_viewingDetail=false. Chọn hành vi điều hướng rõ ràng: quay về nguồn thích hợp hoặc
bắt đầu owner mới có guard sau đơn đã xác minh. Không tự reset submitting/uncertain.
Test cả nguồn tạo đơn và nguồn danh sách; không chỉ test nút Tạo đơn khác.

### D02 — P2: Hạn mang hàng thiếu giờ địa phương

DB có deadline chính xác nhưng detail và lookup chỉ hiện Chủ nhật, 08/11/2026.
DateFormatter.formatFullDate không chứa giờ. Hai đơn #27/#28 có giờ hết hạn khác
nhau nhưng cùng nhãn ngày, khiến khách không biết thời điểm hết hạn trong ngày.

Hiển thị ngày **và HH:mm** từ dropoffDeadline.toLocal(), không tự dựng giờ/hạn mới.
Đối chiếu UTC DB và giờ local ở cả detail/lookup. confirmedAt cũng nên có giờ khi
được dùng để trình bày thời điểm chốt cước.

## Quan sát ngoài phạm vi gửi hàng

Trước khi vào flow đã có một lần màn hình đen; log công cụ quan sát báo
AuthModalSheet gọi Navigator.pop làm mất trang cuối của GoRouter. Người dùng mở
lại app, tải phiên xong thì flow gửi hàng chạy được. Chưa tái hiện ổn định/nghiên
cứu đủ nguyên nhân nên không coi đây là finding mới đã chốt của module gửi hàng.
Ảnh màn hình đen được giữ ngoài Git, không sửa auth trong lượt test này.

## Bằng chứng và phần chưa test

Evidence ngoài repo tại workspace/mobile-qa-evidence/shipments-device-20261105/:

- orders-live-evidence.json: ID, tiền, route/trip, payload/key hash, đối chiếu DB chính.
- quote-before-create.png; first-order-top.png; second-order-top.png.
- owned-detail-fees.png; lookup-second-order.png; current-screen.png (màn đen trước flow).
- back-after-success_probe_test.dart; back-after-success-probe.log.
- migration.log; qa-pricing-workaround.json; migration-after-qa-backfill.log.

Ảnh/XML có dữ liệu cá nhân dùng test: giữ ngoài Git, không đưa nguyên bộ vào PR.
Không commit key, env riêng, archive hoặc thư mục private của môi trường QA.

Chưa live-test đổi giữa hai tài khoản, kill app khi POST đang pending, timeout/retry,
cân đo/thu tiền/phân chuyến từ Admin, hoặc cước đã chốt/đã thu một phần trên device.
Các ca tương ứng ở fixture/widget trước đó không được gọi là device E2E.
Chưa chạy test bằng DB chính sau nâng; chưa sửa code chức năng, commit/push/merge.

## Kiểm thử bổ sung bản Navigation/Form đã sửa — 05/11/2026

### Bản cài và môi trường

- APK `app-debug-shipments-nav-fixed.apk`, SHA-256 `90e594280447e9df51c4485df791f47b67f02b8f1b4dc8aff52f2b1254f03d91`.
- Đối chiếu hash APK đã cài trên realme 11 khớp file build, không chỉ đối chiếu file trong Download.
- ADB reverse `tcp:4002 -> tcp:4002`; API QA dùng DB cách ly `vexgo-shipments-device-20261105`, cổng 3312. Dùng lại môi trường clone có workaround migration đã mô tả ở trên; không chứng minh migration gốc chạy được trên DB chính.

### Các thao tác thực chạy trên điện thoại

| Ca | Kết quả quan sát |
| --- | --- |
| Navigation | Đủ 5 tab đúng thứ tự, Gửi hàng là tab thứ 3; root không có nút Back vô nghĩa. |
| Chọn tuyến | Sheet chọn tỉnh/thành mở được; chọn TP.HCM/Đà Lạt, đảo chiều đổi đúng hai giá trị. Trang chủ vẫn giữ cặp tìm vé ban đầu; quay lại Gửi hàng giữ lựa chọn đã đảo. |
| Ngày gửi | Chọn 07/11/2026, xác nhận trở về form, tìm tuyến được 3 nhà xe; chọn Phương Trang tải đúng hai điểm giao nhận. |
| Giữ form | Điền thông tin liên hệ đã dùng ở đợt QA trước, 1 kiện BƯU PHẨM 2kg, tên QA Nav Parcel 20261105. Báo cước 50.000đ; chuyển sang tab Thông báo rồi quay lại vẫn giữ form/quote. |
| Tạo đơn | Tạo qua UI/API: shipment #29, order #864, route #1, chưa phân chuyến, CHO_THANH_TOAN, 50.000đ; không chuyển tiền, không xác nhận thu tại quầy. |
| D01 sau tạo | Bấm Back từ đơn vừa tạo mở form sạch; chọn lại hai thành phố và tìm tuyến thành công. Form không còn bị kẹt phase created. |
| Danh sách | Đơn #29 xuất hiện đúng tài khoản; mở chi tiết rồi bấm Back hệ thống Android quay lại Đơn của tôi. |
| Tra cứu và D02 | Mã vận đơn + phone chủ sở hữu trả đúng #29, thanh toán tại bến; detail và lookup đều hiện 23:22 - Chủ nhật, 08/11/2026. DB UTC deadline 2026-11-08 16:22:31 khớp local UTC+7. |

Mã vận đơn: `8e833143bb4140098af7c10f98033a79`; mã đơn `e4d6cbdb47c04dc183d638cef304db79`.
DB chính kiểm tra có **0** bản ghi theo mã vận đơn mới; đơn QA chỉ nằm trong clone.
Log Flutter của PID app đang chạy không có dòng khớp Unhandled Exception, setState after dispose, RenderFlex overflow hoặc EXCEPTION CAUGHT trong buffer đã đọc. Đây là quan sát log, không chứng minh mọi nhánh không có lỗi.

### Điểm UI còn lại và giới hạn

- Timeline tra cứu vẫn hiện mã `MOI_TAO` thay vì nhãn tiếng Việt (`shipment_lookup_view.dart` phần timeline).
- Form loại dịch vụ còn nhãn `Tiêu chuẩn (NORMAL)`; nên bỏ mã enum khỏi nội dung cho khách.
- Hai điểm trên là nhãn UI, chưa sửa trong lượt kiểm thử này.
- Chưa tái hiện đổi phiên/account trong lúc date picker đang mở trên máy thật; regression này đã được kiểm tra bằng widget/probe ở lượt sửa code (51 test chính + 8 probe qua), không gọi là device E2E.
- Chưa test mạng gián đoạn/uncertain, kill app khi POST đang pending, cân đo/chốt cước/thu tiền/phân chuyến, hoặc landscape/text scale 2x trên thiết bị ở đợt bổ sung này.
- Điện thoại để tại Gửi hàng → Đơn của tôi; API QA và ADB reverse giữ nguyên. Chưa commit/push.

Evidence ngoài Git ở `mobile-qa-evidence/shipments-device-20261105/`:
`nav-device-evidence.json`, `nav-create-device.png`, `nav-created-detail-device.png`, `nav-lookup-device.png`.
Ảnh/XML có thể chứa dữ liệu cá nhân; không đưa nguyên thư mục QA, env/secret hoặc ảnh này vào PR.
