# Mobile — một QR cho vé khứ hồi

Ngày: 06/11/2026. Worktree hiện tại: `vexgo_accompanied_luggage_worktree`, branch `feature/mobile-accompanied-luggage` (có các thay đổi local/UI hành lý trước đó; chưa commit/push).
Backend đối chiếu: `0159558`, API QA4012 / DB3313. Không sửa Backend hoặc DB schema.

## Hành vi mới

- Hai booking vẫn được tạo/tra cứu riêng, gửi chung một `comboCode` cho cả hai POST. Mã mặc định có tiền tố RT và 128-bit ngẫu nhiên, chỉ gồm ký tự chữ-số để phù hợp cách tách mã chuyển khoản hiện tại. Mã giữ nguyên suốt checkout/retry, không sinh lại khi chỉ thiếu một chặng.
- BookingModel parse/lưu comboCode do API trả về; coordinator chỉ hiện QR khi đủ hai đơn khác nhau, mã nhóm khớp với mã đã gửi, số tiền đọc lại hợp lệ, cả hai còn đủ điều kiện thanh toán.
- QR lấy tổng số tiền chính thức của hai đơn, không cộng các quote/ước tính phía client. Hạn QR theo đơn hết hạn sớm nhất. Chặn tổng vượt giới hạn số nguyên an toàn.
- Không hiện hai QR riêng cho checkout combo. Khi chỉ tạo được một chặng hoặc phản hồi POST chưa rõ: giữ các recovery ID, khóa QR chung, không tự gửi lại POST không rõ kết quả.
- Nút kiểm tra hai chiều chỉ GET/đối soát các đơn đã biết. Không tạo đơn, không mô phỏng thanh toán. Hoàn tất chỉ sau khi cả hai chặng được xác minh đã trả tiền và tải đủ vé.
- Nếu webhook mới xử lý một chặng: khóa QR và yêu cầu kiểm tra lại/đối soát; không khuyến khích chuyển tiền lần nữa.
- Đổi phiên xóa dữ liệu checkout được render và chặn tác vụ từ phiên cũ.
- Sửa tương thích DTO: bỏ trường email khỏi contact của POST khi người dùng không nhập email, thay vì gửi chuỗi rỗng bị IsEmail từ chối. Không thay đổi dữ liệu tài khoản.
- BookingModel equality bao gồm hạn thanh toán/mã nhóm/mã giao dịch/trạng thái thanh toán để cập nhật mới từ server không bị bỏ qua.

## Code chính

- `lib/data/models/booking_model.dart`
- `lib/data/datasources/remote/booking_remote_data_source.dart`
- `lib/data/repositories/booking_repository.dart`
- `lib/features/user/booking/bloc/booking_flow_bloc.dart`
- `lib/features/user/round_trip/round_trip_checkout_cubit.dart`
- `lib/features/user/round_trip/presentation/widgets/round_trip_payment_view.dart`
- `lib/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart`

Các test double cập nhật tham số optional comboCode. Luồng một chiều không gửi trường comboCode khi không có nhóm.

## Kiểm chứng đã thực hiện

- `flutter analyze --no-pub`: **No issues found**.
- 15 suite đặt vé/thanh toán/khứ hồi/hành lý/network: **219/219 pass**. Trong đó `round_trip_combo_test.dart` có 15 ca (mã chung, retry, unknown outcome, sai mã trả về, thay đổi mã khi đọc lại, hạn sớm nhất, hoàn tất hai vé, single flight, overflow, phiên, email optional, một ảnh QR với đúng amount/memo, responsive 320dp/640dp chữ 2x có bàn phím, và đối soát một chặng không hiện thêm QR).
- Log workspace cha: `mobile-qa-evidence/round-trip-combo-20261106/{regression-tests.log,analyze.log,combo-tests.log}`. Log combo-tests riêng được chạy trước khi thêm ca khóa QR khi đối soát một chặng; bộ regression cuối gồm đủ ca đó.
- Native Flutter repository/coordinator → HTTP/NestJS/MySQL thật: **1/1 pass**, không MockClient, không Android. Dùng tài khoản QA và contact đã có trong DB cách ly; không ghi contact/credential vào báo cáo này.
- Tạo booking QA847 (210.000đ) và QA848 (190.000đ), API xác nhận cùng nhóm, tổng **400.000đ**, đọc lại cả hai đơn khớp và canDisplayCombo=true. Không gọi webhook, không thanh toán, không gửi email/push. Không đổi DB3312/3306. Không tự chạy lại POST: journal native-result.json ngăn replay.
- Lần probe đầu chưa tạo đơn vì contact QA không phù hợp validation của UI; lần sau API từ chối email rỗng trước khi tạo đơn. Giữ bằng chứng rejection tại native-validation-rejected.json; chỉ retry sau khi xác minh không có ID/unknown outcome. Sửa serializer rồi native pass.
- Native probe dùng mã RT-... được DTO chấp nhận; generator mặc định cuối cùng chuyển sang chữ-số RT... để tránh việc Backend tách dấu gạch trong nội dung có thêm tiền tố. Cả hai định dạng đều được test parser/contract; chưa xác minh giao dịch ngân hàng cho định dạng nào.

## Chưa kiểm chứng / công việc tiếp

- Chưa cài/test APK mới trên Android; chưa chạy webhook SePay sandbox cho hai đơn cùng nhóm. Không coi fixture trạng thái paid là E2E ngân hàng.
- Khi test SePay cần callback tới đúng API/DB của đơn. Callback báo cáo cũ tới API4002/DB3312 không xác nhận được đơn của QA4012/3313.
- Phần hành lý chỉ dự tính không thu cùng vé vẫn chờ teammate đổi Backend; tính năng QR này không thay đổi quy tắc tiền hành lý.
- Các mục hủy đơn gửi hàng, đánh giá mở rộng, rà vé điện tử/429 là các phần tiếp theo, không nằm trong thay đổi QR này.


## APK

Đã build debug bằng public-defines của bản thử API4012, chép vào workspace cha `luggage-preview-20261106/app-debug-accompanied-luggage.apk`. File này gồm UI hành lý mới và QR khứ hồi. SHA-256 `e75efe85f8e9724a208d03b9fa33b863327352481a415f8513db3753a9f6161f`; chữ ký hợp lệ. Manifest và shortcut VexGo - Hanh ly moi đã trỏ tới APK mới (CheckOnly qua). Bản báo cáo cũ giữ nguyên hash. ADB không có thiết bị tại thời điểm đóng gói, chưa chép/cài lên Android.
