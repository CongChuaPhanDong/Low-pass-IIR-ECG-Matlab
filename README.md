Thiết Kế Bộ Lọc Số IIR Thông Thấp (Low-pass IIR Filter)

Bài tập lớn môn Xử Lý Tín Hiệu Số (XLTHS) tại Học viện Công nghệ Bưu chính Viễn thông - PTIT

📝 Giới thiệu
Bộ lọc IIR (Infinite Impulse Response - Đáp ứng xung vô hạn) là một thành phần cốt lõi trong xử lý tín hiệu số nhờ khả năng đạt được đáp ứng tần số mong muốn với bậc lọc thấp hơn nhiều so với bộ lọc FIR. Dự án này tập trung vào thiết kế và mô phỏng bộ lọc IIR thông thấp ứng dụng trong xử lý nhiễu tín hiệu y sinh (ECG) và âm thanh.
Lý do cần thiết kế
Lọc nhiễu cao tần: Loại bỏ nhiễu cơ (EMG) và nhiễu điện lưới (50Hz/60Hz) khỏi tín hiệu ECG.

Tối ưu tài nguyên: Đạt được độ dốc cắt lớn với bậc lọc thấp, phù hợp cho các hệ thống nhúng/thời gian thực.

Ứng dụng thực tế: Xử lý âm thanh, tách nhạc nền, và phân tích tín hiệu y sinh.

🎯 Mục tiêu đề tài
Tìm hiểu lý thuyết về xấp xỉ bộ lọc tương tự và biến đổi song tuyến (Bilinear Transformation).

Thiết kế và so sánh 3 loại bộ lọc IIR kinh điển:

Butterworth: Đáp ứng biên độ phẳng tuyệt đối trong dải thông.

Chebyshev Loại I: Độ dốc cắt nhanh, có gợn sóng (ripple) trong dải thông.

Chebyshev Loại II: Có gợn sóng trong dải chặn, dải thông phẳng.

Triển khai thuật toán lọc không lệch pha (Zero-phase filtering) bằng hàm filtfilt trên MATLAB.

🛠 Công nghệ & Công cụ
Ngôn ngữ: MATLAB R202x

Toolbox: Signal Processing Toolbox

Các hàm chính: butter, cheby1, cheby2, buttord, freqz, filtfilt, zplane.

⚙️ Nội dung thực hiện
I. Cơ sở lý thuyết
II. Thiết kế bộ lọc
III. Mô phỏng matlab
IV. Ứng dụng thực tế 
Nhận xét tổng quan
Ưu điểm:

Hiệu quả tính toán cao (tốn ít bộ nhớ và CPU hơn FIR cho cùng một độ dốc cắt).

Khả năng lọc nhiễu cao tần (nhiễu 50Hz, nhiễu cơ) cực kỳ sạch sẽ.

Phù hợp cho xử lý tín hiệu y sinh yêu cầu thời gian thực.

Nhược điểm:

Đáp ứng pha không tuyến tính (có thể khắc phục bằng lọc filtfilt).

Có nguy cơ không ổn định nếu các cực nằm ngoài vòng tròn đơn vị.
