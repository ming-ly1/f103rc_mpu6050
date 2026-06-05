#ifndef FILTER_H
#define FILTER_H

#include <stdint.h>

/* ========== 一阶低通滤波 ========== */
#define LARFA   0.2f

int16_t low_pass_filter(int16_t input);

/* ========== 1D 卡尔曼滤波 ========== */
typedef struct {
    float x;    /* 滤波后的最优估计值 */
    float p;    /* 估计误差协方差 */
    float q;    /* 过程噪声（值越大响应越快） */
    float r;    /* 测量噪声（值越大越平滑） */
} KalmanFilter_t;

void    Kalman_Init(KalmanFilter_t *kf, float init_value, float q, float r);
float   Kalman_Update(KalmanFilter_t *kf, float measurement);
void    Kalman_SetQ(KalmanFilter_t *kf, float q);
void    Kalman_SetR(KalmanFilter_t *kf, float r);

#endif
