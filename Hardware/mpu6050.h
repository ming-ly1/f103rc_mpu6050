#ifndef MPU6050_H
#define MPU6050_H

#include "stdint.h"

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


struct axis{
    int16_t x;
    int16_t y;
    int16_t z;
};

struct euler_angles{
    float roll;
    float pitch;
    float yaw;  
};

struct mpu6050_data{
    struct axis acc;
    struct axis gyro;
    struct euler_angles euler_angle;
};


void mpu6050_init(void);
void mpu6050_get_acc(struct axis *acc_data);
#endif 
