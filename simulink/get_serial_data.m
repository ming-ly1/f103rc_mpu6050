function [raw, mcu_filtered] = get_serial_data()
    % 从全局变量 serial_buffer 读取最新串口数据
    % 由 MATLAB Function 模块通过 coder.extrinsic 调用
    global serial_buffer
    if isempty(serial_buffer)
        raw = 0;
        mcu_filtered = 0;
    else
        raw = serial_buffer.raw;
        mcu_filtered = serial_buffer.mcu_filtered;
    end
end
