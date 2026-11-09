# Mobile — Quên mật khẩu (2026-11-06)

## Phạm vi

Worktree: `vexgo_auth_develop_sync_worktree`, branch `fix/mobile-auth-account-type`.
Đang cùng nhánh với thay đổi tương thích accountType và danh mục địa điểm đã làm trước đó; chưa commit/push thay đổi mới này.
Backend đối chiếu: `vexgo_web` develop `f6ababc8c503b8cff5a5d2bc302dcc6ce6316506`.
Không sửa Backend, migration hoặc cấu trúc DB.

## Luồng người dùng

Đăng nhập → Quên mật khẩu? → nhập số điện thoại → yêu cầu OTP → xác thực OTP → nhập và xác nhận mật khẩu mới → thành công → về đăng nhập với số điện thoại vừa khôi phục.
Không tự đăng nhập, không gửi mật khẩu mới qua SMS/email.
Mật khẩu cũ trong form đăng nhập được xóa khi mở màn khôi phục.

## API

- POST `/auth/forgot-password/request-otp`: phoneNumber chuẩn +84, lấy challengeId/expiresAt/resendAfter.
- POST `/auth/forgot-password/verify-otp`: phoneNumber/challengeId/otp, lấy otpProof/expiresAt.
- POST `/auth/forgot-password/reset`: phoneNumber/otpProof/newPassword; chỉ hoàn tất khi có phản hồi thành công hợp lệ.

Các request public không đính kèm token và không ghi token/session vào storage.
Các proof/OTP/password chỉ giữ trong bộ nhớ của màn; xóa khi rời màn, bắt đầu lại, đổi phiên hoặc hoàn tất.
Chặn gửi liên tiếp; bỏ phản hồi muộn sau dispose/đổi phiên; chặn request nếu phiên đổi trong lúc chuẩn bị header.
Thời gian gửi lại và hết hạn dựa trên deadline trả về, không dùng đếm lùi tích lũy.
Mật khẩu kiểm tra 8–72 byte UTF-8, không trim. Xác nhận phải khớp hoàn toàn.
Không tự gửi lại reset khi kết quả chưa xác định: hướng dẫn thử đăng nhập bằng mật khẩu mới hoặc xin OTP mới. Proof chỉ dùng một lần.
Backend là nguồn xác thực cuối cùng về hạn dùng, cooldown và số lần thử OTP.

## File chính

- `lib/data/repositories/password_recovery_repository.dart`: contract HTTP và validation.
- `lib/features/user/profile/presentation/screens/forgot_password_screen.dart`: các bước, bàn phím, loading, lỗi, session/dispose guards.
- `lib/features/user/profile/presentation/widgets/auth_modal_sheet.dart`: điểm vào và quay lại đăng nhập.
- `lib/core/network/api_config.dart`: ba endpoint.
- `test/password_recovery_test.dart`: repository/widget regression.

## Kiểm thử và giới hạn

Kết quả cuối được ghi trong phần xác minh bên dưới sau khi chạy xong.
Các test MockClient/widget không phải SMS thật hoặc E2E trên Android.
Backend hiện chỉ có ConsoleSmsSender: OTP ghi trong terminal local; chưa có nhà cung cấp SMS production.
Không đưa mã OTP mẫu hoặc tính năng demo vào giao diện khôi phục.
ADB chưa nhận thiết bị tại thời điểm triển khai. Cần cập nhật APK thủ công trên máy thật rồi kiểm tra bằng tài khoản thuộc quyền sử dụng của người kiểm thử.
Không reset mật khẩu tài khoản thật trong quá trình test tự động lần này.

## Xác minh đã thực thi

- Suite Mobile toàn bộ: 815/815 qua trước điều chỉnh nhỏ trả số điện thoại về route đăng nhập.
- Sau điều chỉnh cuối: 46/46 test trong password_recovery_test, auth_lifecycle_regression_test, auth_and_profile_flow_test qua; riêng quên mật khẩu có 14 test.
- flutter analyze --no-pub: No issues found.
- flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:4002/api/v1: thành công.
- APK: mobile-qa-evidence/locations-sync-20261106/app-debug-forgot-password.apk
- SHA-256: ac025363bb3f585afa73580ef3f751ca3573bb39c62d936725637a9a08842285
- Log kiểm thử/build ở cùng thư mục evidence, ngoài Git.
- Chưa chạy luồng OTP/reset thật qua HTTP hoặc trên Android. Không gọi đây là E2E/SMS PASS.
