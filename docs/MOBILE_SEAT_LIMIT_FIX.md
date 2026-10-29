# Mobile giới hạn tối đa 5 ghế — 26/10/2026

Người dùng đã chốt giữ tối đa 5 ghế theo Backend/Web, sửa logic Mobile. Không thay đổi contract hoặc code Backend.

Trên APK cũ, Mobile cho chọn 6 ghế và bấm Tiếp tục; API từ chối, app hiện “Dữ liệu không hợp lệ.” rồi mất toàn bộ lựa chọn. Lỗi đã được tái hiện trên realme 11, chuyến 769. Evidence gốc: `mobile-qa-evidence/seat-coordinate-device-20261026/DEVICE_REVIEW.md` trong workspace.

## Sửa lỗi

- `BookingFlowState.maxSeatsPerTrip = 5` dùng chung cho kiểm tra state, BLoC và nhãn màn chọn ghế.
- Chặn ghế thứ 6 ngay trong `_onToggleSeat`, trước khi thay đổi lựa chọn, quote, hold hoặc countdown. Giữ 5 ghế cũ, tổng tiền, hold và deadline; chỉ thông báo tối đa 5.
- State có hơn 5 ghế không thể bật nút tiếp tục ở bước chọn ghế, kể cả khi state bị dựng sai từ nơi khác.
- Nhãn hiển thị lấy từ constant, không còn ghi tối đa 6. Chưa sửa bố cục UI; phần đó giao Agent khác qua `MOBILE_SEAT_MAP_FIXED_LAYOUT_AGENT_HANDOFF.md` tại workspace.

## Kiểm thử thực thi

- 3 regression đã fail trên code cũ (2 ca không chặn ghế thứ 6, 1 ca state 6 ghế vẫn canProceed).
- Sau sửa, focused suite booking integrity + seat/pickup: 36/36 qua.
- Full Flutter suite: 395/395 qua.
- Analyzer lượt cuối: không có issue; build APK exit 0.
- Regression giữ 5 ghế và hold/deadline khi chọn ghế thứ 6, không phát sinh thêm hold POST/release; 5 ghế vẫn tiến hành giữ chỗ được. Test UI xác minh nhãn tối đa 5.
- Format lib/test: 167 file, 0 thay đổi. Lint dấu ngoặc trong test chụp ảnh cũ được sửa riêng, không đổi logic test hoặc assertion. Log analyzer cũ và lượt chạy lại được giữ riêng.

Evidence tại `mobile-qa-evidence/seat-limit-fix-20261026/`: `regression-before.log`, `regression-after.log`, `full-tests.log`, `analyze.log`, `analyze-final.log`, `apk-build.log`, `build-manifest.json`.

## Artifact và trạng thái bàn giao

APK `mobile-qa-evidence/ci-followup/app-debug-seat-limit-5.apk`, debug Real Mode, API `http://127.0.0.1:4000/api/v1`. SHA-256 `308bafde32681a7670bca4ff8735b2e158bd7c1bf050addb6b9a87198b4a3cfd`.

Đã chép vào `/sdcard/Download/Vexgo/app-debug-seat-limit-5.apk`, đối chiếu hash và người dùng đã cập nhật thủ công, không gỡ app. Thao tác cài APK qua ADB trước đây bị kiểm duyệt tự động chặn. Đã xác minh bản mới trên máy thật như mục bên dưới.

### Cập nhật: đã xác minh bản sửa trên realme 11

Người dùng đã cập nhật thủ công; SHA-256 APK cài trên máy khớp chính xác artifact nêu trên. Đã thử trực tiếp chuyến 769 ngày 27/10/2026:

- Nhãn hiển thị tối đa 5. Chọn A01–A05 rồi chạm A06: A06 vẫn trống, hiện thông báo giới hạn 5, giữ nguyên A01–A05 và tổng tiền 950.000đ.
- Bấm Tiếp tục vẫn giữ chỗ thành công, sang điểm đón; DB xác nhận đúng 5 tripSeatId của A01–A05 và hold 361 có chủ sở hữu đăng nhập.
- Quay lại chọn ghế, thử A06 khi hold đang có: vẫn giữ 5 lựa chọn. Readback DB trước/sau xác nhận hold 361 vẫn DANG_GIU, expiresAt khớp chính xác, không tạo hold mới. Tiếp tục lại vẫn sang điểm đón, countdown tiếp diễn 09:07 thay vì reset về 10:00.
- Thoát qua hộp xác nhận Rời khỏi: DB xác nhận hold 361 DA_GIAI_PHONG và cả 59 ghế của 3 chuyến kiểm thử đều TRONG, holdId null. Không tạo booking/payment/ticket.

Evidence XML `limit5-*.xml` và readback `limit5-*.json` trong `mobile-qa-evidence/seat-coordinate-device-20261026/`; screenshot `device-sixth-rejected.png`, log held/released trong `mobile-qa-evidence/seat-limit-fix-20261026/`. Đây là xác minh thiết bị thật cho lỗi giới hạn, không phải full E2E thanh toán.

Không commit/push/merge; giữ nguyên các thay đổi chưa commit từ những đợt trước. Agent UI phải giữ fix giới hạn này khi sửa sơ đồ, icon và legend.
