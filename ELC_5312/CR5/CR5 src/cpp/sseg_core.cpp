/*****************************************************************//**
 * @file sseg_core.cpp
 *
 * @brief implementation of SsegCore class
 *
 * @author p chu
 * @version v1.0: initial release
 ********************************************************************/

#include "sseg_core.h"
#include "chu_init.h" 
SsegCore::SsegCore(uint32_t core_base_addr) {
   base_addr = core_base_addr;

   // blank all 8 digits, no decimal points
   uint8_t blank_ptn[8];
   for (int i = 0; i < 8; i++) {
       blank_ptn[i] = 0xff;   // all segments off (active low)
   }
   write_8ptn(blank_ptn);
   set_dp(0x00);              // all decimal points off
}


SsegCore::~SsegCore() {
}
// not used

void SsegCore::write_led() {
   int i, p;
   uint32_t word = 0;

   // pack left 4 patterns into a 32-bit word
   // ptn_buf[0] is the leftmost led
   for (i = 0; i < 4; i++) {
      word = (word << 8) | ptn_buf[3 - i];
   }
   // incorporate decimal points (bit 7 of pattern)
   for (i = 0; i < 4; i++) {
      p = bit_read(dp, i);
      bit_write(word, 7 + 8 * i, p);
   }
   io_write(base_addr, DATA_LOW_REG, word);
   // pack right 4 patterns into a 32-bit word
   for (i = 0; i < 4; i++) {
      word = (word << 8) | ptn_buf[7 - i];
   }
   // incorporate decimal points
   for (i = 0; i < 4; i++) {
      p = bit_read(dp, 4 + i);
      bit_write(word, 7 + 8 * i, p);
   }
   io_write(base_addr, DATA_HIGH_REG, word);
}

void SsegCore::write_8ptn(uint8_t *ptn_array) {
   int i;

   for (i = 0; i < 8; i++) {
      ptn_buf[i] = *ptn_array;
      ptn_array++;
   }
   write_led();
}

void SsegCore::write_1ptn(uint8_t pattern, int pos) {
   ptn_buf[pos] = pattern;
   write_led();
}

// set decimal points,
// bits turn on the corresponding decimal points
void SsegCore::set_dp(uint8_t pt) {
   dp = ~pt;     // active low
   write_led();
}

// PTN_table for the segment
uint8_t SsegCore::h2s(int hex) {
   // Original Chu table: bits = [dp g f e d c b a] (active low)
   static const uint8_t PTN_TABLE[16] =
     {0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80, 0x90, //0-9
      0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e };                       //a-f

   uint8_t p;

   if (hex < 16)
      p = PTN_TABLE[hex];
   else
      p = 0xff;

   // old mapping which mismatched with te xdc from the HDL side
   // bus[7] = dp (same)
   // bus[6] = a (old bit0)
   // bus[5] = b (old bit1)
   // bus[4] = c (old bit2)
   // bus[3] = d (old bit3)
   // bus[2] = e (old bit4)
   // bus[1] = f (old bit5)
   // bus[0] = g (old bit6)

   uint8_t q = 0;

   if (p & 0x80) q |= 0x80;  // dp
   if (p & 0x01) q |= 0x40;  // a -> bit6
   if (p & 0x02) q |= 0x20;  // b -> bit5
   if (p & 0x04) q |= 0x10;  // c -> bit4
   if (p & 0x08) q |= 0x08;  // d -> bit3
   if (p & 0x10) q |= 0x04;  // e -> bit2
   if (p & 0x20) q |= 0x02;  // f -> bit1
   if (p & 0x40) q |= 0x01;  // g -> bit0

   return q;
}

