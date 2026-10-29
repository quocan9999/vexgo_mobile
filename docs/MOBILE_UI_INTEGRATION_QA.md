# Tích hợp UI Mobile và kiểm thử trên điện thoại

Chốt ngày 28/10/2026. Nhánh cục bộ **integration/mobile-complete-ui**, checkout **vexgo_mobile_integration_worktree**. Code của APK v2 tại `d6de297d0d972a5055a2538faa2b1c128d696026`; các commit tài liệu sau đó không đổi code APK.

## Phạm vi tích hợp

| Nhóm | Nguồn / cách tích hợp |
|---|---|
| Trang chủ, tìm/lọc chuyến, chi tiết xe | Kế thừa chuỗi Discovery trong nền774450a |
| Ghế theo từng xe/tầng, giới hạn5ghế, đón/trả | Kế thừa Seat/Pickup; giữ resolver inventory và F02 bốn cột fd793ba |
| Hành khách, booking header/stepper | Kế thừa Passenger trong cùng nền |
| Bước5 xác nhận, mã ưu đãi, căn thông tin hành khách | Nền410ba93 + patch đã review của worktree Trip Summary |
| Bước6 thanh toán | Nềnf9dacb3 trong chuỗi Ticket Detail |
| Đặt vé thành công | Patch Success đã review, copy từng vé và token/session guard |
| Vé của tôi, chi tiết vé/QR | Nềnb85ff1d/774450a |
| Hủy vé | Patch Cancellation đã sửa quote/consent/single-flight/uncertain/session/read lifecycle |
| Hồ sơ, chỉnh thông tin, đổi mật khẩu | Patch Profile sau review, gồm thu hồi đúng route dialog |
| Chat | Merge nghiệp vụ7a726fa, áp patch UI sau hai lần review |
| Chứng từ | Merge6d1ad34, bổ sung commitd321178 sửa nhãn vé đã thanh toán |

Notification và các màn chưa redesign giữ chức năng/UI hiện có. **Khứ hồi chưa được triển khai đầy đủ trong đợt này.** Không đổi Backend/schema/migration/.env hay tạo DB riêng. Dùng Backend shared đang chạy từ vexgo_chat_worktree tạice84991, DB local chính127.0.0.1:3306/vexgo.

## Xung đột và sửa tại điểm tích hợp

- Routes: giữ cả `/support-chat` và `/booking-receipt`, cùng model/request đúng kiểu; không bỏ route khi giải quyết conflict.
- Vé của tôi: giữ UI mới/NestedScrollView/tab cố định, thêm lại action tra cứu chứng từ.
- Success: giữ UI mới/session fence/copy từng vé và entry chứng từ. Giữ AddNewTicketEvent có generation/token version để event cũ không thêm vé sang phiên khác.
- MyTicketsBloc và events: ghép guard Success với cancellation lifecycle; không ghi đè một nhánh lên nhánh kia. Dọn một import TokenStorage lặp sau merge.
- TokenStorage dùng sessionChanges của nhánh Chứng từ cho login/logout; semantics tương đương các patch Success/Cancellation, refresh rotation không phát event này. Không xóa sessionInvalidations.
- Profile mới được thêm entry **Chat với nhà xe** theo design token mới, giữ guest/login gate của chat.
- Token/font/OFL dùng chung đúng snapshot774450a; không copy pubspec từ nhánh chat cũ để mất font hoặc dependency khác.
- Không đưa7file generated plugin registrants vào commit. Chỉ khôi phục noise do pub get tạo trong checkout tích hợp; không thay bất kỳ worktree nguồn nào.
- Tất cả patch/untracked file được snapshot theo whitelist trước khi ghép. Manifest+SHA256 ở `mobile-qa-evidence/ui-integration-20261028/sources.json` ngoài Git. Đối chiếu sau ghép: **tất cả source snapshot vẫn khớp**, nguồn không bị sửa.

## Kiểm tra tự động / build

| Gate thực chạy | Kết quả |
|---|---|
| Full suite lần đầu sau ghép |633/633PASS,71giây |
| Full suite cuối sau device follow-up |**636/636PASS**,45giây |
| Analyzer cuối |**No issues found**,21.4giây |
| Format toàn lib/test |205files/0changed |
| Git diff check | Không lỗi whitespace; có cảnh báoLF→CRLF |
| Debug APK v1 | Build thành công,279.3giây |
| Debug APK v2 | Build thành công,52.1giây |

Build v1 có cảnh báo Kotlin incremental cache do plugin/cache ở ổC và checkout ổD; Gradle vẫn hoàn tất và trả exit0. Không xóa cache chung hoặc đổi toolchain để giấu cảnh báo. Analyzer lần đầu có import trùng và format routes; đã sửa rồi chạy lại các gate cuối.

APK cuối: **app-debug-mobile-integrated-ui-v2.apk**,159596369bytes.

SHA256: `692b22f6fceaee2597bebc96e63f565ccdbd28a247889129b440ef28c1ab6442`.

Build với DEMO_MODE=false, API_BASE_URL=http://127.0.0.1:4002/api/v1, SEPAY_BANK_ID=MB, SEPAY_ACCOUNT_NUMBER=0000000001, SEPAY_ACCOUNT_NAME=PHAM MINH TAI. Chỉ public receiving settings của **SePay Test Mode**; không nhúng secret vào APK. Manifest APK ở `mobile-qa-evidence/ui-integration-20261028/build-manifest.json`.

## Máy thật và môi trường

- Realme RMX3636 (realme11), ADB serialLFZHQWE65LV8XGZH. Packagecom.example.vexgo_app.
- ADB reverse: tcp4002→tcp4002. API health4002 trảok. MySQL Docker healthy, không thiếu/unfinished migration; không reset/seed/migrate trong lượt này.
- Người dùng cài thủ công v1 và v2, không gỡ app. SHA256 của **base.apk đang cài** đã đối chiếu lần lượt khớp APK v1/v2, không chỉ hash file Download.
- Tài khoản người dùng đang đăng nhập được giữ khi update/restart. Không lấy mật khẩu/OTP, không đổi mật khẩu hay tạo tài khoản trong lượt này.
- Admin local3005 dùng phiên tenant Hoa Mai đang có. Bổ sung dependency sonner2.0.8 còn thiếu để Admin render; manifests/lockfile và source Backend/Web không thay đổi. Không chạy audit fix hoặc nâng API/schema.
- Khôi phục forwarder chỉ nhận POST webhook SePay ở4402→4002 và ngrok đã cấu hình. Kiểm tra HMAC/account bằng payload thiếu transaction:400SEPAY_TRANSACTION_INVALID đúng dự kiến; đây là preflight, không tính là thanh toán thành công.

## Kịch bản đã thực thi trên máy

| Bước | Bằng chứng / kết quả |
|---|---|
| Trang chủ→tìm chuyến ngày29/10 TP.HCM→Đà Lạt |API trả3chuyến; chọn chuyến775,lúc08:00,190.000đ |
| Ghế |Sơ đồ4cột16ghế; chọn5rồi ghế6 bị chặn đúng thông báo; bỏ4ghế để cònA01 |
| Giữ chỗ |Đã đăng nhập giữA01 thành công; countdown10phút hiện ở bước đón/trả/hành khách |
| Đón/trả |Chọn Bến xe Miền Đông mới / Bến xe Liên tỉnh Đà Lạt bằng danh sách API |
| Hành khách |Thông tin tài khoản đang dùng tự điền; bước5 hiển thị nhãn2cột gọn và email không rớt đuôi |
| Mã ưu đãi không hợp lệ |Hiện “Mã chưa được xác nhận”, chặn tiếp tục khi chưa có quote hợp lệ; bỏ mã tải lại giá190.000đ. Chưa thử mã giảm giá hợp lệ trong lượt này |
| Tạo booking/payment |Đơn#841,một véA01,giá190.000đ,ordercodeHMGD983A3A3BA7814CA1A369E70E2F6C76 |
| SePay sandbox |Gửi đúng1giao dịch mô phỏng190.000đ vào tài khoảnTEST0000000001; SePay báo webhook thành công và hệ thống xác nhận; forwarder ghiHTTP200 |
| Success |Bấm kiểm tra thanh toán trên Mobile→Đặt vé thành công, mã vé riêng, QR và entry chứng từ |
| Vé của tôi/Chi tiết/QR |Vé vừa tạo xuất hiện, mở chi tiết và phóng toQR được |
| Chứng từ |Tra cứu từ Success và Detail, tải nội dung từAPI. Sau cập nhậtv2, vé đang trảDA_THANH_TOAN hiển thị đúng “GhếA15 • Đã thanh toán” trên chứng từ của vé sẵn có |
| Hủy vé mới tạo |Quote20%/38.000đ, dự kiến hoàn152.000đ; chọn lý do/consent→server xác nhận hủy, tab Đã hủy cập nhật, chi tiết khóaQR |
| Profile |Hiện hồ sơ từAPI; mở sheet edit với phone read-only rồi đóng; entry chat vẫn dùng được |
| Chat Mobile→Admin |TinQA-20261028-841-mobile-admin tự xuất hiện trong inbox Admin, không F5 |
| Chat Admin→Mobile |Tin trả lờiQA-20261028-841-admin-mobile xuất hiện trên điện thoại; Admin chuyển “Đã gửi”→“Đã đọc” khi tin hiện trên máy |
| Background/resume |Đưa app về Home hệ thống, gửi tinQA-20261028-841-background-resume từAdmin; mở lại app nhận tin, không tải lại thủ công |
| Update/restartv2 |Phiên đăng nhập còn, mở lại chat đọc đủ3tinQA từ persisted history |
| Notifications |Mở màn sau restart: tải được trạng thái rỗng. Không coi đây là bằng chứng push hoặc sinh thông báo mới |

Luồng tạo/thanhtoán/thànhcông/hủy chạy trên APKv1 tích hợp. V2 chỉ thêm nhãn paid chứng từ và format địa chỉ thiếu, không sửa booking/payment/chat lifecycle. Đã kiểm tra lại chứng từ và lịch sửchat/sessionrestart trên **đúng APKv2**. Không tuyên bố đã tạo/thanh toán lại một đơn thứ hai trênv2; fallback địa chỉ có regression test riêng trong636test.

## Đối chiếu DB chỉ đọc sau QA

`live-db-verification.json` xác nhận:

- Booking841:DA_HUY; ticket354:HUY; inventoryA01:TRONG.
- ThanhToan753:THANH_TOAN,THANH_CONG,190000; đây là thanh toán mô phỏng provider, không có chuyển tiền thật.
- ThanhToan754:HOAN_TIEN,DANG_XU_LY,152000,laQuyetToanHopLe=0. **Chưa hoàn tiền ngân hàng**, không báo đã settlement.
- Hội thoại97: tin320/321/322, mỗi nội dungQA chỉ1bản ghi, đềuDA_DOC.

Không xóa dấu vếtQA hoặc sửa ticket/order trực tiếp bằngSQL. Những mutation chỉ qua app/API/Webhook đúng luồng. Query kiểm chứng làSELECT có targetbooking/message cụ thể.

## Device follow-up và giới hạn

1. Bổ sung commitd321178 từ nhánh demo để xử lý nhãnDA_THANH_TOAN trong chứng từ; không kéo cả nhánh demo.
2. Bỏ dấu ngoặc rỗng ở Success khi server không trả địa chỉ; giữ nguyên dữ liệu đã xác minh, không tự bịa địa điểm. Backend hiện chỉ lưu diemDon trênVe và trả dropoff theo thành phố tuyến; điểm trả chi tiết/địa chỉ không được đảm bảo sau fresh-read. Đợt này không sửaBE/schema để lưu điểm trả.
3. Chưa test login/registerOTP/đổi mật khẩu bằng credential thật, review chuyến hoàn tất, guest lookup mới, discount hợp lệ, hai tầng hoặc mọi lỗi mạng trên đúng APK cuối. Những phần này có fixture/regression riêng nhưng không gọi là đã chạy hết trên thiết bị trong lượt này.
4. Chưa kiểm thử push, attachment, VATinvoice, roundtrip; chúng không thuộc scope đã hoàn thiện. Không coi bộ test xanh là xác nhận mọi luồng hệ thống.

## Trạng thái bàn giao

- Nhánh tích hợp đã có commit cục bộ, nguồn giữ nguyên, sẵn sàng chuẩn bị PR tổng hợp vào team/develop sau khi người dùng yêu cầu publish.
- **Chưa push/tạo PR tổng hợp, chưa merge/approve/resolve bất kỳ PR GitHub nào.** Không đóng PR cũ trong lượt này. Cần nêu danh sách PR thay thế trong PR tổng hợp để lead tránh merge trùng.
- Docker/API/ADB/Admin và tunnel sandbox đang dùng cho QA; API vẫn ở terminal do người dùng mở. Không có automation/monitor nền định kỳ được tạo.
- Toàn bộ log/ảnh/XML/private runtime evidence nằm ngoàiMobileGit tại `mobile-qa-evidence/ui-integration-20261028/`. Không đưa APK,token,.env hoặc contact riêng vào PR. Tài liệu này chỉ ghi mãQA và kết quả cần review.
