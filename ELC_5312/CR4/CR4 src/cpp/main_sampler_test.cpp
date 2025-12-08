/*****************************************************************//**
 * @file main_sampler_test.cpp
 *
 * @brief Basic test of nexys4 ddr mmio cores
 *
 * @author p chu
 * @version v1.0: initial release
 *********************************************************************/

// #define _DEBUG
#include "chu_init.h"
#include "gpio_cores.h"
#include "xadc_core.h"
#include "sseg_core.h"
#include "spi_core.h"
#include "i2c_core.h"
#include "ps2_core.h"
#include "ddfs_core.h"
#include "adsr_core.h"
#include "chu_io_map.h"
#include <cmath>
GpoCore led(get_slot_addr(BRIDGE_BASE, S2_LED));
SpiCore spi(get_slot_addr(BRIDGE_BASE, S9_SPI));
SsegCore sseg(get_slot_addr(BRIDGE_BASE, S8_SSEG));

//helper for orientation
int compute_orientation(float x, float y) {
    float angle = std::atan2(y, x) * 180.0f / 3.14159f;
 // convert to degrees

    // Normalize angle into [-180, +180)
    if (angle >= 180) angle -= 360;
    if (angle < -180) angle += 360;

    // Determine quadrant
    if (angle >= -45 && angle < 45)
        return 0;   // 0 degrees
    else if (angle >= 45 && angle < 135)
        return 1;   // 90 degrees
    else if (angle >= -135 && angle < -45)
        return 3;   // 270 degrees
    else
        return 2;   // 180 degrees
}
//drive LED based on orientation
void show_orientation_led(int orient) {
    led.write(0); // clear all LEDs first

    switch(orient) {
    case 0: led.write(1 << 0); break;  // LED0
    case 1: led.write(1 << 1); break;  // LED1
    case 2: led.write(1 << 2); break;  // LED2
    case 3: led.write(1 << 3); break;  // LED3
    }
}

//helper for abs
static inline int iabs(int v) {
    return (v < 0) ? -v : v;
}

// ADXL362 commands / registers
const uint8_t WR_CMD          = 0x0A;
const uint8_t RD_CMD          = 0x0B;
const uint8_t PART_ID_REG     = 0x02;
const uint8_t POWER_CTL_REG   = 0x2D;
const uint8_t MEAS_MODE_DATA  = 0x02;  // measurement mode
const uint8_t XDATA_REG       = 0x08;  // 8-bit X/Y/Z


// 7-seg patterns (active low)
static const uint8_t SSEG_BLANK = 0xFF;  // all segments off
static const uint8_t SSEG_DASH  = 0xBF;  // minus sign (only middle segment on)

// this function is used to add negative values instead of A. "-X" instead of "AX"
//show signed value in two digits at positions [tens_pos, ones_pos] so that it no longer shows A for minus sign.
void display_signed_2dig(SsegCore *sseg, int value, int tens_pos, int ones_pos)
{
    // clamp to range
    if (value > 99)  value = 99;
    if (value < -9)  value = -9;

    int is_neg = (value < 0);
    int mag    = iabs(value);

    int tens = mag / 10;
    int ones = mag % 10;

    uint8_t tens_ptn;

    if (is_neg && mag < 10) {
        // -1 .. -9  -> show "-X" on 7 segment
        tens_ptn = SSEG_DASH;
    } else if (!is_neg && tens == 0) {
        // 0 .. 9 -> blank tens digit for positive #
        tens_ptn = SSEG_BLANK;
    } else {
        // 10..99 or -10..-99 (after clamping)
        tens_ptn = sseg->h2s(tens);
    }

    sseg->write_1ptn(tens_ptn,      tens_pos);
    sseg->write_1ptn(sseg->h2s(ones), ones_pos);
}

//updated fn to make 7-seg to display in tens
void display_xyz_7seg(SsegCore *sseg, int x, int y, int z)
{
    display_signed_2dig(sseg, x, 7, 6);  // X tens, ones
    display_signed_2dig(sseg, y, 5, 4);  // Y tens, ones
    display_signed_2dig(sseg, z, 3, 2);  // Z tens, ones

    // last two digits off
    sseg->write_1ptn(SSEG_BLANK, 1);
    sseg->write_1ptn(SSEG_BLANK, 0);

    sseg->set_dp(0x00);   // no decimal points
}

void init_accel()
{
    spi.set_freq(400000);
    spi.set_mode(0, 0);

    // 1) (Optional) confirm PART ID again
    spi.assert_ss(0);
    spi.transfer(RD_CMD);
    spi.transfer(PART_ID_REG);
    int id = spi.transfer(0x00);
    spi.deassert_ss(0);

    uart.disp("ADXL362 PART ID (Expected: 0xF2): 0x");
    uart.disp(id, 16);
    uart.disp("\n\r");

    // 2) Put into measurement mode
    spi.assert_ss(0);
    spi.transfer(WR_CMD);
    spi.transfer(POWER_CTL_REG);
    spi.transfer(MEAS_MODE_DATA);
    spi.deassert_ss(0);

    uart.disp("ADXL362 in measurement mode.\n\r");
}

void read_xyz_once()
{
    const float raw_max = 127.0f / 2.0f;
    int8_t xraw, yraw, zraw;
    float x, y, z;

    spi.assert_ss(0);
    spi.transfer(RD_CMD);
    spi.transfer(XDATA_REG);
    xraw = spi.transfer(0x00);
    yraw = spi.transfer(0x00);
    zraw = spi.transfer(0x00);
    spi.deassert_ss(0);

    x = (float)xraw / raw_max;
    y = (float)yraw / raw_max;
    z = (float)zraw / raw_max;

    uart.disp("XYZ (g): ");
    uart.disp(x, 3); uart.disp(" / ");
    uart.disp(y, 3); uart.disp(" / ");
    uart.disp(z, 3); uart.disp("\n\r");
}

void test_sseg_digits()
{
    // position of digit 0 = rightmost digit in Chu's code
    for (int pos = 0; pos < 8; ++pos) {
        sseg.write_1ptn(sseg.h2s(pos), pos);  // show 0..7
    }
}


int main() {
    uart.disp("=== CR4 Accelerometer + Orientation Test ===\n\r");

    init_accel();          // put ADXL362 into measurement mode
    sleep_ms(200);

    while (1) {
        // --- Read X/Y/Z ---
        spi.assert_ss(0);
        spi.transfer(RD_CMD);
        spi.transfer(XDATA_REG);
        int8_t xraw = spi.transfer(0x00);
        int8_t yraw = spi.transfer(0x00);
        int8_t zraw = spi.transfer(0x00);
        spi.deassert_ss(0);

        float x = (float)xraw / (127.0f / 2.0f);
        float y = (float)yraw / (127.0f / 2.0f);
        float z = (float)zraw / (127.0f / 2.0f);

        // --- Print to UART ---
        uart.disp("XYZ (g): ");
        uart.disp(x, 3); uart.disp(" / ");
        uart.disp(y, 3); uart.disp(" / ");
        uart.disp(z, 3); uart.disp("\n\r");

        // --- Show XYZ on 7-seg ---
        int xi = (int)(x * 10);
        int yi = (int)(y * 10);
        int zi = (int)(z * 10);
        display_xyz_7seg(&sseg, xi, yi, zi);

        // --- Compute Orientation ---
        int orient = compute_orientation(x, y);

        // --- Light LEDs ---
        show_orientation_led(orient);

        sleep_ms(150);
    }
}

