# Bàn giao Agent — Tab Gửi hàng và form chọn tuyến đồng bộ Trang chủ

Ngày 05/11/2026. Đây là phạm vi người dùng đã duyệt, chưa phải báo cáo triển khai.

## 1. Workspace và điểm xuất phát

- Làm tại `D:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_standalone_shipments_worktree`.
- Nhánh `feature/mobile-standalone-shipments`; kiểm tra branch/SHA và git status trước khi sửa. Snapshot trước bàn giao: HEAD `762764e`, module gửi hàng vẫn có nhiều file untracked.
- Tiếp tục code hiện có, giữ mọi thay đổi của người dùng/Agent. Không reset, clean, checkout đè hoặc format hàng loạt.
- Đọc `MOBILE_STANDALONE_SHIPMENTS_CORE.md`, báo cáo `MOBILE_STANDALONE_SHIPMENTS_DEVICE_QA_20261105.md` và source hiện tại. Các kết luận P1 cũ trong handoff UI là lịch sử: hai lỗi nonce/PII đã có bản sửa và được kiểm tra; không quay về bản cũ.
- Codex phụ trách API/model/core; Agent phụ trách UI, navigation và widget tests của phạm vi này. Không commit/push/merge khi chưa được yêu cầu.

## 2. Yêu cầu đã chốt

1. Thanh điều hướng dưới có 5 mục theo thứ tự: **Trang chủ · Vé của tôi · Gửi hàng · Thông báo · Tài khoản**.
2. Gửi hàng là một branch độc lập, giữ ba khu vực bên trong: Tạo đơn, Tra cứu, Đơn của tôi.
3. Phần chọn tuyến đầu màn Tạo đơn giống form tìm chuyến Trang chủ: hai hàng chọn Điểm đi/Điểm đến, nút đổi chiều, hàng Ngày gửi và CTA Tìm tuyến gửi hàng.
4. Điểm đi/đến là selection có tìm kiếm, không còn ô nhập tự do. Ngày gửi dùng date picker.
5. Người gửi, người nhận, kiện hàng, điểm giao nhận, báo cước và xác nhận tạo đơn vẫn nằm phía dưới theo luồng hiện có.
6. Sửa kèm D01/D02 của báo cáo device: Back sau tạo đơn và hạn mang hàng thiếu giờ.

Không đưa khứ hồi, số hành khách, thao tác demo, dữ liệu QA hoặc chức năng chuyển khoản vào form gửi hàng.

## 3. File và phạm vi sửa

Đường dẫn dưới đây tương đối với worktree:

| File | Công việc |
| --- | --- |
| `lib/app/routes.dart` | Chuyển `/shipments` từ GoRoute root sang StatefulShellBranch riêng; thêm navigator key; không khai báo trùng path. |
| `lib/features/user/main_shell/main_shell_screen.dart` | Thêm item Gửi hàng ở index 2. Thông báo chuyển thành index 3, Tài khoản index 4. Sửa điều kiện refresh thông báo hiện đang hardcode `index == 2`. |
| `lib/features/user/profile/presentation/screens/profile_screen.dart` | Bỏ mục Gửi hàng trùng sau khi có bottom tab. Kiểm tra mọi caller `/shipments` còn lại đi đúng branch. |
| `lib/features/user/shipments/presentation/screens/shipments_host_screen.dart` | Thích ứng branch root, bỏ Back vô nghĩa ở trang gốc; giữ Back nội bộ và xử lý D01; bảo toàn owner/state khi chuyển bottom tab. |
| `lib/features/user/shipments/presentation/widgets/shipment_create_view.dart` | Form chọn tuyến mới và nối selection vào flow hiện tại. Có thể tách widget nhỏ trong module shipments. |
| `lib/features/user/shipments/presentation/widgets/shipment_detail_view.dart` | Hạn mang hàng có ngày và giờ local; xử lý D02. |
| `lib/features/user/shipments/presentation/widgets/shipment_lookup_view.dart` | Hiển thị hạn mang hàng cùng quy tắc detail. |
| `test/standalone_shipments_ui_test.dart` và test navigation mới nếu cần | Regression cho navigation, selectors, owner và Back. |

File tham khảo, ưu tiên tái sử dụng; không làm thay đổi luồng đặt vé:

- `lib/features/user/home/presentation/widgets/search_form_card.dart`
- `lib/features/user/home/presentation/screens/select_city_sheet.dart`
- `lib/data/models/city_model.dart`
- `lib/data/adapters/city_search_adapter.dart`
- `lib/data/repositories/trip_repository.dart`
- `lib/core/design/discovery_theme.dart`, `lib/core/constants/app_dimensions.dart`

Không sửa `shipment_model.dart`, `shipment_repository.dart`, `shipment_flow_cubit.dart`, ApiClient, Backend/schema hoặc pubspec để lách UI. Nếu thiếu API core thì báo Codex kèm tình huống tái hiện.

## 4. Thiết kế form chọn tuyến

Giữ font/tokens/spacing/icon và phân cấp giống SearchFormCard; tham khảo cấu trúc, không bê cả HomeBloc hoặc booking state sang gửi hàng.

```text
┌──────────────────────────────────────┐
│ ◉  Điểm đi                           │
│    Chọn tỉnh/thành phố                │
│    ───────────────────────────   ⇅    │
│ ◉  Điểm đến                          │
│    Chọn tỉnh/thành phố                │
│ ──────────────────────────────────── │
│ ▣  Ngày gửi                          │
│    [Ngày đã chọn]                ›    │
│                                      │
│       Tìm tuyến gửi hàng              │
└──────────────────────────────────────┘
```

- Nhãn luôn hiện, giá trị đã chọn rõ hơn nhãn; tên dài được wrap hợp lý, không tràn hoặc che nút đổi chiều.
- Chạm cả hàng mở SelectCitySheet; icon đổi chiều có tooltip/semantics, vùng chạm tối thiểu 48dp.
- Selector là hàng tương tác/read-only, không bật bàn phím nhập tuyến. Sheet vẫn có ô tìm kiếm.
- Ngày hiển thị dễ đọc nhưng chuyển đúng `DD-MM-YYYY` khi gọi core. Giữ validation ngày hiện có; không tự thêm giới hạn nghiệp vụ.
- Không cho tìm khi chưa đủ hai thành phố/ngày hoặc hai thành phố trùng nhau; giải thích tại vùng liên quan.
- Nút Tìm tuyến có loading và chống bấm lặp; lỗi/không có tuyến hiện sát kết quả, cho thử lại.
- Không tái thiết kế toàn bộ form liên hệ/kiện hàng ngoài các chỉnh sửa cần để hòa hợp spacing.
- Áp dụng skill `C:/Users/HP/.codex/skills/ui-ux-pro-max/SKILL.md`: nhãn rõ, phản hồi submit, tương tác dễ chạm, responsive và giảm chuyển động khi hệ thống yêu cầu.

## 5. Nguồn dữ liệu và nối core — đọc kỹ

**Không có bằng chứng về API danh mục thành phố đang dùng ở Trang chủ.** Source hiện tại: `HomeBloc` gọi `TripRepository.getCities()`; ngay cả `RealTripRepository.getCities()` cũng đọc `assets/mock_data/cities.json`. Vì vậy tái sử dụng danh mục qua repository hiện có; không gọi một endpoint tự nghĩ ra, không tuyên bố danh mục này lấy từ DB/API. Không tạo bản sao danh sách trong widget.

- Có thể tái sử dụng SelectCitySheet với List<CityModel> được tải độc lập cho gửi hàng. Không dispatch sự kiện chọn thành phố/ngày của HomeBloc: thay đổi gửi hàng không được đổi bộ tìm chuyến vé.
- Không phụ thuộc việc Trang chủ tải popular routes/operators thành công mới cho chọn thành phố. Có loading/error/retry cho catalog và xử lý danh sách rỗng an toàn.
- Dùng `CitySearchAdapter.resolveBackendSearchCity` theo cách source booking/shipment đang dùng để gửi giá trị canonical; không gửi nhầm ID catalog làm routeId hoặc pointId.
- Danh mục thành phố chỉ là lựa chọn tìm kiếm. **API gửi hàng mới quyết định tuyến, nhà xe, điểm gửi/nhận, cước và điều kiện thực sự hỗ trợ.** Không tạo tuyến/giá fallback khi không có kết quả.
- Chọn tuyến qua `searchRoutes(from, to, date)` → `selectRoute(routeId)` → options điểm gửi/nhận → draft/quote. Điểm đi/đến tỉnh/thành khác với dropdown điểm giao nhận hàng.
- Khi đổi/đảo thành phố hoặc đổi ngày, vô hiệu tuyến/điểm/draft/quote cũ bằng API public hiện có như `clearRouteSelection()`. Không để response trễ hoặc giá cũ làm hiện nút tạo hợp lệ.
- Chỉ giữ thông tin liên hệ/kiện hàng qua thay đổi tìm kiếm trong cùng phiên nếu vẫn nối lại thành draft hợp lệ theo tuyến mới; tuyệt đối không giữ qua đổi tài khoản. Không tự đoán/khôi phục điểm giao nhận từ tuyến cũ.

## 6. Navigation và an toàn giao dịch

- StatefulShellBranch giữ instance host khi đổi bottom tab. Chuyển sang Vé/Thông báo rồi quay lại không tạo lại Cubit/repository, không mất form/quote và không POST tạo đơn.
- Kiểm tra cả chạm lại tab Gửi hàng đang active: `goBranch(initialLocation: true)` không được âm thầm reset owner hoặc bỏ trạng thái uncertain/submitting. Không dựa vào PopScope như thể nó chắc chắn bắt được mọi chuyển branch.
- Giữ expectedSessionVersion, request epochs, single-flight, quote freshness/fingerprint và account invalidation hiện có.
- Đơn uncertain: giữ payload/nonce; chỉ explicit retry qua core hiện có. Không tạo repository mới khi đổi tab để né guard.
- Sau một đơn đã xác minh, Tạo đơn khác phải có repository/nonce mới. Cùng payload của hai ý định tạo mới vẫn phải tạo hai đơn khác nhau; giữ bản sửa hiện tại.
- D01: Back từ chi tiết đơn vừa tạo không được mở ShipmentCreateView với phase created và controller trống. Chọn hành vi rõ ràng: về danh sách hoặc bắt đầu form mới sau đơn đã xác minh. Back từ đơn mở ở Đơn của tôi quay lại danh sách, giữ filter/search/page. Không reset uncertain/submitting; không close Cubit được inject từ bên ngoài.
- Khi đổi phiên/account, xóa PII/controller/quote/detail/list theo cơ chế owner hiện có. Không chỉ che dữ liệu trong Snackbar.
- Không sửa TabPageHeader dùng chung chỉ để thay header gửi hàng. Nếu cần, dùng cấu hình cục bộ; tránh ảnh hưởng màn khác.

## 7. D02 — Hạn mang hàng

Detail và lookup hiện format deadline chỉ có ngày. Dùng `dropoffDeadline.toLocal()` và hiển thị cả **HH:mm + ngày**. Không cộng thêm 72h ở client, không tự dựng timestamp; null thì không giả định hạn. Nếu hiển thị thời điểm confirmedAt, cũng thể hiện giờ rõ ràng. Giữ các trạng thái cước dự tính/chốt, tiền đã thu/còn phải thu và chưa phân chuyến.

## 8. Kiểm thử và bàn giao kết quả

Các kiểm tra cần có sau thay đổi:

1. Năm tab đúng thứ tự; Thông báo vẫn refresh ở đúng index; deep link `/shipments` vào đúng branch; Trang chủ/Tài khoản/Vé không lệch route.
2. Điểm đi/đến mở selector, chọn/đổi chiều/hủy sheet; bộ tìm chuyến ở Trang chủ không đổi theo. Catalog rỗng/lỗi có phản hồi.
3. Request options dùng canonical city/date đúng; API trả rỗng không giả dữ liệu; đổi thành phố/ngày bỏ route/points/quote cũ, response trễ không khôi phục giá cũ.
4. Chuyển bottom tab rồi quay lại giữ cùng owner/form, kể cả pending/uncertain; không thêm POST. Chạm lại tab active không né guard.
5. D01 cho cả chi tiết từ Tạo đơn và từ danh sách; D02 đúng giờ local trong detail/lookup.
6. Hai đơn mới cùng nội dung dùng khóa mới; explicit retry uncertain dùng lại khóa cũ; đổi account không lộ form cũ. Giữ regression P1 hiện có.
7. Màn 320dp/360dp, text scale 2x, landscape, bàn phím và safe area không overflow. Tên tỉnh dài và đủ 5 nhãn bottom tab đọc được.

Chạy test core/UI gửi hàng hiện có, test navigation mới và analyze các file Dart sửa. Báo số test thực chạy, lệnh và lỗi cụ thể; không gọi widget/fixture là device E2E. Không cần Docker để chỉnh UI/chạy widget test; live API/Android cần môi trường riêng.

Snapshot QA trước handoff: 47 test/probe qua và TabPageHeader 2/2; probe Back riêng vẫn thất bại. Đây là bằng chứng trước thay đổi, **không phải kết quả của lượt Agent mới**. Hai đơn test thực #27/#28 ở DB cách ly, không tạo thêm dữ liệu/áp dụng migration DB chính trong nhiệm vụ UI.

Cuối lượt cập nhật báo cáo `MOBILE_STANDALONE_SHIPMENTS_UI.md`: file đã sửa, cách giữ owner/idempotency, kiểm thử thật, ảnh trước/sau nếu có và phần còn chưa xác minh. Dẫn link handoff này để phân biệt phạm vi mới với lịch sử review cũ. Không đưa env/secret, XML/ảnh có PII hoặc bằng chứng QA thô vào Git.
