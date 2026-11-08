# Core Mobile AI Chatbot — 08/11/2026

Đã triển khai trên `vexgo_accompanied_luggage_worktree`, nhánh `feature/mobile-accompanied-luggage`. Chưa commit/push. Sau re-review UI, Codex đã nối provider/route `/ai-chatbot`, entry tại Trang chủ/Tài khoản và JWT đọc lịch sử. Các kết quả phía dưới là lịch sử giai đoạn core; xem `MOBILE_AI_CHATBOT_INTEGRATION.md` cho snapshot tích hợp mới nhất.

## Nội dung

- DTO immutable parse dữ liệu response/history/citation/trip/suggestion đúng Backend ec75064, phân biệt history và send response; kiểm tra số nguyên, ngày/giờ, token UUID, trường bắt buộc.
- Repository dùng ApiClient chung, envelope data, optional bearer cho POST, version guard và không gửi secret LLM. Giới hạn UX 2000 ký tự, không auto retry.
- Cubit single-flight, bản nháp, câu hỏi gợi ý, handoff flag và read-only history. Guest có thể gửi; thay đổi identity/nhà xe, hội thoại mới hoặc close đều vô hiệu phản hồi cũ. Logout/login xóa nội dung, draft và token trong bộ nhớ.
- Token không persist qua đóng app; HTTP debug sanitizer hiện có che token UUID trong path history. Không truy cập endpoint Admin, không thực thi mutation từ AI, không mở bookingUrl do server gửi.
- Timeout, response lỗi định dạng hoặc 5xx đánh dấu uncertain, giữ draft, chặn gửi lại. 4xx xác định như400/429 cho thử lại thủ công, không hiển thị raw server message. Khi đang gửi, sửa draft được và ACK giữ draft mới.
- Backend chỉ lưu ASSISTANT, không có USER/requestId; đọc history không thể chứng minh POST nào đã được xử lý. Core giữ local exchanges và historySnapshot riêng, không tự unlock uncertain hoặc giả khôi phục đủ lịch sử.

## Files

- `lib/data/models/ai_chatbot_model.dart`
- `lib/data/repositories/ai_chatbot_repository.dart`
- `lib/features/user/ai_chatbot/ai_chatbot_cubit.dart`
- `test/ai_chatbot_core_test.dart`

Handoff UI và API/migration/prerequisite: `MOBILE_AI_CHATBOT_INTEGRATION_HANDOFF.md`.

## Kiểm thử và phạm vi

17 test core/HTTP fixture: shape đúng/sai, payload guest/auth/tenant, validation trước HTTP, suggestions/history/404, token mismatch, đổi identity giữa request, double tap, draft chỉnh khi gửi, timeout/500/malformed/429, readback không unlock uncertain, logout/login/tenant/new/close, lỗi suggestions và che token trong log.

Lượt chạy rộng đầu: 957 qua, 1 fail ở `feature_errors_regression_test.dart` cũ vì assertion đòi raw `lookup offline`; production code hiện bảo vệ bằng thông báo an toàn và reviewStatus.uncertain. Đã cập nhật riêng assertion để kiểm tra uncertain, có lỗi hiển thị và không lộ raw error. Không sửa production review flow để làm xanh test.

Kết quả cuối: **958/958 test toàn bộ thư mục test qua**, gồm 17 test chatbot; `flutter analyze --no-pub` không có vấn đề (10.2s), `git diff --check` không có lỗi whitespace. Lượt 486 test trước thuộc nhóm hồi quy chọn lọc; lượt này chạy toàn bộ thư mục test. Log: `mobile-regression-final.log`, `mobile-analyze-final.log` tại `mobile-qa-evidence/chatbot-prep-20261108/`; giữ log lượt đầu để đối chiếu assertion cũ.

Unit/fixture không phải E2E. Chưa migrate/restart Backend, chưa gọi Groq/Jina, chưa build APK UI chatbot hoặc kiểm thử máy thật trong lượt này. Không tuyên bố chatbot đã dùng được trên APK hiện hành.
