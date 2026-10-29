# Đồng bộ sơ đồ ghế theo tọa độ — 26/10/2026

Mobile đọc `floor/x/y` từ `GET /api/v1/trips/{tripId}/seats` theo contract đã merge vào Backend `develop` tại `ce84991aa5176c11137105a349b2f28fd85b7b6b` (PR #46). Sơ đồ không còn suy ra từ loại xe nếu payload có contract tọa độ mới. Giữ icon, màu, Header/Stepper và luồng giữ ghế hiện có.

## Thay đổi

- `SeatModel` giữ tọa độ trong parse, copy, serialization và equality; phân biệt contract mới với fixture row/col cũ, kể cả API trả cả hai tọa độ là null.
- Resolver ưu tiên tọa độ và tầng do API trả về. Không sắp mã ghế để quyết định vị trí của ghế đã cấu hình. Các xe cùng loại vẫn có thể có sơ đồ khác nhau.
- Với ghế thiếu tọa độ, dùng chính sách Customer Web: các vị trí ngang 160/360/640/840, hàng cách 1000 đơn vị, tránh các ghế đã có tọa độ trên cùng tầng. Đây chỉ là vị trí dự phòng trên client; không gửi tọa độ này về API và không cập nhật DB.
- `SpatialSeatMap` đặt ghế theo tâm x/y, giữ hàng/cột thẳng và tỉ lệ khoảng trống. Không chèn nhãn dãy trái/phải hay dải lối đi cố định. Nếu dữ liệu dày hoặc chữ lớn, mở rộng canvas có thể cuộn ngang để giữ vùng chạm tối thiểu 48dp và tránh chồng ghế/nhãn/giá.
- Giữ phân biệt ghế trống, đang giữ, đã đặt, không khả dụng và state đang chọn của client. Callback vẫn dùng đúng `tripSeatId`; ghế không khả dụng không thể chọn.
- Refresh inventory sau hết hạn giữ ghế cũng dùng resolver như khởi tạo, tránh mất bố cục và tầng API.
- Fixture/offline payload cũ chỉ có row/col vẫn dùng renderer cũ. Không đổi API giữ ghế, booking, quote, payment hoặc session fence.

## DB local và Backend

Đã sao lưu DB chính `127.0.0.1:3306/vexgo` bằng mysqldump, xác minh SHA-256 và marker dump hoàn tất, rồi chạy `prisma migrate deploy` cho đúng 3 migration:

1. `20261025120000_add_vehicle_seat_layout`
2. `20261025130000_add_vehicle_delete_permission`
3. `20261025140000_add_trip_delete_permission`

Preflight sau migration không có migration thiếu hoặc dang dở. Số bản ghi 9 bảng ChuyenXe/Ghe/GheChuyenXe/Ve/DonGiaoDich/ThanhToan/TaiKhoan/CuocTroChuyen/TinNhanHoTro không đổi. Không reset, seed, xóa dữ liệu thử hoặc tự điền tọa độ. Chưa thử restore backup.

DB local hiện có 502 ghế xe và 6384 ghế chuyến; chưa có ghế nào có đủ x/y. Vì vậy dữ liệu này dùng fallback như Web, chưa phải bằng chứng kiểm thử live sơ đồ tùy chỉnh. Việc lưu sơ đồ riêng cần thực hiện qua chức năng Admin phù hợp.

Backend đã build thành công (gồm Prisma generate). Lần gọi build đầu không tìm thấy Nest CLI từ root; lần sau resolve CLI theo package của apps/api và thành công. Log lỗi ban đầu được giữ lại.

## Kiểm thử đã thực thi

Evidence nằm ngoài Git tại `mobile-qa-evidence/backend-sync-20261026/` của workspace:

| Kiểm tra | Kết quả |
| --- | --- |
| Flutter full suite | 393/393 qua |
| Coordinate/legacy seat/booking selection focused suite | 27/27 qua |
| Render suite với font thật (390dp, 320dp chữ 2x, landscape chữ 2x) | 9/9 qua |
| Flutter analyzer | Không có issue |
| Dart format lib/test | 167 file, 0 thay đổi |
| Backend unit tests trips/alternatives/vehicles/seat holds | 5 file, 123/123 qua |

Các regression mới kiểm tra tầng API ưu tiên hơn tiền tố B, copy/roundtrip tọa độ, hai xe cùng loại có bố cục khác nhau, null/partial coordinates tránh ghế đã cấu hình, giữ tỷ lệ khoảng trống và hàng/cột, hai tầng có số cột khác nhau, giữ lựa chọn theo ID khi chuyển tầng, vùng chạm/không chồng nhau ở chữ 2x, khóa ghế held/booked/unknown và inventory refresh sau hết hạn hold.

Lượt test đầu phát hiện overflow chiều cao nhãn/giá; đã sửa phép đo text để dùng DefaultTextStyle kế thừa giống SeatItem. Các log thất bại được giữ. Lỗi teardown SemanticsHandle của harness cũng đã được sửa bằng dispose trước thao tác render bất đồng bộ; không bỏ assertion.

Đã build APK debug Real Mode `app-debug-seat-coordinates.apk` (185599409 byte), SHA-256 `d7b61d947cf977752443596ab10517aa8819820a092058d94acf061bb47af580`. Artifact nằm trong `mobile-qa-evidence/ci-followup/`, ngoài Git. Đã đối chiếu hash bản copy và kiểm tra kernel có renderer/resolver tọa độ cùng API `http://127.0.0.1:4000/api/v1` (ADB reverse dự kiến 4000 → 4002). Manifest source/config/hash: `mobile-build-manifest.json` trong thư mục evidence của đợt này.

Đây là unit/widget/component tests và kiểm tra DB migration, không phải E2E đặt vé/thanh toán hoặc bằng chứng trên điện thoại thật. ADB chưa có thiết bị; người dùng đã chọn xem APK sau. Chưa commit, push hoặc merge PR.

## Kiểm tra API sau khi người dùng khởi động thủ công

- Đã xác nhận PID 12560 chạy đúng `vexgo_chat_worktree/apps/api/dist/main.js`, worktree tại `ce84991`, nhánh `integration/develop-mobile-20261026`; health cổng 4002 trả `data.status=ok`.
- Các chuyến cũ 766/767/768 đã qua ngày khởi hành, API trả 404 `TRIP_NOT_AVAILABLE`. Không đổi ngày/trạng thái hoặc tạo chuyến mới để vượt điều kiện mở bán.
- DB còn hai chuyến tương lai 149 (01/01/2099) và 187 (01/12/2099). Endpoint Customer trả lần lượt 1 và 2 ghế. Đây là dữ liệu có sẵn, không phải chuyến mới chuẩn bị cho demo.
- Đã gọi HTTP thật vào hai endpoint này rồi đưa response trực tiếp qua `SeatModel.fromJson` và `resolveSeatLayout` của Mobile. Cả 3 ghế giữ đúng ID, mã, tầng, trạng thái; tọa độ null được bố trí dự phòng không trùng vị trí. Evidence: `runtime-smoke.json`, `live-seat-payloads.json`, `live-mobile-layout-check.json` và log cùng tên.
- Mọi thao tác kiểm tra của đợt smoke là đọc; không tạo hold/booking/payment và không cấu hình sơ đồ trong DB. Hai payload thật đều có x/y null nên chưa chứng minh sơ đồ tùy chỉnh hoặc hai tầng bằng API live; các trường hợp đó đã được kiểm tra bằng fixture/widget tests.
- Kiểm tra trên Android thật vẫn chờ vì ADB chưa nhận thiết bị. Chưa cài APK mới.
