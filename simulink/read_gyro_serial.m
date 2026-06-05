function [raw, mcu_filt] = read_gyro_serial()
    % 读取串口陀螺仪数据（独立函数，MATLAB Function 通过 coder.extrinsic 调用）
    persistent s last_raw last_filt
    if isempty(s)
        s = serialport('COM3', 115200);    % ← 改成你的 COM 口
        configureTerminator(s, "LF");
        flush(s);
        last_raw = 0;
        last_filt = 0;
    end
    try
        if s.NumBytesAvailable > 0
            line = readline(s);
            parts = split(line, {' ', ','});
            if numel(parts) >= 3
                raw = str2double(parts{2});
                mcu_filt = str2double(parts{3});
                if ~isnan(raw), last_raw = raw; end
                if ~isnan(mcu_filt), last_filt = mcu_filt; end
            else
                raw = last_raw; mcu_filt = last_filt;
            end
        else
            raw = last_raw; mcu_filt = last_filt;
        end
    catch
        raw = last_raw; mcu_filt = last_filt;
    end
end
