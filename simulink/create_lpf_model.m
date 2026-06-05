%% 创建一阶低通滤波器 Simulink 模型
% 适用于 MPU6050 加速度/角速度数据滤波
% 使用方法：在 MATLAB 中运行此脚本即可生成 .slx 文件

modelName = 'mpu6050_lowpass_filter';

% 关闭旧模型
bdclose(modelName);

% 创建新模型
new_system(modelName);
open_system(modelName);

%% ---------- 添加模块 ----------

% 1. 有用信号 - 2Hz 正弦波（模拟人体运动/慢速旋转）
src1 = [modelName '/Useful_Signal_2Hz'];
add_block('simulink/Sources/Sine Wave', src1);
set_param(src1, 'Amplitude', '10', 'Bias', '0', ...
    'Frequency', '2*pi*2', 'SampleTime', '0.001');

% 2. 噪声信号 - 50Hz 高频噪声
noiseSrc = [modelName '/HighFreq_Noise_50Hz'];
add_block('simulink/Sources/Sine Wave', noiseSrc);
set_param(noiseSrc, 'Amplitude', '3', 'Bias', '0', ...
    'Frequency', '2*pi*50', 'SampleTime', '0.001');

% 3. 加法器 - 混合信号+噪声
adder1 = [modelName '/Add_Noise'];
add_block('simulink/Math Operations/Add', adder1);
set_param(adder1, 'Inputs', '++');

% 4. 增益 α (滤波系数) — 减小 α 增强滤波效果
gainAlpha = [modelName '/Alpha_0.02'];
add_block('simulink/Math Operations/Gain', gainAlpha);
set_param(gainAlpha, 'Gain', '0.004');

% 5. 增益 1-α
gainOneMinus = [modelName '/One_Minus_Alpha'];
add_block('simulink/Math Operations/Gain', gainOneMinus);
set_param(gainOneMinus, 'Gain', '0.996');

% 6. 滤波求和 (α*x[n] + (1-α)*y[n-1])
filterSum = [modelName '/Filter_Sum'];
add_block('simulink/Math Operations/Add', filterSum);
set_param(filterSum, 'Inputs', '++');

% 7. Unit Delay (实现 y[n-1])
unitDelay = [modelName '/Unit_Delay'];
add_block('simulink/Discrete/Unit Delay', unitDelay);
set_param(unitDelay, 'SampleTime', '0.001', ...
    'InitialCondition', '0');

% 8. 示波器 - 对比原始信号和滤波后信号
scopeBlock = [modelName '/Scope'];
add_block('simulink/Sinks/Scope', scopeBlock);
set_param(scopeBlock, 'NumInputPorts', '2');

%% ---------- 连线 ----------

% 信号混合
add_line(modelName, 'Useful_Signal_2Hz/1', 'Add_Noise/1');
add_line(modelName, 'HighFreq_Noise_50Hz/1', 'Add_Noise/2');

% 含噪信号 → 示波器通道1
add_line(modelName, 'Add_Noise/1', 'Scope/1');

% 含噪信号 → 滤波：α*x[n]
add_line(modelName, 'Add_Noise/1', 'Alpha_0.02/1');

% 滤波通路：α*x[n] + (1-α)*y[n-1] = y[n]
add_line(modelName, 'Alpha_0.02/1', 'Filter_Sum/1');

% 反馈通路：y[n] → Unit Delay → y[n-1] → Gain(1-α) → Filter_Sum
add_line(modelName, 'Filter_Sum/1', 'Unit_Delay/1');
add_line(modelName, 'Unit_Delay/1', 'One_Minus_Alpha/1');
add_line(modelName, 'One_Minus_Alpha/1', 'Filter_Sum/2');

% 滤波输出 → 示波器通道2
add_line(modelName, 'Filter_Sum/1', 'Scope/2');

%% ---------- 布局美化（自动排列） ----------
Simulink.BlockDiagram.arrangeSystem(modelName);

% 设置仿真参数
set_param(modelName, 'StopTime', '5');

% 保存模型
save_system(modelName);

fprintf('==========================================\n');
fprintf('✅ 模型 "%s.slx" 已创建并打开！\n', modelName);
fprintf('==========================================\n');
fprintf('\n');
fprintf('📌 当前参数：\n');
fprintf('   有用信号:  2Hz, 幅值10\n');
fprintf('   噪声信号: 50Hz, 幅值3  \n');
fprintf('   采样周期: 1ms (更密集采样，波形更平滑)\n');
fprintf('   滤波系数 α = 0.004\n');
fprintf('   仿真时长: 5秒\n');
fprintf('\n');
fprintf('🎯 调整滤波强度：\n');
fprintf('   α 越小 → 滤波越强 → 输出越平滑 (延迟越大)\n');
fprintf('   α 越大 → 滤波越弱 → 响应越快 (噪声残留)\n');
fprintf('   常用范围: 0.01 ~ 0.3\n');
fprintf('\n');
fprintf('💡 示波器上：\n');
fprintf('   黄色 = 原始含噪信号\n');
fprintf('   蓝色 = 滤波后信号\n');
fprintf('\n');
