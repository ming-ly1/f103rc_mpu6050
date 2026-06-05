#include "filter.h"

int16_t low_pass_filter(int16_t input)
{
    static int16_t output;
    output =LARFA * input + (1 - LARFA) * output;
    return output;
}

/* ========== 1D 卡尔曼滤波 ========== */

void Kalman_Init(KalmanFilter_t *kf, float init_value, float q, float r)
{
    kf->x = init_value;
    kf->p = 1.0f;
    kf->q = q;
    kf->r = r;
}

float Kalman_Update(KalmanFilter_t *kf, float measurement)
{
    kf->p = kf->p + kf->q;
    float k = kf->p / (kf->p + kf->r);
    kf->x = kf->x + k * (measurement - kf->x);
    kf->p = (1.0f - k) * kf->p;
    return kf->x;
}

void Kalman_SetQ(KalmanFilter_t *kf, float q)
{
    kf->q = q;
}

void Kalman_SetR(KalmanFilter_t *kf, float r)
{
    kf->r = r;
}
