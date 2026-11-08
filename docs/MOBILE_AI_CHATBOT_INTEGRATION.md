# Mobile Trợ lý AI — tích hợp sau re-review, 08/11/2026

Worktree `vexgo_accompanied_luggage_worktree`, branch `feature/mobile-accompanied-luggage`, base8765e1e, giữ các thay đổi local trước đó. Chưa commit/push Mobile. Ba finding UI trước đã được Agent sửa và Codex kiểm chứng lại.

## Đã hoàn tất code

- GET history gửi bearer khi có tài khoản, vẫn cho guest dùng capability UUID. Dùng cơ chế refresh token chung, kiểm tra sessionVersion, không tự POST lại câu chat khi refresh auth.
- Đăng ký AiChatbotRepository tại app, route `/ai-chatbot` trên root navigator; entry tại Trang chủ và Tài khoản. Không thêm tab bottom nav; chat nhà xe `/support-chat` tiếp tục riêng.
- Route nhận companyId dương hoặc không lọc; screen tự đóng Cubit theo lifecycle, xóa phiên khi identity thay đổi. Chuyến gợi ý đọc API xác minh lại và lấy ngày từ lịch mới, chống navigation muộn khi tạo phiên mới.
- Mô tả lịch sử trung lập, hiển thị USER/ASSISTANT, giữ snapshot đọc lại riêng và không tự mở khóa uncertain khi chưa có requestId.

## Kiểm thử đã thực thi

-30/30 test chatbot/navigation qua:19 core,10 UI,1 integration route app thật với repository fixture. Bao gồm guest/owner bearer, refresh401 không đổi identity/không gửi chat lại, entry Trang chủ/Tài khoản, back và company scope.
- Toàn bộ971/971 test Flutter qua; analyze không có vấn đề. Profile test được sửa để scroll tới footer sau khi menu thêm một dòng, vẫn kiểm tra version và logout. Không thay layout chỉ để thỏa assertion cũ.
- Unit/widget/route fixture không phải kiểm thử Android/LLM/MySQL.

## Backend và DB QA

- Checkout Backend QA `vexgo_luggage_backend_worktree` fast-forward local tới0177105 từ nhánh sửa PR69 để kiểm thử; không merge PR GitHub hay sửa develop remote.
- API QA4012 đã có route chatbot nhưng DB QA3313 chưa có bảng AI lúc kiểm tra. Đã xác nhận chỉ thiếu migration `20261106080500_add_ai_chatbot_rag_models`, backup mysqldump vào thư mục private (ACL tài khoản Windows), sau đó migrate deploy.4 bảng AI đã có; số booking/vé/thanh toán trước/sau không đổi. DB chính3306 và DB báo cáo3312 không thao tác.
- Runner `mobile-qa-evidence/luggage-api-20261106/run-qa.mjs` đã build Backend0177105, vẫn4012/3313, tắt SMTP/push/reminders/Cloudinary và GROQ/JINA bên ngoài. Test luồng bằng fallback không chứng minh Groq/Jina thật hoạt động.
- User đã Ctrl+C và chạy lại runner API. Probe UUID sai trả400 đúng bản0177105; native smoke bên dưới đã qua. Không tự khởi động API qua công cụ.

## Đóng gói và native

APK debug build thành công (assembleDebug111s), apksigner verify qua và COPY_LUGGAGE.ps1 -CheckOnly xác nhận hash khớp. Đã cập nhật gói `luggage-preview-20261106/app-debug-accompanied-luggage.apk` mà shortcut **VexGo - Hanh ly moi** sử dụng. SHA-256 `0d1f4a5ae17fc1df7db382ba6e9117a0f0aa64e1c0aed27f2468cf4b385aba9c`. Bản báo cáo dự phòng và launcher đã đối chiếu hash không đổi.

Sau khi user khởi động lại: **native Flutter → API4012/MySQL QA3313 1/1 PASS**. Đã đọc gợi ý, tạo một phiên guest và một phiên owner bằng JWT đăng nhập thật, đọc lại đủ USER/ASSISTANT cho từng phiên; GET phiên owner không JWT nhận403. Query DB xác nhận hai câu hỏi QA thuộc một guest/một owner, mỗi phiên có hai tin; số booking/vé/thanh toán so với trước migration giữ nguyên.

Đây là native repository/API/DB smoke bằng dữ liệu QA, không phải Android UI E2E. Câu hỏi tổng hợp yêu cầu nhân viên đi vào nhánh handoff, không gọi Groq/Jina; token/credential không ghi vào report. Chưa kiểm thử chất lượng trả lời LLM thật, RAG/provider thật hoặc điện thoại; ADB chưa có thiết bị lúc đóng gói. Kết quả tại `native.log`, `native-result.json`, `native-db-result.json` trong evidence.

Evidence ngoài repo: `mobile-qa-evidence/chatbot-integration-20261108/`, gồm log test/analyze/build, backup migration journal, script native và kết quả khi chạy. APK hiện hành/hash thuộc `luggage-preview-20261106/MANIFEST.json`; bản báo cáo dự phòng giữ nguyên.
