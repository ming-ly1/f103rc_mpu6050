#include "mpu6050.h"
#include "i2c.h"
#include "stm32f1xx_hal_i2c.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "filter.h"

zero_move_t mpu6050_zero_move_data = {0, 0, 0, 0, 0, 0};
KalmanFilter_t mpu6050_acc_kalman_data[3] = {
    {0, 1.0f, 0.06f, 100.0f},
    {0, 1.0f, 0.06f, 100.0f},
    {0, 1.0f, 0.06f, 100.0f}
};

void mpu6050_write_byte(uint8_t reg, uint8_t data)
{
    HAL_I2C_Mem_Write(&hi2c2, MPU6050_ADDR, reg, 1, &data, 1, 100);
}
void mpu6050_write_bytes(uint8_t reg, uint8_t *data, uint8_t len)
{
    HAL_I2C_Mem_Write(&hi2c2, MPU6050_ADDR, reg, 1, data, len, 100);
}

void mpu6050_read_byte(uint8_t reg, uint8_t *data)
{
    HAL_I2C_Mem_Read(&hi2c2, MPU6050_ADDR, reg, 1, data, 1, 100);
}
void mpu6050_read_bytes(uint8_t reg, uint8_t *data, uint8_t len)
{
    HAL_I2C_Mem_Read(&hi2c2, MPU6050_ADDR, reg, 1, data, len, 100);
}

void mpu6050_get_acc(struct axis *acc_data)
{
    struct axis acc;
    uint8_t data[6];

    mpu6050_read_bytes(MPU6050_ACC_OUT, data, 6);

    acc.x = ((data[0] << 8) | data[1]) - mpu6050_zero_move_data.acc.x;
    acc.y = ((data[2] << 8) | data[3]) - mpu6050_zero_move_data.acc.y;
    acc.z = ((data[4] << 8) | data[5]) - mpu6050_zero_move_data.acc.z;

    *acc_data = acc;
}
void mpu6050_get_gyro(struct axis *gyro_data)
{
    struct axis gyro;
    uint8_t data[6];
    
    mpu6050_read_bytes(MPU6050_GYRO_OUT, data, 6);

    gyro.x = ((data[0] << 8) | data[1]) - mpu6050_zero_move_data.gyro.x;
    gyro.y = ((data[2] << 8) | data[3]) - mpu6050_zero_move_data.gyro.y;
    gyro.z = ((data[4] << 8) | data[5]) - mpu6050_zero_move_data.gyro.z;

    *gyro_data = gyro;
}

void mpu6050_get_gyro_filter(struct axis *gyro_data)
{
    axis_t gyro_filter;

    mpu6050_get_gyro(&gyro_filter);
    gyro_filter.x = low_pass_filter(gyro_filter.x);
    gyro_filter.y = low_pass_filter(gyro_filter.y);
    gyro_filter.z = low_pass_filter(gyro_filter.z);

    *gyro_data = gyro_filter;
}

void mpu6050_get_acc_filter(struct axis *acc_data)
{
    axis_t acc_filter;

    mpu6050_get_acc(&acc_filter);
    acc_filter.x = Kalman_Update(&mpu6050_acc_kalman_data[0], acc_filter.x);
    acc_filter.y = Kalman_Update(&mpu6050_acc_kalman_data[1], acc_filter.y);
    acc_filter.z = Kalman_Update(&mpu6050_acc_kalman_data[2], acc_filter.z);

    *acc_data = acc_filter;
}

void mpu6050_calculate_zero_move(zero_move_t *zero_move_data)
{
    zero_move_t mpu6050_new_data, mpu6050_old_data;
    int32_t acc_x_sum = 0, acc_y_sum = 0, acc_z_sum = 0;
    int32_t gyro_x_sum = 0, gyro_y_sum = 0, gyro_z_sum = 0;
    uint8_t error = 0;
    axis_t acc_max_data = {INT16_MIN, INT16_MIN, INT16_MIN},acc_min_data = {INT16_MAX, INT16_MAX, INT16_MAX};

    mpu6050_get_acc(&mpu6050_old_data.acc);
    for(uint8_t i = 0; i < 100; i++)
    {
        mpu6050_get_acc(&mpu6050_new_data.acc);
        if(mpu6050_new_data.acc.x > acc_max_data.x)
            acc_max_data.x = mpu6050_new_data.acc.x;
        if(mpu6050_new_data.acc.y > acc_max_data.y)
            acc_max_data.y = mpu6050_new_data.acc.y;
        if(mpu6050_new_data.acc.z > acc_max_data.z)
            acc_max_data.z = mpu6050_new_data.acc.z;
        if(mpu6050_new_data.acc.x < acc_min_data.x)
            acc_min_data.x = mpu6050_new_data.acc.x;
        if(mpu6050_new_data.acc.y < acc_min_data.y)
            acc_min_data.y = mpu6050_new_data.acc.y;
        if(mpu6050_new_data.acc.z < acc_min_data.z)
            acc_min_data.z = mpu6050_new_data.acc.z;
        
        if(abs(mpu6050_new_data.acc.x - mpu6050_old_data.acc.x) > ZERO_MOVE_COUNT ||\
            abs(mpu6050_new_data.acc.y - mpu6050_old_data.acc.y) > ZERO_MOVE_COUNT ||\
            abs(mpu6050_new_data.acc.z - mpu6050_old_data.acc.z) > ZERO_MOVE_COUNT)
        {
            i = 0;
            error++;
            printf("acc max:%6d, %6d, %6d\r\n",acc_max_data.x, acc_max_data.y,\
                 acc_max_data.z);
            printf("acc min:%6d, %6d, %6d\r\n",acc_min_data.x, acc_min_data.y,\
                 acc_min_data.z);
        }
        if(error > 50)
        {
            printf("-----zero_move error-----\r\n");
            return;
        }
        
        mpu6050_old_data.acc = mpu6050_new_data.acc;
        HAL_Delay(5);
    }

    for(uint8_t i = 0; i < 100; i++)
    {
        mpu6050_get_acc(&mpu6050_new_data.acc);
        acc_x_sum += mpu6050_new_data.acc.x;
        acc_y_sum += mpu6050_new_data.acc.y;
        acc_z_sum += mpu6050_new_data.acc.z - 16384; // 16384 为 1g 的值

        mpu6050_get_gyro(&mpu6050_new_data.gyro);
        gyro_x_sum += mpu6050_new_data.gyro.x;
        gyro_y_sum += mpu6050_new_data.gyro.y;
        gyro_z_sum += mpu6050_new_data.gyro.z;
        HAL_Delay(10);
    }

    zero_move_data->acc.x = acc_x_sum / 100;
    zero_move_data->acc.y = acc_y_sum / 100;
    zero_move_data->acc.z = acc_z_sum / 100;
    zero_move_data->gyro.x = gyro_x_sum / 100;
    zero_move_data->gyro.y = gyro_y_sum / 100;
    zero_move_data->gyro.z = gyro_z_sum / 100;
    printf("zero_move_data:,%6d, %6d, %6d, %6d, %6d, %6d\r\n",
           zero_move_data->acc.x, zero_move_data->acc.y, zero_move_data->acc.z,
           zero_move_data->gyro.x, zero_move_data->gyro.y, zero_move_data->gyro.z);
    printf("max:%6d, %6d, %6d\r\n",acc_max_data.x, acc_max_data.y, acc_max_data.z);
    printf("min:%6d, %6d, %6d\r\n",acc_min_data.x, acc_min_data.y, acc_min_data.z);
    // HAL_Delay(3000);
}

void mpu6050_init(void)
{
    /* 复位芯片 */
    mpu6050_write_byte(MPU6050_PWR_MGMT_1, 0x80);
    HAL_Delay(100);

    /* 唤醒 */
    mpu6050_write_byte(MPU6050_PWR_MGMT_1, 0x01);
    HAL_Delay(10);

    mpu6050_write_byte(MPU6050_GYRO_CONFIG, 0x18);
    mpu6050_write_byte(MPU6050_ACC_CONFIG, 0x00);
    mpu6050_write_byte(MPU6050_SAMPLE_RATE_DIV, 0x04); // 1000Hz/10 
    mpu6050_write_byte(MPU6050_CONFIG, 0x04);

    mpu6050_write_byte(MPU6050_PWR_MGMT_1, 0x01);
    mpu6050_write_byte(MPU6050_PWR_MGMT_2, 0x00);

    mpu6050_calculate_zero_move(&mpu6050_zero_move_data);
}


