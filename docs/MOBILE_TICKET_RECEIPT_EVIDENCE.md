# Vé điện tử và chứng từ — dữ liệu bổ sung

Ngày 06/11/2026. Flutter `feature/mobile-accompanied-luggage`, base `8765e1e915fbac1fe840ce6fdbfd943bb67fb7f9` và working tree hiện tại. Đối chiếu Backend `0159558a6040dad9245796252d4b3ec66362c2dc`. Không sửa Backend/schema/migration trong thay đổi này.

## Điểm đón/trả đã đặt

- Model chung `StopSnapshot` đọc `diemDonSnapshot` và `diemTraSnapshot`: tên, địa chỉ, điện thoại, mã/loại điểm, độ lệch phút, thời gian có mặt, phụ phí và bến trung chuyển.
- Snapshot được giữ trong `TicketModel.toJson`, `copyWith` và equality, không truy vấn danh mục điểm hiện tại để ghi đè lịch sử.
- `departureAt` là thời điểm khởi hành của chuyến. Giờ tại điểm = `departureAt + phutLech`, áp dụng cho cả điểm đón và điểm trả theo contract Backend. Giờ phải có mặt = giờ đón − `phutCoMatTruoc`.
- Tính trên timestamp UTC; hiển thị theo giờ Việt Nam, có ngày đầy đủ để phân biệt điểm đón trước ngày khởi hành hoặc trả qua ngày. Giờ khởi hành ở phần tóm tắt chuyến vẫn giữ riêng.
- Nếu có snapshot nhưng thiếu độ lệch/thời điểm gốc, không gán giờ xuất bến làm giờ đón tại điểm. Không tự điền hạn có mặt mặc định. Vé cũ không có snapshot tiếp tục dùng dữ liệu legacy đã trả.
- BoardingPassCard hiển thị địa chỉ đầy đủ, thời gian tại điểm, thời gian có mặt, điện thoại và trung chuyển. Timeline dùng bố cục có xuống dòng để không cắt địa chỉ dài hoặc vỡ ở cỡ chữ 2x.

## Vật phẩm và tiền cấp đơn

- Model chung `EvidenceCargo` giữ tên, số lượng, cân nặng khai báo, mã/tên loại và ghi chú.
- TicketModel giữ `cargoItems`, `cargoFee`, `originalTicketSubtotal`, `ticketSubtotal`, `promotionCode` để không mất thông tin khi reload/copy/serialize.
- Màn vé hiển thị vật phẩm và phí với nhãn **toàn đơn**. `price`/`finalAmount` vẫn là giá một vé; không cộng cước cả đơn vào từng vé và không trừ lặp mức giảm của cả đơn.
- Nhãn tiền của BoardingPassCard là **Giá vé này**. Logic hủy vé, số tiền dự kiến hoàn và cổng QR không bị đổi bởi metadata hàng.
- Không tự tính tổng đơn từ một vé. Chứng từ tiếp tục dùng số tiền Backend trả, không thay thuật toán thu cước.

## Chứng từ

- BookingReceipt tái sử dụng cùng model snapshot/cargo và ưu tiên tên điểm đã chốt trong snapshot.
- UI chứng từ bổ sung địa chỉ, giờ tại điểm, thời gian có mặt, điện thoại/trung chuyển; vật phẩm có loại, kg và ghi chú.
- Phí chỉ hiển thị một lần trong phần tiền của chứng từ. Danh sách vật phẩm không cộng thêm phí.
- Giữ nguyên điều kiện đơn đã trả tiền và bảo vệ dữ liệu khi đổi phiên; không hiển thị chứng từ thanh toán cho đơn hủy/hết hạn/chưa xác minh đã trả tiền.

## Kiểm chứng

- `test/ticket_receipt_evidence_test.dart`: âm/dương/zero offset, qua ngày, không offset/không snapshot, timestamp có timezone, serialize/copy/equality, nhiều vé không cộng cước/giảm lặp, dữ liệu lỗi, vật phẩm/địa chỉ dài, 320x640 và 640x360 ở text scale 2x, đổi tài khoản xóa nội dung chứng từ.
- **465/465** kiểm thử hồi quy qua, gồm **23** ca mới; bao phủ thanh toán/đặt vé/khứ hồi/hành lý/gửi hàng/tài khoản/đánh giá/hủy vé và chứng từ. Log ở `mobile-qa-evidence/ticket-receipt-fix-20261106/regression-tests.log`.
- `flutter analyze --no-pub`: không có vấn đề. Build APK debug thành công; đã cập nhật file preview và manifest, kiểm tra chữ ký APK và launcher `COPY_LUGGAGE.ps1 -CheckOnly` thành công. ADB chưa có thiết bị nên chưa chép/cài hoặc kiểm thử Android. SHA-256 hiện hành trong `luggage-preview-20261106/MANIFEST.json`.
- Native Flutter đọc API4012/DB QA3313 xác nhận snapshot âm 35 phút, yêu cầu có mặt 15 phút, cargo metadata và cước 110.000đ/80.000đ được giữ đúng; giá vé 190.000đ không bị cộng thêm. Kiểm tra round-trip serialize/copy trên dữ liệu thật cũng qua.
- Hai đơn native được kiểm tra đã hủy; chứng từ bị từ chối đúng. Không coi đây là kiểm thử chứng từ PAID trên API thật. Chứng từ PAID và phần trình bày được kiểm tra bằng HTTP/widget fixture.
- Không tạo/sửa/hủy đơn, không chuyển tiền, không migrate DB trong lượt này. Chưa kiểm thử Android.

Log và bằng chứng ở `mobile-qa-evidence/ticket-receipt-fix-20261106/`: `regression-tests.log`, `evidence-tests.log`, `analyze.log`, `native.log`, `native-result.json`, `build.log`.

## Phần còn chờ

- Email vé vẫn phụ thuộc trường `passengerEmail` mà ticket API chưa trả. Không dùng email hồ sơ hiện tại để tự điền đơn lịch sử.
- Quy tắc hành lý chỉ dự tính, không thu cùng vé do teammate Backend xử lý; thay đổi này chưa áp dụng một quy tắc tiền mới.
- Chứng từ gộp hai chặng khứ hồi vẫn là phần mở rộng riêng; hiện chứng từ theo từng booking/chặng.
- Thay đổi chưa commit/push/tạo PR. APK preview vẫn dùng API4012/DB3313; bản báo cáo cũ giữ nguyên.


## Cập nhật 07/11/2026 — PR66

Đã đồng bộ contract cước dự tính thu tại bến trên Backend72decda và Mobile; giữ tổng lịch sử. Xem MOBILE_CARGO_COUNTER_PAYMENT_SYNC_20261107.md cho phạm vi, 486 test Flutter, 62 test Backend và giới hạn kiểm thử thật. Ghi chú chờ Backend loại cước khỏi tiền vé ở các phần trước là lịch sử; các vấn đề gói/bảng giá khác chưa mặc nhiên được giải quyết.
