function start_serial_stream(comPort)
    % 启动后台串口数据流（在另一个线程中持续读取）
    % 数据存入全局变量 serial_buffer，Simulink 通过 get_serial_data 读取
    %
    % 用法: start_serial_stream('COM3')
    
    if nargin < 1
        comPort = 'COM3';  % ← 改成你的 COM 口
    end
    
    global serial_buffer
    serial_buffer.raw = 0;
    serial_buffer.mcu_filtered = 0;
    
    try
        s = serialport(comPort, 115200);
        configureTerminator(s, "LF");
        disp(['✅ 串口 ' comPort ' 已打开，等待数据...']);
    catch e
        error('串口打开失败: %s', e.message);
    end
    
    % 在后台循环读取（按 Ctrl+C 停止）
    while true
        try
            if s.NumBytesAvailable > 0
                line = readline(s);
                % 格式: "gyro_x: raw_val, filtered_val"
                parts = split(line, {' ', ','});
                if numel(parts) >= 3
                    raw = str2double(parts{2});
                    filt = str2double(parts{3});
                    if ~isnan(raw), serial_buffer.raw = raw; end
                    if ~isnan(filt), serial_buffer.mcu_filtered = filt; end
                end
            end
        catch
            % 错误继续
        end
        pause(0.001);  % 1ms 轮询间隔
    end
end
