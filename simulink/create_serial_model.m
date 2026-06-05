%% 创建串口接收 + 低通滤波器 Simulink 模型
% 使用 MATLAB System 模块读取串口数据（无需额外工具箱）
% MATLAB R2019b 及以上可用
%
% STM32 数据格式: "gyro_x: raw_val, filtered_val\r\n"
% 波特率: 115200, 采样间隔: 10ms

modelName = 'mpu6050_serial_lpf';
bdclose(modelName);
new_system(modelName);
open_system(modelName);

%% ========== 参数配置（修改这里） ==========
comPort = 'COM3';       % 你的 STM32 串口号
baudRate = 115200;
sampleTime = 0.01;      % 10ms
alpha = 0.04;           % 滤波系数

%% ========== 添加模块 ==========

% 1. MATLAB System - 串口读取 + 解析
sysReader = [modelName '/Serial_Gyro_Reader'];
add_block('simulink/User-Defined Functions/MATLAB System', sysReader);
set_param(sysReader, 'System', 'SerialGyroReader');

% 2. 增益 α
gainA = [modelName '/Alpha'];
add_block('simulink/Math Operations/Gain', gainA);
set_param(gainA, 'Gain', num2str(alpha));

% 3. 增益 1-α
gain1mA = [modelName '/One_Minus_Alpha'];
add_block('simulink/Math Operations/Gain', gain1mA);
set_param(gain1mA, 'Gain', num2str(1 - alpha));

% 4. 加法器
filterSum = [modelName '/Filter_Sum'];
add_block('simulink/Math Operations/Add', filterSum);
set_param(filterSum, 'Inputs', '++');

% 5. Unit Delay
unitDelay = [modelName '/Unit_Delay'];
add_block('simulink/Discrete/Unit Delay', unitDelay);
set_param(unitDelay, 'SampleTime', num2str(sampleTime), ...
    'InitialCondition', '0');

% 6. 示波器 - 3通道
scopeBlock = [modelName '/Scope'];
add_block('simulink/Sinks/Scope', scopeBlock);
set_param(scopeBlock, 'NumInputPorts', '3');

% 7. 数值显示
dispRaw = [modelName '/Display_Raw'];
add_block('simulink/Sinks/Display', dispRaw);
dispFilt = [modelName '/Display_Filtered'];
add_block('simulink/Sinks/Display', dispFilt);

%% ========== 连线 ==========
add_line(modelName, 'Serial_Gyro_Reader/1', 'Scope/1');       % 原始 → 示波器1 (黄)
add_line(modelName, 'Serial_Gyro_Reader/2', 'Scope/3');       % MCU滤波 → 示波器3 (青)
add_line(modelName, 'Serial_Gyro_Reader/1', 'Alpha/1');        % 原始 → 低通滤波

% 滤波通路
add_line(modelName, 'Alpha/1', 'Filter_Sum/1');
add_line(modelName, 'Filter_Sum/1', 'Unit_Delay/1');
add_line(modelName, 'Unit_Delay/1', 'One_Minus_Alpha/1');
add_line(modelName, 'One_Minus_Alpha/1', 'Filter_Sum/2');
add_line(modelName, 'Filter_Sum/1', 'Scope/2');               % 滤波 → 示波器2 (蓝)

% 数值显示
add_line(modelName, 'Serial_Gyro_Reader/1', 'Display_Raw/1');
add_line(modelName, 'Filter_Sum/1', 'Display_Filtered/1');

%% ========== 布局 ==========
Simulink.BlockDiagram.arrangeSystem(modelName);

%% ========== 仿真设置 ==========
set_param(modelName, 'StopTime', 'inf');       % 无限运行
set_param(modelName, 'FixedStep', num2str(sampleTime));

% 保存
save_system(modelName);

fprintf('==============================================\n');
fprintf('✅ 模型 "%s.slx" 已创建！\n', modelName);
fprintf('==============================================\n');
fprintf('\n');
fprintf('🔧 使用步骤：\n');
fprintf('   1. 设备管理器中找到 STM32 的 COM 口\n');
fprintf('   2. 打开 SerialGyroReader.m，修改第8行 COMPort 为你的COM口\n');
fprintf('   3. 运行此脚本：>> create_serial_model\n');
fprintf('   4. STM32 上电运行\n');
fprintf('   5. Simulink 中点 Run 开始实时采集\n');
fprintf('\n');
fprintf('📊 示波器：\n');
fprintf('   黄色 = 原始陀螺仪（含噪声）\n');
fprintf('   蓝色 = Simulink 滤波后 (α=%.2f)\n', alpha);
fprintf('   青色 = MCU 内滤波结果（参考）\n');
fprintf('\n');
fprintf('⏹ 仿真无限运行，手动 Stop 停止\n');
