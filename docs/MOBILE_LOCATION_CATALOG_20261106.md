# Danh mục địa điểm API và dữ liệu ghế/điểm đón trả — 06/11/2026

## Code Mobile

Worktree vexgo_auth_develop_sync_worktree, nhánh fix/mobile-auth-account-type (cùng lượt đồng bộ develop; chưa commit/push, PR #20 không thay đổi).

- LocationRepository gọi GET /api/v1/locations, validate danh mục, cache5phút và gộp request đang chạy. Empty/malformed/API lỗi không được lặng lẽ thay bằng asset cities.json trong Real Mode; lỗi không bị cache.
- RealTripRepository.getCities dùng repository mới. Gửi hàng đọc cùng TripRepository trong app; không tạo MockTripRepository làm nguồn mặc định nữa. Demo Mode vẫn có thể dùng fixture riêng theo cấu hình app.
- CityModel tách id, name và backendValue/searchValue, giữ aliases, kind, isLegacy và ghi chú sáp nhập. Mã opaque như current:79 không được gửi thẳng vào from/to. Repository tìm chuyến tra đúng ID trong catalog rồi gửi value do Backend cung cấp; ID không còn trong danh mục yêu cầu chọn lại.
- Bộ chọn chỉ đưa province/city/district vào lựa chọn tuyến. Station/bưu cục/điểm đón thực tế vẫn chọn sau khi có trip/route, không coi mọi station trong catalogue là điểm giao nhận hợp lệ của một tuyến.
- Tìm theo tên gọi khác/không dấu nếu API có alias; phân biệt địa danh cũ ở chip và list; không ghi “0 bến xe” giả cho địa điểm API. Chạm hàng không có danh sách bến con để chọn trực tiếp.
- Home chọn mặc định theo giá trị chuẩn thay vì hardcode ID HCM/DL; danh mục rỗng báo lỗi, thiếu điểm đến thì khóa tìm. Kiểm tra identity khứ hồi tính cả canonical value, không coi hai địa danh cũ/mới cùng value là hai đầu khác nhau.
- Không đổi API Backend, quyền đặt vé, trạng thái vé, quote/create-booking hoặc schema trong lượt này. Parser/renderer ghế và stop model đã có nên không thay renderer theo từng loại xe.

## Dữ liệu QA (không phải DB chính)

Target duy nhất: vexgo-shipments-device-20261105 / 127.0.0.1:3312/vexgo. Đã backup mã hóa và verify trước khi ghi, lưu ngoài Git tại workspace/mobile-qa-evidence/locations-sync-20261106/backups/; key riêng, không kèm archive.

Đã chạy theo prerequisites của pipeline develop f6ababc:

1. seed-locations-and-stations.mjs.
2. sync-all-trip-seats.mjs.
3. seed-crawled-operator-data.mjs: dry-run rồi --apply.
4. sync-all-route-and-trip-stops.mjs.

Lượt đầu chạy bước4 trước dữ liệu crawler bị Prisma validation do thiếu bến gốc Đà Lạt; dừng, đọc prerequisite rồi chạy bước3 và4 thành công. Không vá script Backend hoặc tự gán một bến khác để ép qua. File route-templates.json do seeder sinh được lưu ở evidence và khôi phục bản tracked ban đầu; Backend source vẫn giữ nguyên develop, untracked seed_future_trips.mjs của người dùng được giữ nguyên.

Đối chiếu SQL cuối lượt:

- 105 danh mục hành chính, 287 điểm bến/văn phòng.
- 7.322 ghế chuyến, 0 ghế thiếu tọa độ.
- 4.570 liên kết điểm theo chuyến, 0 trường hợp giờ dự kiến không khớp giờ xuất phát + phutLech (mod24h).
- 246 chuyến tổng cộng, **243 có điểm / 3 chưa có điểm**. Ba chuyến #148/#149/#187 thuộc tuyến QA #68/#97 cũ có tên lỗi mã hóa; script không khớp mẫu. Giữ nguyên chúng, không nhận kết luận “100% chuyến có điểm” chỉ từ thông báo console của script.
- Tạo thêm đúng1 fixture chuyến #790 (QA-LOCATIONS-20261107), ngày07/11/2026, route10 TP.HCM→Đà Lạt, sao cấu hình xe/giờ/sức chứa từ #778 và sơ đồ/điểm đã đồng bộ: 28ghế TRONG, 14điểm. Không tạo booking/payment. Fixture này chỉ trong clone, không phải dữ liệu bán vé thật.
- Vận đơn QA #29 vẫn tổng50.000đ. Không reset/seed/migrate/UPDATE DB chính3306 trong lượt này.

Dữ liệu crawler có cảnh báo template mỏng/chưa đầy đủ trong report nguồn; không gọi việc chạy seeder thành công là đã nghiệm thu toàn bộ nội dung tuyến hoặc địa chỉ nguồn.

## Kiểm chứng đã thực chạy

- 135/135 test thuộc các caller liên quan: catalogue, Home/discovery, gửi hàng, tìm chuyến, khứ hồi, route/operator và timed points. Sau chỉnh nhỏ thao tác chọn hàng địa điểm API, chạy lại catalogue+discovery:20/20 qua.
- Flutter analyze --no-pub: No issues found.
- Native Dart/Flutter datasource + API/NestJS/MySQL QA thật: 1/1 integration probe qua. Catalogue trả392 options; Mobile dùng105 địa điểm hành chính. Tìm TP.HCM→Đà Lạt ngày07/11/2026 qua ID catalog ra đúng #790; parse8 điểm đón,6 điểm trả với tripPointId và HH:mm, đọc28 ghế có tọa độ, tìm3 tuyến gửi hàng từ cùng canonical values. Không MockClient/auth bypass; không gọi là Android device E2E.
- API đã được người dùng restart để bỏ cache catalog24h sau nạp dữ liệu. HTTP probe trước khi API lên đã bị connection refused; không dùng các count null của lần đó làm bằng chứng.
- Evidence ngoài Git: database-sync-result.json, qa-future-trip.json, native-locations-result.json, feature-tests-final.log, các sync logs và native_locations_live_test.dart.
- Chưa cài lại APK trên máy thật hoặc đặt vé/giữ ghế thực trên sơ đồ đã đồng bộ trong lượt này; chưa kiểm thử Admin hoặc toàn bộ tuyến. Chưa commit/push.

APK debug mới build thành công; SHA-256 32da78d8d84e725d317c9ed50f7d5795f2600603bc60a6fb07e59978e4ac92b3. File workspace/mobile-qa-evidence/locations-sync-20261106/app-debug-location-catalog-sync.apk lưu ngoài Git, chưa cài Android. APK này gồm cả bản sửa accountType và danh mục mới.
