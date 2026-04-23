%% ================================================================
%  LỌC TÍN HIỆU ECG – BỘ LỌC IIR THÔNG THẤP BUTTERWORTH
%  ECG Signal Filtering using Butterworth Low-pass IIR Filter
%  *** Phiên bản tương thích Command Window / MATLAB Online ***
%% ================================================================
clc; clear; close all;

%% ---------------------------------------------------------------
%  HÀM PHỤ TRỢ – định nghĩa anonymous function ĐẦU TIÊN
%  (phải đặt trước khi dùng, tránh lỗi "Unrecognized function")
%% ---------------------------------------------------------------
gauss_pulse = @(t, t0, sigma) exp(-0.5 * ((t - t0) / sigma).^2);

%% ---------------------------------------------------------------
%  BƯỚC 1: CHỌN NGUỒN TÍN HIỆU ECG
%% ---------------------------------------------------------------
choice = questdlg( ...
    'Bạn muốn dùng tín hiệu ECG nào?', ...
    'Nguồn tín hiệu ECG', ...
    '📂 Tải file ECG (.mat/.csv/.txt)', ...
    '🔬 Tạo ECG mô phỏng (có nhiễu)', ...
    '🔬 Tạo ECG mô phỏng (có nhiễu)');

ecg_raw    = [];
fs_default = '360';

if strcmp(choice, '📂 Tải file ECG (.mat/.csv/.txt)')
    [fname, fpath] = uigetfile( ...
        {'*.mat','MAT file'; '*.csv','CSV file'; '*.txt','Text file'}, ...
        'Chọn file ECG');
    if isequal(fname, 0)
        disp('Không chọn file. Thoát.'); return;
    end
    fullpath  = fullfile(fpath, fname);
    [~, ~, ext] = fileparts(fname);

    if strcmpi(ext, '.mat')
        S      = load(fullpath);
        fields = fieldnames(S);
        for i = 1:numel(fields)
            v = S.(fields{i});
            if isnumeric(v) && numel(v) > 10
                ecg_raw = double(v(:));
                break;
            end
        end
        if isempty(ecg_raw)
            errordlg('Không tìm thấy dữ liệu số trong file .mat!', 'Lỗi');
            return;
        end

    elseif strcmpi(ext, '.csv') || strcmpi(ext, '.txt')
        try
            raw = readmatrix(fullpath);
            if size(raw, 2) > 1
                ecg_raw = double(raw(:, end));
            else
                ecg_raw = double(raw(:));
            end
        catch
            errordlg('Không đọc được file. Kiểm tra định dạng!', 'Lỗi');
            return;
        end
    end
    fprintf('Đã tải file: %s  (%d mẫu)\n', fname, length(ecg_raw));
else
    ecg_raw = [];   % sẽ tạo bên dưới sau khi biết fs
end

%% ---------------------------------------------------------------
%  BƯỚC 2: NHẬP THÔNG SỐ BỘ LỌC
%% ---------------------------------------------------------------
prompt = {
    'Tần số lấy mẫu  fs  (Hz):', ...
    'Tần số cắt passband  fp  (Hz):', ...
    'Tần số cắt stopband  fst (Hz):', ...
    'Độ gợn passband  Rp  (dB):', ...
    'Suy hao stopband Rs  (dB):'
};
dlgtitle = 'Thông số bộ lọc Butterworth – ECG';
defaults = {fs_default, '40', '60', '3', '40'};
dims     = [1 48; 1 48; 1 48; 1 48; 1 48];

answer = inputdlg(prompt, dlgtitle, dims, defaults);
if isempty(answer)
    disp('Đã hủy.'); return;
end

fs      = str2double(answer{1});
fp      = str2double(answer{2});
fs_stop = str2double(answer{3});
Rp      = str2double(answer{4});
Rs      = str2double(answer{5});

if any(isnan([fs fp fs_stop Rp Rs]))
    errordlg('Vui lòng nhập số hợp lệ!', 'Lỗi'); return;
end
if fp <= 0 || fs_stop <= fp || fs_stop >= fs/2
    errordlg(sprintf('Yêu cầu: 0 < fp < fst < fs/2 (= %.1f Hz)', fs/2), 'Lỗi tần số');
    return;
end
if Rp <= 0 || Rs <= Rp
    errordlg('Yêu cầu: 0 < Rp < Rs', 'Lỗi dB'); return;
end

%% ---------------------------------------------------------------
%  BƯỚC 3: TẠO ECG MÔ PHỎNG (nếu không tải file)
%  --- Code được inline trực tiếp vào script ---
%% ---------------------------------------------------------------
if isempty(ecg_raw)
    fprintf('Tạo tín hiệu ECG mô phỏng...\n');

    duration    = 10;           % giây
    hr          = 72;           % nhịp tim (BPM)
    t_gen       = 0 : 1/fs : duration - 1/fs;
    N_gen       = length(t_gen);
    rr          = 60 / hr;      % chu kỳ RR (s)
    ecg_raw_gen = zeros(1, N_gen);
    beat_times  = rr/2 : rr : duration;

    for bt = beat_times
        ecg_raw_gen = ecg_raw_gen + 0.15 * gauss_pulse(t_gen, bt - 0.20*rr, 0.025); % P
        ecg_raw_gen = ecg_raw_gen - 0.10 * gauss_pulse(t_gen, bt - 0.03,    0.010); % Q
        ecg_raw_gen = ecg_raw_gen + 1.20 * gauss_pulse(t_gen, bt,            0.010); % R
        ecg_raw_gen = ecg_raw_gen - 0.25 * gauss_pulse(t_gen, bt + 0.03,    0.012); % S
        ecg_raw_gen = ecg_raw_gen + 0.35 * gauss_pulse(t_gen, bt + 0.20*rr, 0.040); % T
    end

    noise_hf  = 0.05 * randn(1, N_gen);          % nhiễu điện cơ (EMG)
    noise_pl  = 0.08 * sin(2*pi*50*t_gen);        % nhiễu điện lưới 50 Hz
    noise_bw  = 0.06 * sin(2*pi*0.3*t_gen);       % baseline wander

    ecg_raw = (ecg_raw_gen + noise_hf + noise_pl + noise_bw)';
end

%% ---------------------------------------------------------------
%  BƯỚC 4: THIẾT KẾ BỘ LỌC BUTTERWORTH
%% ---------------------------------------------------------------
ecg_raw = ecg_raw(:);
N_sig   = length(ecg_raw);
t       = (0:N_sig-1) / fs;

Wp = fp      / (fs/2);
Ws = fs_stop / (fs/2);

[N_ord, Wn] = buttord(Wp, Ws, Rp, Rs);
[b, a]      = butter(N_ord, Wn, 'low');

[~, p, ~]   = tf2zpk(b, a);
stable_flag = all(abs(p) < 1);

fprintf('\n===== THÔNG SỐ BỘ LỌC =====\n');
fprintf('Bậc lọc N         : %d\n',   N_ord);
fprintf('Tần số cắt Wn     : %.4f (%.2f Hz)\n', Wn, Wn*(fs/2));
if stable_flag
    fprintf('Ổn định           : Có\n');
else
    fprintf('Ổn định           : KHÔNG\n');
end

%% ---------------------------------------------------------------
%  BƯỚC 5: ÁP DỤNG BỘ LỌC
%  filtfilt → lọc 2 chiều, không lệch pha
%% ---------------------------------------------------------------
ecg_filtered = filtfilt(b, a, ecg_raw);

%% ---------------------------------------------------------------
%  BƯỚC 6: VẼ ĐỒ THỊ KẾT QUẢ
%% ---------------------------------------------------------------

% ---- Figure 1: Tín hiệu ECG trước & sau lọc -------------------
figure('Name','ECG – Trước và Sau Lọc', ...
    'NumberTitle','off','Color','white','Position',[40 60 1280 700]);

n_disp = min(N_sig, round(5*fs));
t_disp = t(1:n_disp);

subplot(3,1,1);
plot(t_disp, ecg_raw(1:n_disp), 'Color',[0.4 0.4 0.8], 'LineWidth',1);
ylabel('Biên độ (mV)'); title('Tín hiệu ECG gốc (có nhiễu)');
grid on; xlim([t_disp(1) t_disp(end)]);

subplot(3,1,2);
plot(t_disp, ecg_filtered(1:n_disp), 'Color',[0.1 0.7 0.4], 'LineWidth',1.2);
ylabel('Biên độ (mV)');
title(sprintf('ECG sau lọc Butterworth (N=%d, fp=%.0f Hz)', N_ord, fp));
grid on; xlim([t_disp(1) t_disp(end)]);

subplot(3,1,3);
noise_removed = ecg_raw(1:n_disp) - ecg_filtered(1:n_disp);
plot(t_disp, noise_removed, 'Color',[0.85 0.3 0.3], 'LineWidth',0.8);
xlabel('Thời gian (s)'); ylabel('Biên độ');
title('Nhiễu đã loại bỏ (= gốc – sau lọc)');
grid on; xlim([t_disp(1) t_disp(end)]);

sgtitle(sprintf('Lọc ECG – Butterworth Thông Thấp  |  fs=%.0f Hz  |  fp=%.0f Hz  |  N=%d', ...
    fs, fp, N_ord), 'FontSize',13, 'FontWeight','bold');

% ---- Figure 2: Phân tích tần số --------------------------------
figure('Name','ECG – Phân tích tần số & Bộ lọc', ...
    'NumberTitle','off','Color','white','Position',[60 60 1280 780]);

NFFT   = 2^nextpow2(N_sig);
f_axis = (0:NFFT/2) * fs / NFFT;
X_raw  = abs(fft(ecg_raw,      NFFT)) / N_sig * 2;
X_filt = abs(fft(ecg_filtered, NFFT)) / N_sig * 2;

subplot(2,3,1);
plot(f_axis, X_raw(1:NFFT/2+1), 'Color',[0.4 0.4 0.8], 'LineWidth',1.2);
hold on;
xline(fp,      '--r', 'LineWidth',1.3, 'Label',sprintf('fp=%.0f',fp));
xline(fs_stop, '--m', 'LineWidth',1.3, 'Label',sprintf('fst=%.0f',fs_stop));
grid on; xlim([0 min(fs/2, 250)]);
xlabel('Tần số (Hz)'); ylabel('Biên độ'); title('Phổ ECG gốc |X(f)|');

subplot(2,3,2);
plot(f_axis, X_filt(1:NFFT/2+1), 'Color',[0.1 0.7 0.4], 'LineWidth',1.2);
hold on;
xline(fp,      '--r', 'LineWidth',1.3);
xline(fs_stop, '--m', 'LineWidth',1.3);
grid on; xlim([0 min(fs/2, 250)]);
xlabel('Tần số (Hz)'); ylabel('Biên độ'); title('Phổ ECG sau lọc |Y(f)|');

[H, f_H] = freqz(b, a, 2048, fs);
H_dB     = 20*log10(abs(H) + eps);

subplot(2,3,3);
plot(f_H, H_dB, 'b-', 'LineWidth',2); hold on;
xline(fp,      '--r', 'LineWidth',1.5, 'Label',sprintf('fp=%.0fHz',fp));
xline(fs_stop, '--m', 'LineWidth',1.5, 'Label',sprintf('fst=%.0fHz',fs_stop));
yline(-Rp, ':g', 'LineWidth',1.2);
yline(-Rs, ':k', 'LineWidth',1.2);
xlim([0 fs/2]); ylim([-Rs*1.5 5]);
grid on; xlabel('Tần số (Hz)'); ylabel('Biên độ (dB)');
title(sprintf('Đáp ứng biên độ bộ lọc (N=%d)', N_ord));
legend('|H(f)|', 'fp', 'fst', 'Location','SW');

subplot(2,3,4);
zplane(b, a); title('Sơ đồ cực và không điểm'); grid on;

subplot(2,3,5);
plot(f_H, angle(H)*180/pi, 'r-', 'LineWidth',1.8);
grid on; xlim([0 fs/2]);
xlabel('Tần số (Hz)'); ylabel('Pha (độ)'); title('Đáp ứng pha bộ lọc');

subplot(2,3,6);
[pxx_raw,  f_psd] = pwelch(ecg_raw,      [], [], [], fs);
[pxx_filt, ~    ] = pwelch(ecg_filtered, [], [], [], fs);
semilogy(f_psd, pxx_raw,  'Color',[0.4 0.4 0.8], 'LineWidth',1.3); hold on;
semilogy(f_psd, pxx_filt, 'Color',[0.1 0.7 0.4], 'LineWidth',1.3);
xline(fp,      '--r', 'LineWidth',1.2);
xline(fs_stop, '--m', 'LineWidth',1.2);
grid on; xlim([0 min(fs/2, 250)]);
xlabel('Tần số (Hz)'); ylabel('PSD (V²/Hz)');
title('Mật độ phổ công suất (PSD)');
legend('ECG gốc','ECG sau lọc','fp','fst','Location','NE');

sgtitle(sprintf('Phân tích tần số – Butterworth Thông Thấp  |  N=%d  |  fp=%.0f Hz', ...
    N_ord, fp), 'FontSize',12, 'FontWeight','bold');

%% ---------------------------------------------------------------
%  BƯỚC 7: IN THỐNG KÊ SO SÁNH
%% ---------------------------------------------------------------
snr_in  = snr(ecg_raw);
snr_out = snr(ecg_filtered);

fprintf('\n===== THỐNG KÊ =====\n');
fprintf('Số mẫu tín hiệu   : %d\n',     N_sig);
fprintf('Thời lượng        : %.2f s\n',  N_sig/fs);
fprintf('SNR đầu vào       : %.2f dB\n', snr_in);
fprintf('SNR sau lọc       : %.2f dB\n', snr_out);
fprintf('Cải thiện SNR     : %.2f dB\n', snr_out - snr_in);
fprintf('\nHoàn thành!\n');
