%% 将现有模型中的串口模块改为全局变量读取方式
% 用法：
%   1. MATLAB 运行: >> start_serial_stream('COM3')
%   2. 运行本脚本:  >> add_serial_to_model
%   3. Simulink 点 Run

modelName = 'mpu6050_lowpass_filter';

%% 1. 先恢复信号源连接（删除串口模块及相关连线，恢复原始信号源）
% 关闭并重新加载，清空未保存的修改
bdclose(modelName);
load_system(modelName);

% 先找出并删除所有与串口模块相关的连线
blockNames = {'Serial_Gyro_Reader', 'Serial_Receive', 'Serial Read'};
for i = 1:length(blockNames)
    blk = [modelName '/' blockNames{i}];
    try
        % 获取该模块所有端口的连线并删除
        ports = get_param(blk, 'PortHandles');
        for j = 1:length(ports.Outport)
            line = get_param(ports.Outport(j), 'Line');
            if line ~= -1
                delete_line(line);
            end
        end
        for j = 1:length(ports.Inport)
            line = get_param(ports.Inport(j), 'Line');
            if line ~= -1
                delete_line(line);
            end
        end
        delete_block(blk);
    catch
    end
end

% 检查信号源模块是否存在，如果不存在就添加
try
    get_param([modelName '/Useful_Signal_2Hz'], 'Type');
catch
    % 信号源被删了，重新添加
    src1 = [modelName '/Useful_Signal_2Hz'];
    add_block('simulink/Sources/Sine Wave', src1);
    set_param(src1, 'Amplitude', '10', 'Bias', '0', ...
        'Frequency', '2*pi*2', 'SampleTime', '0.01');
    noiseSrc = [modelName '/HighFreq_Noise_50Hz'];
    add_block('simulink/Sources/Sine Wave', noiseSrc);
    set_param(noiseSrc, 'Amplitude', '3', 'Bias', '0', ...
        'Frequency', '2*pi*50', 'SampleTime', '0.01');
    adder1 = [modelName '/Add_Noise'];
    add_block('simulink/Math Operations/Add', adder1);
    set_param(adder1, 'Inputs', '++');
    add_line(modelName, 'Useful_Signal_2Hz/1', 'Add_Noise/1');
    add_line(modelName, 'HighFreq_Noise_50Hz/1', 'Add_Noise/2');
end

%% 2. 添加 MATLAB Function 模块
fnBlock = [modelName '/Serial_Gyro_Reader'];
add_block('simulink/User-Defined Functions/MATLAB Function', fnBlock);

% MATLAB Function 代码
fnCode = sprintf([
    'function [raw, mcu_filt] = fcn()\n' ...
    '%%#codegen\n' ...
    '    coder.extrinsic(''get_serial_data'');\n' ...
    '    persistent last_raw last_filt\n' ...
    '    if isempty(last_raw)\n' ...
    '        last_raw = 0;\n' ...
    '        last_filt = 0;\n' ...
    '    end\n' ...
    '    try\n' ...
    '        [r, m] = get_serial_data();\n' ...
    '        if ~isnan(r) && ~isnan(m)\n' ...
    '            last_raw = r;\n' ...
    '            last_filt = m;\n' ...
    '        end\n' ...
    '    catch\n' ...
    '    end\n' ...
    '    raw = last_raw;\n' ...
    '    mcu_filt = last_filt;\n' ...
    'end\n']);

try
    sf = get_param(fnBlock, 'MATLABFunctionConfiguration');
    sf.Script = fnCode;
catch
    % 创建备用文本文件
    fid = fopen('serial_fn_code.m', 'w');
    fprintf(fid, '%s', fnCode);
    fclose(fid);
    disp('⚠️ 请手动打开 MATLAB Function 模块，粘贴 serial_fn_code.m 中的代码');
end

%% 3. 重新连线
% 删除旧连线
try, delete_line(modelName, 'Add_Noise/1', 'Scope/1'); catch, end
try, delete_line(modelName, 'Add_Noise/1', 'Alpha_0.02/1'); catch, end

% 连接串口 → 滤波 + 示波器
add_line(modelName, 'Serial_Gyro_Reader/1', 'Alpha_0.02/1');
add_line(modelName, 'Serial_Gyro_Reader/1', 'Scope/1');

% 第3通道显示 MCU 滤波
try
    set_param([modelName '/Scope'], 'NumInputPorts', '3');
    add_line(modelName, 'Serial_Gyro_Reader/2', 'Scope/3');
catch
end

%% 4. 仿真参数
set_param(modelName, 'StopTime', 'inf');
set_param(modelName, 'FixedStep', '0.01');
try, set_param([modelName '/Unit_Delay'], 'SampleTime', '0.01'); catch, end

save_system(modelName);

fprintf('============================================\n');
fprintf('✅ 模型 "%s.slx" 已更新！\n', modelName);
fprintf('============================================\n');
fprintf('\n');
fprintf('📌 使用步骤：\n');
fprintf('\n');
fprintf('  第1步：启动串口后台读取\n');
fprintf('    >> start_serial_stream(''COM3'')\n');
fprintf('    （COM3 改成你的实际串口号）\n');
fprintf('\n');
fprintf('  第2步：点 Simulink 的 Run 按钮\n');
fprintf('   停止后台读取：按 Ctrl+C\n');
fprintf('\n');
fprintf('📊 示波器：\n');
fprintf('  黄色 = 原始陀螺仪数据\n');
fprintf('  蓝色 = Simulink 低通滤波\n');
fprintf('  青色 = MCU 内滤波（参考）\n');
fprintf('\n');
