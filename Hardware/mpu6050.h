#ifndef MPU6050_H
#define MPU6050_H

#include "stdint.h"
#include "filter.h"

#define MPU6050_ADDR                            0xD0
#define MPU6050_WRITE_REG                       0xD0
#define MPU6050_READ_REG                        0xD1

#define MPU6050_PWR_MGMT_1                      0x6B
#define MPU6050_PWR_MGMT_1_RESET                0x80
#define MPU6050_PWR_MGMT_1_CLOCK_SEL_PLL        0x01

#define MPU6050_GYRO_CONFIG                     0x1B
#define MPU6050_ACC_CONFIG                      0x1C
#define MPU6050_FIFO_EN                         0x23
#define MPU6050_SAMPLE_RATE_DIV                 0x19
#define MPU6050_CONFIG                          0x1A

#define MPU6050_PWR_MGMT_2                      0x6C
#define MPU6050_WHO_AM_I                        0x75

#define MPU6050_ACC_OUT                         0x3B
#define MPU6050_GYRO_OUT                        0x43

#define ZERO_MOVE_COUNT                         300
typedef struct axis{
    int16_t x;
    int16_t y;
    int16_t z;
}   axis_t;

typedef struct euler_angles{
    float roll;
    float pitch;
    float yaw;  
}   euler_angles_t;

typedef struct {
    axis_t acc;
    axis_t gyro;
}  zero_move_t;

typedef struct {
    struct axis acc;
    struct axis gyro;
    struct euler_angles euler_angle;
    
}  mpu6050_data_t;

void mpu6050_init(void);
void mpu6050_get_acc(struct axis *acc_data);
void mpu6050_get_gyro(struct axis *gyro_data);
void mpu6050_get_gyro_filter(struct axis *gyro_data);
void mpu6050_get_acc_filter(struct axis *acc_data);
void mpu6050_calculate_zero_move(zero_move_t *zero_move_data);
// void mpu6050_get_euler_angle(struct euler_angles *euler_angle_data);

extern KalmanFilter_t mpu6050_acc_kalman_data[3];
#endif

