# Đồng bộ cước vật phẩm thu tại bến — 07/11/2026

## Snapshot

Mobile: `feature/mobile-accompanied-luggage`, base `8765e1e`, giữ các thay đổi local trước đó; chưa commit/push. Backend QA fast-forward develop tới `72decda` (PR66), source sạch. API4012 / DB QA3313; không migrate/reset/seed. Bản báo cáo API4002/DB3312 và APK dự phòng giữ nguyên.

## Contract và thay đổi

Tổng online mới chỉ gồm tiền vé sau giảm giá. Cước vật phẩm là dự tính thu tại bến, không cộng vào QR một chiều/khứ hồi. Vé giảm còn 0đ không phát sinh thanh toán online chỉ vì có vật phẩm. Mobile dùng tổng server khi đã có đơn.

`cargo_settlement.dart` đối chiếu tiền server: tổng bằng tiền vé là thu cước tại bến (nếu cước dương); tổng bằng vé cộng cước là đơn lịch sử đã gộp cước. Giữ nguyên tổng lịch sử, không trừ cước hoặc cộng lại. Thiếu metadata không suy diễn; đủ metadata nhưng tổng sai bị từ chối.

Tạo đơn mới có vật phẩm phải nhận contract mới. Nếu server trả contract gộp cước cũ, giữ ID phục hồi/kiểm tra, chặn QR và không tự tạo lại đơn. Màn đọc đơn/chứng từ lịch sử vẫn giữ số tiền server và nhãn đã cộng cước.

API từng vé không có tổng thanh toán toàn đơn: không suy cách thu từ giá một ghế; dùng nhãn trung lập và hướng dẫn xem chứng từ. Màn có tổng đơn dùng nhãn tương ứng thu tại bến/đã cộng trong tổng.

Phân loại bưu phẩm dùng nhóm danh mục API, không tự chuyển thành hàng cồng kềnh chỉ vì vượt 20kg, đồng bộ PR66. Không khẳng định mọi vấn đề bảng giá/gói trước đó đã được giải quyết. Gửi hàng độc lập giữ luồng thu phí riêng hiện có.

## Kiểm chứng đã chạy

- Backend build thành công; 62/62 unit test booking/payment-attempt/cargo-pricing qua.
- Flutter toàn bộ suite 486/486 qua, gồm 8 ca mới: tổng mới/lịch sử, thiếu metadata, tạo đơn gặp contract cũ, vé 0đ, combo QR, danh mục bưu phẩm và nhãn chứng từ.
- Analyze không có vấn đề; diff check không có lỗi whitespace.
- APK debug build thành công; chữ ký hợp lệ và hash khớp manifest/script CheckOnly.
- Native Flutter đọc API4012 đơn lịch sử #846: vé 190.000đ + cước 110.000đ = tổng 300.000đ được giữ nguyên. Đây là đơn đã hủy/chưa trả tiền, không phải kiểm chứng chứng từ paid.

Log tại workspace: `mobile-qa-evidence/cargo-counter-sync-20261107/`.

## Chưa chạy và bước tiếp

Chưa tạo đơn mới qua API thật: chuyến QA nhận hàng đều đã qua giờ; staff gọi API tạo chuyến bị 403 `PERMISSION_FORBIDDEN` cho quyền `trip:create`. Không tạo chuyến hoặc vượt quyền bằng SQL. Cần người có quyền tạo chuyến QA nhận hàng còn hiệu lực rồi kiểm thử tạo đơn, tổng QR và đọc lại/chứng từ. Chưa thực hiện thanh toán/webhook trong lượt này.

ADB chưa nhận thiết bị nên chưa chép/cài hoặc xác nhận Android. Dùng shortcut **VexGo - Hanh ly moi** khi kết nối, cập nhật APK thủ công từ Download/Vexgo, không gỡ app. Hash hiện hành: `luggage-preview-20261106/MANIFEST.json`.
