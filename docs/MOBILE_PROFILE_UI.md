# Tài liệu Bàn giao — UI Hồ sơ & Quản lý Tài khoản (`ProfileScreen`, `EditProfileDialog`, `ChangePasswordDialog`)

**Ngày cập nhật**: 28/10/2026  
**Worktree**: `vexgo_profile_ui_worktree`  
**Branch**: `feature/mobile-profile-ui`  
**Base commit (HEAD)**: `774450aac36e105d5b0463a0a9a87d57788bf73a`  
**Baseline tests**: 472/472. Sau Agent sửa F01–F04: 489/489. Sau sửa route từ re-review: **492/492 tests qua**; xem mục 8 cho kết quả mới nhất.

---

## 1. Phạm vi Triển khai & Mục tiêu Thiết kế

1. **Chuẩn hóa Design System (`DiscoveryTheme`)**:
   - Sử dụng thống nhất hệ thống design token của VexGo (`DiscoveryColors`, `DiscoveryTextStyles`, `AppDimensions`).
   - Giao diện hiện đại, tối giản, màu sắc thương hiệu Trust Blue (`DiscoveryColors.primary`) và Energy Orange (`DiscoveryColors.secondary`), nền trung tính `DiscoveryColors.background`.
   - Đạt chuẩn tương phản, typography font chuẩn `VexGoJakarta`, không crop, méo hay tràn layout.
   - Kiểm thử ma trận responsive trên các profile màn hình:
     - 390×844 chữ 1.0x (chuẩn điện thoại hiện đại).
     - 320×740 chữ 2.0x (màn hẹp, font siêu lớn người già/trợ năng, kế thừa qua overlay route).
     - 640×360 landscape chữ 2.0x kèm bàn phím (xoay ngang màn hình).

2. **Các file triển khai chính trong nhiệm vụ UI**:
   - `lib/features/user/profile/presentation/screens/profile_screen.dart`: Màn hình Hồ sơ chính. Bỏ AppBar đỏ cao nặng nề, thay bằng Header ngắn "Tài khoản". Thẻ định danh người dùng (User Card) hiển thị avatar ký tự đầu, họ tên hỗ trợ 2 dòng chống tràn, SĐT, email fallback "Chưa cập nhật email". Thẻ điểm tích lũy thật từ `user.diemTichLuy`. Loại bỏ triệt để menu giả (không hotline giả 1900 6067, không toggle thông báo giả lập, không voucher/chuyến đi giả). Hộp thoại xác nhận đăng xuất an toàn chống tràn chữ lớn.
   - `lib/features/user/profile/presentation/widgets/edit_profile_dialog.dart`: Bottom sheet chỉnh sửa thông tin cá nhân. Số điện thoại chỉ đọc có badge xác thực. Kiểm tra validation bắt buộc họ tên. Xếp dọc linh hoạt (LayoutBuilder) khi màn hình hẹp 320dp hoặc chữ 2.0x. Tích hợp `BlocListener` tự động đóng sheet định danh bằng `removeRoute` khi phiên đăng xuất hoặc đổi tài khoản, xóa sạch draft controllers, đồng thời dùng `GlobalKey` bảo toàn `EditableTextState` khi xoay màn hình.
   - `lib/features/user/profile/presentation/widgets/change_password_dialog.dart`: Dialog đổi mật khẩu thiết kế chuẩn `DiscoveryTheme`. Bổ sung toggle ẩn/hiện mật khẩu (mặc định ẩn) kèm tooltip trợ năng. Giữ nguyên toàn bộ ValueKeys (`Mật khẩu hiện tại`, `Mật khẩu mới`, `Xác nhận mật khẩu mới`, `Lưu mật khẩu`, `Hủy`) và validation UTF-8 byte (8–72 bytes). Tích hợp kiểm tra `ownerUserId` thu hồi tức thì và xóa sạch controllers khi chuyển phiên tài khoản.
   - `.github/workflows/flutter-ci.yml`: Bổ sung branch `feature/mobile-ticket-detail-ui` vào danh sách `pull_request.branches` để CI tự động kích hoạt.
   - `test/profile_ui_comprehensive_test.dart`: Bộ 17 ca kiểm thử hồi quy UI toàn diện bao phủ toàn bộ 6 nhóm yêu cầu ban đầu kèm 4 probe độc lập xác minh triệt để các phát hiện F01, F02, F03, F04.

---

## 2. Chi tiết Kiến trúc & Giao diện Thành phần

### 2.1. Màn hình Hồ sơ chính (`ProfileScreen`)
- **Header trang**:
  - Tiêu đề "Tài khoản" ngắn gọn, font h2 đậm nét theo chuẩn trang Tab, bỏ khối AppBar màu đỏ chiếm dụng diện tích.
- **Thẻ định danh (Identity Card)**:
  - *Chế độ Khách (Guest)*: Hiển thị icon người dùng trung tính, tiêu đề *"Chào mừng bạn đến với VexGo"*, mô tả lợi ích và nút CTA *"ĐĂNG NHẬP / ĐĂNG KÝ"* mở `AuthModalSheet.show(context)`. Không lộ bất kỳ dữ liệu cá nhân nào.
  - *Chế độ Đã đăng nhập (Authenticated)*:
    - Avatar dạng hình tròn với ký tự đầu viết hoa của họ tên trên nền `DiscoveryColors.primaryLight`.
    - Họ và tên: Typography h4 đậm, hỗ trợ bọc chữ tối đa 2 dòng không bị cắt cụt. Kèm huy hiệu tick xanh xác thực nếu SĐT đã xác thực.
    - Số điện thoại: Định dạng số rõ ràng.
    - Email: Hiển thị email người dùng; nếu chưa có hoặc rỗng thì hiển thị fallback *"Chưa cập nhật email"* màu xám trung tính.
    - Nút tác vụ nhanh: Nút icon chỉnh sửa mở `EditProfileDialog.show(context, user: user)`.
- **Thẻ Điểm tích lũy VexGo (`PointsCard`)**:
  - Icon ngôi sao `DiscoveryColors.secondary` trên nền cam nhạt.
  - Hiển thị chính xác số điểm từ `user.diemTichLuy` thật.
  - Tuyệt đối không gắn nhãn hạng thành viên giả lập khi backend chưa hỗ trợ.
- **Nhóm Quản lý tài khoản & Thông tin ứng dụng**:
  - Gồm 2 mục menu hoạt động thật:
    1. *Thông tin cá nhân* (`Icons.person_outline_rounded`): Mở bottom sheet chỉnh sửa thông tin.
    2. *Đổi mật khẩu* (`Icons.lock_outline_rounded`): Mở dialog đổi mật khẩu.
  - *Thông tin ứng dụng*: Ngôn ngữ ("Tiếng Việt"), Phiên bản ("1.0.0").
  - **Khắc phục tràn chữ lớn (`_MenuRow`)**: `_buildMenuContainer` sử dụng `LayoutBuilder` kiểm tra nếu chiều rộng khả dụng hẹp (< 280dp) hoặc `textScaleFactor > 1.25x`, tự động xếp `trailingText` xuống dòng dưới `subtitle` thay vì ép Row ngang, loại bỏ hoàn toàn nguy cơ tràn ngang 35px.
- **Tác vụ Đăng xuất (`Logout Action`)**:
  - Nút bấm `TextButton.icon` đặt ở cuối trang với màu đỏ cảnh báo `DiscoveryColors.error`.
  - Chạm vào mở AlertDialog xác nhận đăng xuất với 2 lựa chọn: *"Ở lại"* (hủy, đóng dialog) và *"Đăng xuất"* (xác nhận, phát `LogoutEvent()`).
  - **Khắc phục tràn chữ lớn Dialog đăng xuất**: Bọc title `Text('Đăng xuất')` trong `Expanded` kèm cấu hình `actionsOverflowButtonSpacing: 8` và `actionsOverflowDirection: VerticalDirection.down` để tự động xếp dọc hai nút "Ở lại" và "Đăng xuất" khi màn hình hẹp 320dp với text scale 2.0x, triệt tiêu lỗi tràn 110px.

---

### 2.2. Bottom Sheet Chỉnh sửa thông tin (`EditProfileDialog`)
- **Khối đầu trang (Header)**:
  - Thanh drag-handle ở giữa, icon huy hiệu `Icons.badge_outlined`, tiêu đề *"Chỉnh sửa thông tin cá nhân"*, nút đóng tròn.
- **Trường Họ và tên (Bắt buộc)**:
  - Bắt buộc nhập, kiểm tra validation không được để trống hoặc chỉ chứa khoảng trắng. Hiển thị thông báo lỗi tức thì khi submit.
- **Trường Số điện thoại (Chỉ đọc - Read-only)**:
  - Background xám `neutral100`, viền `neutral300`.
  - Huy hiệu trạng thái *"Đã xác thực"* (xanh lá) hoặc *"Chưa xác thực"* (xám).
  - Chú thích rõ ràng: *"Số điện thoại dùng để đăng nhập và tra cứu vé, không thể thay đổi."*.
  - Tự động bọc cột dọc khi màn hình hẹp hoặc text scale 2.0x để chống tràn pixel.
- **Trường Email, CCCD, Ngày sinh**:
  - Input field chuẩn mực với placeholder và prefix icons.
  - `LayoutBuilder` tự động xếp dọc (Column) cho CCCD và Ngày sinh khi màn hình có chiều rộng < 360dp hoặc chữ lớn, xếp ngang 2 cột (Row) khi màn hình rộng.
- **Bảo toàn Focus và EditableTextState khi xoay màn hình (F03 Fix)**:
  - Gán `GlobalKey<FormFieldState<String>>` cho cả hai trường CCCD (`_cccdFieldKey`) và Ngày sinh (`_dobFieldKey`).
  - Khởi tạo và quản lý toàn bộ `FocusNode` (`_nameFocusNode`, `_emailFocusNode`, `_cccdFocusNode`, `_dobFocusNode`) tại `State` thay vì tạo mới trong `build()`.
  - Nhờ vậy, khi màn hình đổi hướng từ dọc sang ngang (Column sang Row(Expanded)), Flutter reparent element tree và giữ nguyên vẹn `EditableTextState`, focus và bàn phím ảo.
- **Thanh tác vụ (Actions Dock)**:
  - Nút *"Lưu thay đổi"* (FilledButton) và nút *"Hủy"* (OutlinedButton).
  - Tự động xếp chồng dọc khi bề rộng khả dụng hẹp, xếp ngang khi đủ chỗ.
- **Bảo vệ phiên làm việc đa tầng (F02 Fix)**:
  - `EditProfileDialog.show` bọc `BlocProvider.value` truyền `AuthBloc` vào route của bottom sheet.
  - Lưu tham chiếu định danh route `_route ??= ModalRoute.of(context)` trong `didChangeDependencies`.
  - Khi có sự kiện đăng xuất hoặc chuyển đổi tài khoản:
    1. Đánh dấu cờ `_isRevoked = true`.
    2. Dọn sạch bản thảo với `_clearDraft()`.
    3. Thu hồi chính xác route của sheet bằng `Navigator.of(context).removeRoute(_route!)` (nếu có modal khác đè lên) hoặc `Navigator.pop(context)` (nếu là top route). Không gây đóng nhầm modal bên trên.
  - Trong callback `_onSave`: Kiểm tra `if (_isRevoked || currentUser?.taiKhoanId != widget.user.taiKhoanId) { _revokeAndDismiss(); return; }` để triệt tiêu tuyệt đối việc phát tán bản thảo người dùng A sang phiên làm việc của người dùng B.

---

### 2.3. Hộp thoại Đổi mật khẩu (`ChangePasswordDialog`)
- **Giao diện & Trải nghiệm**:
  - Thiết kế `AlertDialog` hiện đại, bo góc 16dp.
  - Header icon ổ khóa tròn màu xanh `DiscoveryColors.primaryLight`.
  - Bổ sung nút bấm ẩn/hiện mật khẩu (toggle visibility icon) cho cả 3 trường:
    - *Mật khẩu hiện tại*
    - *Mật khẩu mới*
    - *Xác nhận mật khẩu mới*
  - Mặc định ở trạng thái ẩn mật khẩu (`obscureText: true`). Nút toggle có tooltip và semantic label hỗ trợ trợ năng: *"Hiện mật khẩu"* / *"Ẩn mật khẩu"*.
- **Bảo toàn Contract Kiểm thử**:
  - Giữ nguyên các `ValueKey`:
    - `ValueKey('Mật khẩu hiện tại')`
    - `ValueKey('Mật khẩu mới')`
    - `ValueKey('Xác nhận mật khẩu mới')`
  - Giữ nguyên nhãn nút bấm: `'Lưu mật khẩu'` và `'Hủy'`.
  - Giữ nguyên quy tắc kiểm tra độ dài UTF-8 byte (8–72 bytes) và bảo toàn ký tự khoảng trắng không tự ý trim.
- **Thu hồi phiên & Dọn sạch bộ nhớ khi đổi tài khoản (F01 Fix)**:
  - Nhận `ownerUserId` (hoặc tự động xác định từ `AuthBloc.state.user?.taiKhoanId` khi mở dialog).
  - `BlocListener` lắng nghe `listenWhen: (previous, current) => !current.isAuthenticated || current.user?.taiKhoanId != _ownerUserId`.
  - Khi phát hiện đăng xuất hoặc đăng nhập bằng tài khoản khác B:
    1. Đánh dấu `_isRevoked = true`.
    2. Xóa sạch dữ liệu nhạy cảm trong RAM bằng `_clearControllers()`.
    3. Đóng dialog ngay lập tức qua `Navigator.of(context).pop()`.
  - Trong `_submit`: Chặn submit nếu `_isRevoked` hoặc `currentUser?.taiKhoanId != _ownerUserId`.

---

## 3. Cập nhật Quy trình CI (`flutter-ci.yml`)

File `.github/workflows/flutter-ci.yml` đã được cập nhật bổ sung branch `feature/mobile-ticket-detail-ui` vào danh sách `pull_request.branches`:
```yaml
on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches:
      - main
      - master
      - develop
      - feature/mobile-my-tickets-ui
      - feature/mobile-ticket-detail-ui
```

---

## 4. Chi tiết Bộ Kiểm thử Hồi quy Toàn diện (`profile_ui_comprehensive_test.dart`)

Bộ kiểm thử gồm 17 test cases bao phủ trọn vẹn 6 nhóm chức năng ban đầu và 4 test probe review độc lập:

| STT | Nhóm kiểm thử | Tên Test Case | Kết quả |
| :---: | :--- | :--- | :---: |
| 1 | Guest Profile | Guest view shows greeting, login CTA, and no private data | **PASS** |
| 2 | Authenticated Profile | Authenticated view displays user card, points, and clean real menu items | **PASS** |
| 3 | Authenticated Profile | Missing email renders fallback text "Chưa cập nhật email" and long names wrap | **PASS** |
| 4 | Logout Dialog | Logout confirmation dialog: cancel stays, confirm dispatches LogoutEvent | **PASS** |
| 5 | Edit Profile | Renders pre-filled values, read-only phone and verified badge | **PASS** |
| 6 | Edit Profile Validation | Empty full name validation blocks submission | **PASS** |
| 7 | Edit Profile Mutation | Valid edits dispatch UpdateProfileEvent and close dialog | **PASS** |
| 8 | Session Safety | Session safety: EditProfileDialog automatically closes on logout or account switch | **PASS** |
| 9 | Change Password UX | Password visibility toggle flips obscureText and tooltip appropriately | **PASS** |
| 10 | Responsive Matrix | Standard phone (390x844, 1.0x text scale) renders cleanly | **PASS** |
| 11 | Responsive Matrix | Compact phone (320x740, 2.0x text scale) renders without overflow | **PASS** |
| 12 | Responsive Matrix | Compact phone (320x740, 2.0x text scale) on EditProfileDialog wraps without overflow | **PASS** |
| 13 | Responsive Matrix | Landscape phone with open keyboard (640x360, 2.0x text scale) scrolls without overflow | **PASS** |
| 14 | F01 Review Probe | ChangePasswordDialog automatically revokes and clears controllers when switching account from A to B | **PASS** |
| 15 | F02 Review Probe | EditProfileDialog retracted properly even when another modal is stacked on top and blocks draft submission | **PASS** |
| 16 | F03 Review Probe | EditProfileDialog preserves CCCD focus and EditableTextState across viewport rotation (320x740 -> 640x360) | **PASS** |
| 17 | F04 Review Probe | Compact phone (320x740, 2.0x text scale inherited by overlay) renders menu and logout dialog without overflow | **PASS** |

---

## 5. Báo cáo Kết quả Quality Gates

1. **Kiểm tra Định dạng (`dart format`)**:
   ```bash
   dart format --output=none --set-exit-if-changed lib/features/user/profile/ test/profile_ui_comprehensive_test.dart
   ```
   - **Kết quả**: 0 files changed — Đạt chuẩn 100%.

2. **Phân tích Tĩnh (`flutter analyze`)**:
   ```bash
   flutter analyze --no-pub
   ```
   - **Kết quả**: `No issues found!` (0 errors, 0 warnings, 0 lints).

3. **Kiểm tra Hồi quy Cục bộ (`Targeted Tests`)**:
   ```bash
   flutter test test/profile_ui_comprehensive_test.dart test/change_password_regression_test.dart test/auth_and_profile_flow_test.dart
   ```
   - **Kết quả**: 42/42 tests qua (100% PASS).

4. **Kiểm tra Toàn bộ Ứng dụng (`Full Test Suite`)**:
   ```bash
   flutter test
   ```
   - **Kết quả**: **489/489 tests qua (100% PASS)** — Không phát sinh bất kỳ lỗi hồi quy nào.

5. **Kiểm tra Trắng Git (`git diff --check`)**:
   - **Kết quả**: Hoàn toàn sạch, không có trailing whitespace hay conflict markers.

---

## 6. Danh sách Tệp thay đổi & Tạo mới

- [`.github/workflows/flutter-ci.yml`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_profile_ui_worktree/.github/workflows/flutter-ci.yml)
- [`lib/features/user/profile/presentation/screens/profile_screen.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_profile_ui_worktree/lib/features/user/profile/presentation/screens/profile_screen.dart)
- [`lib/features/user/profile/presentation/widgets/edit_profile_dialog.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_profile_ui_worktree/lib/features/user/profile/presentation/widgets/edit_profile_dialog.dart)
- [`lib/features/user/profile/presentation/widgets/change_password_dialog.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_profile_ui_worktree/lib/features/user/profile/presentation/widgets/change_password_dialog.dart)
- [`test/profile_ui_comprehensive_test.dart`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_profile_ui_worktree/test/profile_ui_comprehensive_test.dart)
- [`docs/MOBILE_PROFILE_UI.md`](file:///d:/A_KhoaLuanTotNghiep/HeThongDatVeXeKhachTrucTuyen_Application/vexgo_profile_ui_worktree/docs/MOBILE_PROFILE_UI.md)

---

## 7. Bảng Tổng hợp Xử lý 4 Phát hiện Review Độc lập (F01–F04)

| Mã | Mức độ | Hiện tượng trước sửa đổi | Giải pháp kỹ thuật đã áp dụng | Kết quả kiểm chứng |
| :---: | :---: | :--- | :--- | :---: |
| **F01** | **P1 (Security)** | `ChangePasswordDialog` chỉ kiểm tra `!current.isAuthenticated`, không thu hồi khi chuyển tài khoản từ Authenticated A sang Authenticated B. | Gán `ownerUserId` từ session mở dialog; `listenWhen` và `listener` phát hiện `state.user?.taiKhoanId != _ownerUserId` thu hồi dialog ngay lập tức và dọn sạch `TextEditingController` bằng `_clearControllers()`. Guard `_submit` ngăn gửi request sai owner. | Test Probe #14 PASS; mật khẩu của A không thể dùng để submit sang B. |
| **F02** | **P1 (Security & UX)** | `EditProfileDialog` gọi `Navigator.pop(context)` đóng nhầm modal đè lên thay vì chính nó; `_onSave` không kiểm tra owner khiến gửi draft của A sang session của B. | Lưu `_route ??= ModalRoute.of(context)` trong `didChangeDependencies`; thu hồi chính xác bằng `Navigator.of(context).removeRoute(_route!)`; `_onSave` kiểm tra `_isRevoked \|\| currentUser?.taiKhoanId != widget.user.taiKhoanId` dọn sạch draft và hủy thao tác. | Test Probe #15 PASS; modal phía trên vẫn giữ nguyên, draft bị hủy an toàn. |
| **F03** | **P2 (UX)** | Xoay màn hình (320×740 -> 640×360) làm ô CCCD bị mất focus và bàn phím ảo do `LayoutBuilder` chuyển từ Column sang Row/Expanded hủy `EditableTextState`. | Cố định các `FocusNode` tại `State`. Bổ sung `GlobalKey<FormFieldState<String>>` cho CCCD và Ngày sinh để Flutter reparent element tree khi chuyển đổi bố cục. | Test Probe #16 PASS; focus và `EditableTextState` được bảo toàn 100% qua sự kiện xoay màn hình. |
| **F04** | **P2 (UI Layout)** | Tràn ngang 35px tại `_MenuRow` (trailingText) và tràn 110px tại dialog xác nhận đăng xuất trên màn hình 320dp với 2.0x text scale kế thừa qua overlay route. | `_MenuRow`: `LayoutBuilder` tự động đẩy `trailingText` xuống dòng dưới `subtitle` khi `isTight` (width < 280dp hoặc text scale > 1.25x). Dialog đăng xuất: bọc `Expanded` tiêu đề và dùng `actionsOverflowButtonSpacing: 8`, `actionsOverflowDirection: VerticalDirection.down`. | Test Probe #17 PASS; 0 pixel overflow trên toàn bộ màn hình 320dp với 2.0x text scale. |

## 8. Sửa lỗi route từ re-review — 28/10/2026

Điều phối viên đã sửa nốt P2: khi có modal khác phía trên dialog mật khẩu, đổi tài khoản/đăng xuất trước đây đóng nhầm modal và để lại form rỗng. Dữ liệu mật khẩu đã được xóa trong bản Agent; phần sửa này hoàn thiện điều hướng.

- ChangePasswordDialog ghi nhớ ModalRoute và dùng navigator sở hữu route đó. Nếu dialog đang ở top thì pop; nếu bị modal khác che thì remove chính route dialog.
- Dùng cùng helper cho thu hồi phiên, API success, nút Hủy và guard submit. Giữ owner check, clear controllers, validation, payload, busy và thông báo kết quả hiện có.
- Thêm 3 regression tests trong test/change_password_regression_test.dart: account switch, logout, API success khi có modal khác ở trên. Mỗi test xác minh dialog cũ biến mất, modal phía trên còn nguyên và màn nền vẫn hoạt động sau khi đóng modal.

Kết quả thực chạy sau sửa:

| Gate | Kết quả |
|---|---|
| Focused: change_password_regression + profile_ui_comprehensive | **27/27 PASS** |
| Full suite: flutter test --no-pub --timeout 30s | **492/492 PASS**, 34 giây |
| flutter analyze --no-pub | **No issues found**, 12.9 giây |
| Format profile + hai file test | 11 files / 0 changed |
| git diff --check | Không lỗi whitespace; cảnh báo LF→CRLF |

Logs: mobile-qa-evidence/profile-route-fix-focused.log và profile-route-fix-full.log ở workspace cha.

Đây là kiểm thử widget/AuthBloc với repository fixture, không phải API/Android E2E. Chưa build APK, đổi mật khẩu thật, commit hoặc push trong lượt sửa này. Các con số ở mục 4–7 là snapshot trước lần sửa cuối; mục này là kết quả mới nhất.
