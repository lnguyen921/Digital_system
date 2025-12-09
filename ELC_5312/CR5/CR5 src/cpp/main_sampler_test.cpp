/*****************************************************************//**
 * @file main_sampler_test.cpp
 *
 * @brief Basic test of nexys4 ddr mmio cores
 *
 * @author p chu
 * @version v1.0: initial release
 *********************************************************************/

// main_sampler_test.cpp

// main_sampler_test.cpp

#include "chu_init.h"
#include "gpio_cores.h"
#include "sseg_core.h"
#include "i2c_core.h"
#include <cstdint>

#define ADT7420_ADDR     0x4B   // you already verified this works
#define ADT7420_TEMP_REG 0x00

// Read temperature from ADT7420; returns 0 on success, non-zero on I2C error
static int read_adt7420(double &tempC)
{
   uint8_t reg = ADT7420_TEMP_REG;
   uint8_t buf[2];
   int status;

   // Point internal register pointer to temperature register
   status = i2c.write_transaction(ADT7420_ADDR, &reg, 1, /*rstart=*/0);
   if (status != 0) {
      return status;
   }

   // Read two bytes
   status = i2c.read_transaction(ADT7420_ADDR, buf, 2, /*rstart=*/0);
   if (status != 0) {
      return status;
   }

   // ADT7420 16-bit mode, 0.0078125 °C/LSB, two’s complement
   int16_t raw = (int16_t)((buf[0] << 8) | buf[1]);
   tempC = raw / 128.0;   // 1/128 = 0.0078125

   return 0;
}

// Show xx.xC on the 7-segment display
static void display_temp_7seg(double tempC)
{
   // One decimal place, handle sign
   int temp10 = (int)(tempC * 10.0 + (tempC >= 0 ? 0.5 : -0.5));  // °C * 10
   bool neg = (temp10 < 0);
   if (neg) temp10 = -temp10;

   int tens  = (temp10 / 100) % 10;   // 10s of °C
   int ones  = (temp10 / 10)  % 10;   // 1s of °C
   int tenth =  temp10 % 10;          // 0.1 °C digit

   // Clear all 8 digits first so no junk stays lit
   uint8_t ptn[8] = {0};

   // Assume pos 0 = rightmost digit
   ptn[0] = sseg.h2s(0xC);      // 'C'
   ptn[1] = sseg.h2s(tenth);    // 0.1
   ptn[2] = sseg.h2s(ones);     // ones
   ptn[3] = sseg.h2s(tens);     // tens (0 if < 10°C)

   if (neg) {
      // crude minus sign on next digit to the left (only middle segment)
      ptn[4] = 0x40;
   }

   // Write all 8 patterns at once
   sseg.write_8ptn(ptn);

   // Turn on decimal point after the ones digit (pos 2)
   sseg.set_dp(bit(2));
}

int main()
{
   uart.disp("CR5 sampler test with ADT7420\r\n");

   // Set I2C frequency (adjust if needed)
   i2c.set_freq(400000);   // 400 kHz

   // One initial read just to show status
   double tempC_init;
   int status = read_adt7420(tempC_init);
   uart.disp("Initial I2C status = ");
   uart.disp(status);
   uart.disp("\r\n");

   while (1) {
      double tempC;
      status = read_adt7420(tempC);

      if (status != 0) {
         uart.disp("I2C read error = ");
         uart.disp(status);
         uart.disp("\r\n");
      } else {
         // --- UART print: Temp (C) = xx.x ---
         int temp10 = (int)(tempC * 10.0 + (tempC >= 0 ? 0.5 : -0.5));
         bool neg = (temp10 < 0);
         if (neg) temp10 = -temp10;

         int tens  = (temp10 / 100) % 10;
         int ones  = (temp10 / 10)  % 10;
         int tenth =  temp10 % 10;

         uart.disp("Temp (C) = ");
         if (neg) uart.disp('-');
         if (tens) uart.disp(tens);  // suppress leading zero
         uart.disp(ones);
         uart.disp(".");
         uart.disp(tenth);
         uart.disp("\r\n");

         // --- 7-segment update ---
         display_temp_7seg(tempC);
      }

      sleep_ms(1000);
   }

   return 0;
}
