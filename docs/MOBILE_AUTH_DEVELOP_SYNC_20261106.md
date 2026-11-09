# Đồng bộ Mobile với Backend develop — 06/11/2026

## Phạm vi và nhánh

- Backend local `vexgo_web/develop` đã fast-forward từ e50a928 sang f6ababc8c503b8cff5a5d2bc302dcc6ce6316506. Giữ untracked prisma/seed_future_trips.mjs, không sửa Backend source.
- Mobile worktree `vexgo_auth_develop_sync_worktree`, nhánh `fix/mobile-auth-account-type`, tách từ PR #20 HEAD 8765e1e. PR #20 không bị sửa/push trong lượt đồng bộ này.
- Request POST /auth/login thêm accountType=KHACH_HANG cố định; giữ chuẩn hóa số điện thoại, nguyên password, đọc JWT và hydrate /me, session guard. Không có lựa chọn QUAN_TRI trong app khách hàng.
- Regression HTTP fixture xác minh chính xác payload mới trong test/auth_lifecycle_regression_test.dart.
- Chưa triển khai UI quên mật khẩu; đây là luồng mới riêng, không thuộc bản sửa tương thích đăng nhập.

## Môi trường dữ liệu

- Đã backup mã hóa DB QA3312 trước khi nâng: workspace/mobile-qa-evidence/auth-sync-20261106/backups/. Key ở vị trí riêng ngoài Git, không đưa vào tài liệu/PR.
- Chỉ áp dụng migration 20261105110000_add_loai_tai_khoan_composite_unique lên clone vexgo-shipments-device-20261105 tại 127.0.0.1:3312/vexgo; deploy thành công, không còn migration unfinished.
- Kiểm tra sau migration: 0 tài khoản QUAN_TRI mang role KHACH_HANG; 0 KHACH_HANG có hồ sơ NhanVien.
- DB chính3306 chưa migrate/seed/reset. Không chạy seed-bootstrap hoặc đồng bộ diện rộng ghế/điểm đón trả. Code seed mới chỉ xuất hiện sau lấy Git, không có nghĩa dữ liệu DB đã được cập nhật.
- Có một customer fixture riêng tạo trực tiếp trong clone (accountId1243) để chuẩn bị test login/JWT, không phải tài khoản đăng ký bằng SMS thật, không cấp quyền quản trị. Password ngẫu nhiên chỉ ở file private ngoài Git; không gửi email/push/SMS.

## Bằng chứng đã chạy

- Backend npm run build --workspace=@vexgo/api: thành công, generate Prisma Client theo schema mới.
- Backend unit auth/admin-accounts/support-chat: 22 file, **262/262 test qua**. Đây là unit, không phải MySQL HTTP E2E.
- Mobile auth/profile/session/real-mode: **52/52 test qua**.
- Mobile support-chat, seat resolver/four-column, timed pickup/dropoff contract: **51/51 test qua**.
- Export trực tiếp 7 hàm layout từ Backend prisma/lib/seat-layouts.mjs; render từng tầng trong SpatialSeatMap tại 264dp/chữ2x và 380dp/chữ1x: **20/20 probe qua**, vùng chạm >=48dp, không overlap, nằm trong canvas, cuộn và chọn được ghế cuối. Không coi đây là sơ đồ đã seed trong DB hay device evidence.
- Mobile full suite: **796/796 test qua**, flutter analyze --no-pub sạch; hai file sửa format không đổi.
- Raw test/probe/fixture/backup nằm ngoài Git tại workspace/mobile-qa-evidence/auth-sync-20261106/.

## Bước nghiệm thu còn chờ

- API4002 đang là tiến trình cũ ở thời điểm viết. User cần Ctrl+C rồi chạy lại `node .\mobile-qa-evidence\shipments-device-20261105\run-qa.mjs api` từ workspace. Lệnh giữ DB QA3312, external SMTP/FCM/reminders đều tắt.
- Chạy probe-api.mjs sau khi API mới sẵn sàng để xác minh thiếu accountType400, customer login200, không đăng nhập thành admin, /me/tickets/chat, trip seats/points, shipments options, refresh/logout/revocation.
- Chưa có kết quả HTTP với API mới hoặc kiểm thử trên điện thoại cho bản đồng bộ này. Không dùng kết quả fixture để ghi PASS live.
- Chưa commit/push, chưa tạo PR riêng cho bản sửa auth, chưa sửa phần trạng thái hành trình vé theo quyết định lead.

APK debug đã build thành công sau kiểm thử; hash SHA-256: 83025ff50b1448b04dedbd6ca39313e1cf654180ab13df230333335de295b2f4. File ở workspace/mobile-qa-evidence/auth-sync-20261106/app-debug-auth-develop-sync.apk, ngoài Git. Có cảnh báo Kotlin incremental cache khác ổ C/D nhưng compiler fallback và build exit0. Chưa cài thiết bị.

## Nghiệm thu HTTP sau khi user khởi động lại API mới

- User xác nhận đã restart API; tiến trình mới tại cổng4002 (PID33392 khi kiểm tra). Login bằng customer fixture chỉ có trong DB QA3312 thành công.
- `probe-api.mjs`: **13/13 kiểm tra HTTP qua**: thiếu accountType400; customer không đăng nhập QUAN_TRI401; login KHACH_HANG200; /me200 đúng account; tickets200; support-chat/conversations200; trip detail200 có pickup/dropoff arrays; trip seats200; shipment options200; refresh200; /me sau refresh200; logout204; JWT sau logout401.
- Lượt đầu dùng trip778 đã hết ngày mở bán nên detail404 (TRIP_NOT_AVAILABLE), probe dừng đúng assertion. Sau khi xác minh quy tắc, chọn trip187 còn mở bán trong clone, không sửa trạng thái hoặc ngày chuyến để ép test qua. Trip187 là dữ liệu QA có sẵn, chỉ2 ghế và null tọa độ; kết quả HTTP này xác minh contract, không chứng minh đã seed7 sơ đồ mới.
- `native_auth_live_test.dart`: **1/1 qua** bằng chính AuthRemoteDataSourceImpl + ApiClient + HTTP thật + NestJS/MySQL QA. login200 -> hydrate/me200 -> reload/me200 -> logout204 -> local session null. Không MockClient, không auth guard override, không SMS thật. Không gọi đây là Android device E2E.
- JWT/password/refresh token chỉ ở bộ nhớ hoặc private fixture ngoài Git; output/report chỉ ghi status và số kiểm tra. Các phiên tạo bởi lượt probe hoàn chỉnh đã logout; không dùng tài khoản thật của người dùng.
- Vẫn chưa cài APK mới trên Android; chưa chạy seed/sync ghế/điểm diện rộng, chưa migrate DB chính. UI quên mật khẩu và việc phân loại trạng thái vé không nằm trong bản sửa này.
- Phần “Bước nghiệm thu còn chờ” phía trên là snapshot trước lần restart, đã hoàn tất phần HTTP/native datasource tại mục này. Chưa commit/push.
