#include "mpu6050.h"
#include "i2c.h"
#include "stm32f1xx_hal_i2c.h"

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
    mpu6050_write_byte(MPU6050_SAMPLE_RATE_DIV, 0x13);
    mpu6050_write_byte(MPU6050_CONFIG, 0x04);

    mpu6050_write_byte(MPU6050_PWR_MGMT_1, 0x01);
    mpu6050_write_byte(MPU6050_PWR_MGMT_2, 0x00);
}

void mpu6050_get_acc(struct axis *acc_data)
{
    struct axis acc;
    uint8_t data[6];

    mpu6050_read_bytes(MPU6050_ACC_OUT, data, 6);

    acc.x = (data[0] << 8) | data[1];
    acc.y = (data[2] << 8) | data[3];
    acc.z = (data[4] << 8) | data[5];

    *acc_data = acc;
}
