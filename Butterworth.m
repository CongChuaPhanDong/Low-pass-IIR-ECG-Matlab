%% ================================================================
%  THIẾT KẾ BỘ LỌC SỐ IIR THÔNG THẤP - BUTTERWORTH
%  Low-pass IIR Digital Filter Design using Butterworth Method
%% ================================================================
clc; clear; close all;

%% ---------------------------------------------------------------
%  1. NHẬP THÔNG SỐ TỪ NGƯỜI DÙNG (User Input via Dialog)
%% ---------------------------------------------------------------
prompt = {
    'Tần số lấy mẫu  fs  (Hz):', ...
    'Tần số passband  fp  (Hz):', ...
    'Tần số stopband  fst (Hz):', ...
    'Độ gợn passband  Rp  (dB):', ...
    'Suy hao stopband Rs  (dB):'
};
dlgtitle = 'Thông số bộ lọc Butterworth IIR';
defaults = {'1000','150','300','3','40'};
dims     = [1 45; 1 45; 1 45; 1 45; 1 45];

answer = inputdlg(prompt, dlgtitle, dims, defaults);

% Người dùng bấm Cancel → thoát
if isempty(answer)
    disp('Đã hủy. Chương trình kết thúc.');
    return;
end

% Chuyển sang số
fs      = str2double(answer{1});
fp      = str2double(answer{2});
fs_stop = str2double(answer{3});
Rp      = str2double(answer{4});
Rs      = str2double(answer{5});

% Kiểm tra hợp lệ
if any(isnan([fs fp fs_stop Rp Rs]))
    errordlg('Vui lòng nhập số hợp lệ!', 'Lỗi nhập liệu'); return;
end
if fp <= 0 || fs_stop <= fp || fs_stop >= fs/2
    errordlg(sprintf('Yêu cầu: 0 < fp < fst < fs/2 (= %.1f Hz)', fs/2), 'Lỗi tần số'); return;
end
if Rp <= 0 || Rs <= Rp
    errordlg('Yêu cầu: 0 < Rp < Rs', 'Lỗi thông số dB'); return;
end

% Chuẩn hóa tần số (0 < Wn < 1, với 1 = fs/2)
Wp = fp      / (fs/2);
Ws = fs_stop / (fs/2);

fprintf('===== THÔNG SỐ BỘ LỌC =====\n');
fprintf('Tần số lấy mẫu   : %.1f Hz\n', fs);
fprintf('Tần số passband   : %.1f Hz  (Wp = %.4f)\n', fp, Wp);
fprintf('Tần số stopband   : %.1f Hz  (Ws = %.4f)\n', fs_stop, Ws);
fprintf('Độ gợn passband   : %.1f dB\n', Rp);
fprintf('Suy hao stopband  : %.1f dB\n', Rs);

%% ---------------------------------------------------------------
%  2. XÁC ĐỊNH BẬC LỌC TỐI THIỂU (Filter Order Estimation)
%% ---------------------------------------------------------------
[N, Wn] = buttord(Wp, Ws, Rp, Rs);

fprintf('\n===== KẾT QUẢ THIẾT KẾ =====\n');
fprintf('Bậc lọc tối thiểu : N = %d\n', N);
fprintf('Tần số cắt chuẩn  : Wn = %.4f (%.2f Hz)\n', Wn, Wn*(fs/2));

%% ---------------------------------------------------------------
%  3. TÍNH HỆ SỐ BỘ LỌC (Filter Coefficients)
%% ---------------------------------------------------------------
% Phương pháp: biến đổi song tuyến (bilinear transformation)
[b, a] = butter(N, Wn, 'low');

fprintf('\n===== HỆ SỐ BỘ LỌC =====\n');
fprintf('Tử số b = [');
fprintf(' %.6f', b); fprintf(' ]\n');
fprintf('Mẫu số a = [');
fprintf(' %.6f', a); fprintf(' ]\n');

%% ---------------------------------------------------------------
%  4. ĐÁP ỨNG TẦN SỐ (Frequency Response)
%% ---------------------------------------------------------------
[H, f] = freqz(b, a, 1024, fs);
H_dB   = 20*log10(abs(H));
H_phase = angle(H) * 180/pi;   % Pha (độ)

%% ---------------------------------------------------------------
%  5. KIỂM TRA CỰC VÀ KHÔNG ĐIỂM (Poles & Zeros)
%% ---------------------------------------------------------------
[z, p, k] = tf2zpk(b, a);

fprintf('\n===== CỰC VÀ KHÔNG ĐIỂM =====\n');
fprintf('Hệ số khuếch đại k = %.6f\n', k);
fprintf('Không điểm (zeros):\n'); disp(z);
fprintf('Cực (poles):\n');        disp(p);

% Kiểm tra tính ổn định
if all(abs(p) < 1)
    fprintf('=> Bộ lọc ỔN ĐỊNH (tất cả cực nằm trong đơn vị vòng tròn)\n');
else
    fprintf('=> CẢNH BÁO: Bộ lọc KHÔNG ổn định!\n');
end

%% ---------------------------------------------------------------
%  6. VẼ ĐỒ THỊ (Visualization)
%% ---------------------------------------------------------------
figure('Name','Bộ lọc IIR Butterworth Thông Thấp', ...
       'NumberTitle','off', 'Color','white', 'Position',[50 50 1200 800]);

%-- 6.1  Biên độ (Magnitude Response) --------------------------
subplot(2,3,1);
plot(f, H_dB, 'b-', 'LineWidth', 2); hold on;
xline(fp,      '--r', 'LineWidth',1.5, 'Label','f_p');
xline(fs_stop, '--m', 'LineWidth',1.5, 'Label','f_s');
yline(-Rp, ':g', 'LineWidth',1.5);
yline(-Rs,  ':k', 'LineWidth',1.5);
xlim([0 fs/2]); ylim([-80 5]);
grid on; xlabel('Tần số (Hz)'); ylabel('Biên độ (dB)');
title(sprintf('Đáp ứng biên độ (N=%d)', N));
legend('|H(f)|','Passband edge','Stopband edge','Location','SW');

%-- 6.2  Biên độ tuyến tính ------------------------------------
subplot(2,3,2);
plot(f, abs(H), 'b-', 'LineWidth', 2); hold on;
xline(fp,      '--r', 'LineWidth',1.5);
xline(fs_stop, '--m', 'LineWidth',1.5);
grid on; xlabel('Tần số (Hz)'); ylabel('Biên độ tuyến tính');
title('Đáp ứng biên độ (tuyến tính)');
xlim([0 fs/2]);

%-- 6.3  Đáp ứng pha --------------------------------------------
subplot(2,3,3);
plot(f, H_phase, 'r-', 'LineWidth', 2);
grid on; xlabel('Tần số (Hz)'); ylabel('Pha (độ)');
title('Đáp ứng pha'); xlim([0 fs/2]);

%-- 6.4  Sơ đồ cực - không điểm (Pole-Zero Plot) ---------------
subplot(2,3,4);
zplane(b, a);
title('Sơ đồ cực và không điểm');
grid on;

%-- 6.5  Đáp ứng xung (Impulse Response) -----------------------
subplot(2,3,5);
impz(b, a, 100);
title('Đáp ứng xung h[n]');
grid on;

%-- 6.6  Đáp ứng bước (Step Response) --------------------------
subplot(2,3,6);
[h_step, t_step] = stepz(b, a, 200);
stem(t_step, h_step, 'filled', 'MarkerSize', 3);
grid on; xlabel('Mẫu n'); ylabel('Biên độ');
title('Đáp ứng bước s[n]');

sgtitle(sprintf('Bộ lọc IIR Thông Thấp Butterworth  |  N = %d  |  fs = %d Hz  |  fp = %d Hz', ...
    N, fs, fp), 'FontSize', 13, 'FontWeight','bold');

%% ---------------------------------------------------------------
%  7. MÔ PHỎNG LỌC TÍN HIỆU (Signal Filtering Demo)
%% ---------------------------------------------------------------
% Tự động chọn f1 (trong dải thông) và f2 (ngoài dải chặn)
f1 = round(fp * 0.5);              % Thành phần nằm TRONG dải thông
f2 = min(round(fs_stop * 1.5), floor(fs/2) - 10);  % Thành phần nằm NGOÀI dải chặn

t  = 0 : 1/fs : 1 - 1/fs;
x  = sin(2*pi*f1*t) + sin(2*pi*f2*t) + 0.3*randn(size(t));

% Lọc tín hiệu
y = filter(b, a, x);

% Số mẫu hiển thị miền thời gian (tối đa 400 mẫu)
n_show = min(400, length(t));

figure('Name','Mô phỏng lọc tín hiệu','NumberTitle','off', ...
       'Color','white','Position',[50 50 1200 600]);

%-- Miền thời gian -----------------------------------------------
subplot(2,2,1);
plot(t(1:n_show), x(1:n_show), 'b'); grid on;
xlabel('Thời gian (s)'); ylabel('Biên độ');
title(sprintf('Tín hiệu đầu vào x[n]  (%d Hz + %d Hz + noise)', f1, f2));

subplot(2,2,2);
plot(t(1:n_show), y(1:n_show), 'r'); grid on;
xlabel('Thời gian (s)'); ylabel('Biên độ');
title(sprintf('Tín hiệu đầu ra y[n]  (sau lọc, giữ lại %d Hz)', f1));

%-- Miền tần số (FFT) -------------------------------------------
N_fft  = length(x);
X_fft  = abs(fft(x)) / N_fft * 2;
Y_fft  = abs(fft(y)) / N_fft * 2;
f_axis = (0:N_fft/2) * fs / N_fft;

subplot(2,2,3);
plot(f_axis, X_fft(1:N_fft/2+1), 'b'); grid on;
xlabel('Tần số (Hz)'); ylabel('Biên độ');
title('Phổ tần số đầu vào |X(f)|'); xlim([0 fs/2]);

subplot(2,2,4);
plot(f_axis, Y_fft(1:N_fft/2+1), 'r'); grid on;
xlabel('Tần số (Hz)'); ylabel('Biên độ');
title('Phổ tần số đầu ra |Y(f)|'); xlim([0 fs/2]);

sgtitle(sprintf('Mô phỏng lọc tín hiệu - Butterworth Low-pass IIR  |  fp = %.1f Hz', fp), ...
    'FontSize',13,'FontWeight','bold');

fprintf('\nHoàn thành! Kết quả được hiển thị trên đồ thị.\n');
