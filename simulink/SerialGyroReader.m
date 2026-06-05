classdef SerialGyroReader < matlab.System
    % 串口读取 MPU6050 陀螺仪数据
    % STM32 数据格式: "gyro_x: raw_val, filtered_val\r\n"
    %
    % 如果串口号不是 COM3，请修改下方 COMPort 的默认值
    
    properties (Nontunable)
        COMPort = 'COM3';       % ← 修改这里
        BaudRate = 115200;      % ← 修改这里
    end
    
    properties (Access = private)
        SerialObj
        LastRaw = 0
        LastFiltered = 0
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            obj.SerialObj = serialport(obj.COMPort, obj.BaudRate);
            configureTerminator(obj.SerialObj, "LF");
            flush(obj.SerialObj);
            obj.LastRaw = 0;
            obj.LastFiltered = 0;
        end
        
        function [raw, mcu_filtered] = stepImpl(obj)
            try
                if obj.SerialObj.NumBytesAvailable > 0
                    line = readline(obj.SerialObj);
                    % "gyro_x:  raw_val, filtered_val"
                    parts = split(line, {' ', ','});
                    if numel(parts) >= 3
                        raw = str2double(parts{2});
                        mcu_filtered = str2double(parts{3});
                        if ~isnan(raw), obj.LastRaw = raw; end
                        if ~isnan(mcu_filtered), obj.LastFiltered = mcu_filtered; end
                    end
                end
            catch
            end
            raw = obj.LastRaw;
            mcu_filtered = obj.LastFiltered;
        end
        
        function releaseImpl(obj)
            delete(obj.SerialObj);
        end
    end
end
