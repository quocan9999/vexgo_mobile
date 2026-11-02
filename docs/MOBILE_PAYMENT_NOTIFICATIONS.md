# Mobile: thông báo và Android push

Base Mobile develop `1c5fdfc`; phối hợp Backend `feature/payment-confirmation-notifications` (nền `66a2ce8`). Không có SMTP password hoặc Firebase service-account trong Flutter.

## Hành vi

- Inbox đọc category/bookingId/ticketId; recipient id dùng để đánh dấu đã đọc.
- Mở thông báo vé tải chi tiết authoritative, kiểm tra phiên; chặn bấm trùng và bỏ kết quả sau logout/đổi tài khoản. Legacy thiếu ticketId mở Vé của tôi.
- Refresh khi vào màn, chọn lại tab, quay lại foreground; pull-to-refresh giữ nguyên.
- Push foreground làm mới inbox và hiện lời nhắc chung. Chạm push mở inbox; từ inbox mới tải vé theo quyền hiện tại. Không dựng vé từ payload push.
- Đăng ký thiết bị theo account/session, đăng ký lại khi refresh token/resume; hủy đăng ký khi logout/tắt tùy chọn. Preference lưu theo từng account. Kết quả async sau đổi phiên bị bỏ qua.
- Giữ ID điểm đón/trả theo chuyến trong quote/create-booking; đổi điểm làm quote hết hiệu lực. Tổng tiền theo Backend.

## Cấu hình Android

Firebase package phải khớp `com.example.vexgo_app`; cần API notification-device và hai migration Backend. Bật Android POST_NOTIFICATIONS khi được hỏi. Bản build mặc định chưa bật push.

Build bằng file public defines ngoài Git:

```text
flutter build apk --debug --dart-define-from-file=<public-defines.json>
```

Các key: API_BASE_URL, PUSH_NOTIFICATIONS_ENABLED=true, FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_SENDER_ID, FIREBASE_PROJECT_ID. Đây là cấu hình app công khai; private key của server không được đặt vào file này. Thiết lập demo/SePay theo hướng dẫn chung của dự án khi dùng sandbox.

Hiện dùng firebase_core 4.0.0 / firebase_messaging 16.0.0 qua getToken; trên thiết bị nâng cấp, SDK vẫn trả ID 22 ký tự, Backend hỗ trợ cả FID lẫn token. Không bật FID migration trong Android manifest. Firebase auto-init tắt; chỉ đăng ký khi có phiên khách hàng và quyền thông báo. Chưa cấu hình APNs/iOS hoặc kiểm thử push desktop.

## Kiểm thử

Bản cuối: 734/734 Flutter tests qua; analyze sạch và debug APK build thành công. Các ca kiểm tra parse ID, ownership/session, single-flight, stale result, refresh inbox, đăng ký/logout race và khôi phục phiên sau process death. Test gateway giả lập không thay thế FCM/device.

Gmail QA thật được người dùng xác nhận nhận Inbox. Android realme 11 / Android 15 đã kiểm tra: foreground tự tải lại inbox; background hiện push và chạm mở inbox; tiến trình đã tắt bằng kill, chạm push khởi động app và tải thông báo mới. Ba probe là thông báo QA SYSTEM, không tạo booking/thanh toán thật. FCM SENT chỉ chứng minh provider chấp nhận, không chứng minh thiết bị hiển thị.

Để kiểm thử máy thật: API hoạt động, adb reverse đúng API port (nếu dùng localhost), đăng nhập, cấp quyền; kiểm tra lần lượt app foreground, Home/background, process bị OS kết thúc rồi chạm push. Android Force stop có thể chặn push cho tới khi người dùng mở lại app; không dùng Force stop để đại diện cho đóng app thông thường.

Backup, APK, log và credential ở workspace ngoài Git; không chia sẻ cả thư mục bằng chứng.
