# Hủy vé và yêu cầu hoàn tiền qua hỗ trợ

## Quy tắc đã chốt

Hệ thống không hoàn tiền online. Sau khi hủy vé, khách liên hệ hỗ trợ và cung cấp mã vé để yêu cầu hoàn tiền theo chính sách nhà xe. Không tự hứa thời hạn hoặc hình thức hoàn tiền.

## Mobile

- Hiển thị quy tắc trước xác nhận và sau khi hủy, cho cả tài khoản đăng nhập và khách tra cứu.
- Chi tiết vé đã hủy có nút Liên hệ hỗ trợ, dùng route chat hiện có, không tự gửi tin nhắn. Khách tra cứu được nhắc đăng nhập để chat.
- Số tiền chỉ được ghi là Dự kiến hoàn; màn danh sách không trình bày như tiền đã chuyển.
- Giữ API quote/cancel, xác nhận phí, chống gửi trùng, session isolation và reconcile kết quả không rõ. Không tự sửa phí/giới hạn hủy.
- Hướng dẫn trong Thông tin VexGo được cập nhật cùng quy tắc.

## Backend đi kèm

Nhánh fix/manual-refund-support trong vexgo_payment_notifications_api_worktree dựa trên nhánh thông báo hiện có. Refund processor ngừng gọi provider, quét retry và tự hoàn tất giao dịch, kể cả với cấu hình provider cũ. Bản ghi HOAN_TIEN/DANG_XU_LY giữ để đối soát thủ công; refundAmount, phí và API response shape giữ nguyên. Nội dung thông báo/email/push hủy vé chỉ dẫn khách liên hệ hỗ trợ.

Không thêm migration, đổi schema hoặc ghi dữ liệu vào DB chính. Không thêm API đánh dấu hoàn tiền thủ công; đó là phần quản trị riêng nếu cần triển khai sau. API đang chạy chưa được tự khởi động lại theo nhánh này.

## Kiểm chứng

- 126/126 test Mobile liên quan qua, bao gồm hủy đăng nhập/khách, quote hết hạn, gửi trùng, kết quả không rõ, QR sau hủy, điều hướng hỗ trợ và màn hẹp/chữ 2x.
- Flutter analyze: No issues found.
- Backend: 54/54 unit test liên quan qua, TypeScript typecheck sạch.
- MySQL trong DB test riêng: 2 lifecycle test qua (51 ca khác bỏ qua do lọc chủ đích); khoản hoàn giữ pending, không gọi provider hoặc tạo notice/email/push hoàn thành. SMTP và push delivery không bật trong lần chạy này.
- Chưa kiểm thử thay đổi này trên điện thoại thật hoặc API chính đang chạy; chưa chuyển tiền/gửi email thật.

## Tách nhánh

Mobile: fix/mobile-manual-refund-support dựa trên commit 328c069 của PR #18. Backend: fix/manual-refund-support dựa trên nhánh thông báo. PR Mobile đặt trên nhánh của PR #18; merge PR cha trước rồi retarget sang develop và kiểm tra lại diff/CI. PR Backend đặt trên nhánh thông báo của PR #54. Không merge lặp thay đổi trong PR cha.

APK profile ARM64 build thành công (~32 MB), lưu tại mobile-qa-evidence/app-profile-manual-refund-support.apk bên ngoài repo. ADB chưa thấy điện thoại nên chưa chép/cài hoặc kiểm thử máy thật.
