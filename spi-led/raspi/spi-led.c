// spidev_stream.c
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define LEDS 1200

int main(void)
{
  const char *dev = "/dev/spidev4.0";
  uint8_t  mode  = SPI_MODE_3;
  uint32_t speed = 3 * 1000 * 1000;

  int fd = open(dev, O_WRONLY);
  if (fd < 0) { perror("open"); return 1; }

  ioctl(fd, SPI_IOC_WR_MODE,          &mode);
  ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ,  &speed);

  unsigned int hoge=0;
  static uint8_t led[LEDS * 3];
  
  for(;;){
    hoge++;
    for (int i = 0; i < LEDS * 3; i += 3) {
      switch (hoge % 3) {
        case 0:
          led[i] = 0x00; // Green
          led[i + 1] = 0x4; // Red
          led[i + 2] = 0x00; // Blue
          break;
        case 1:
          led[i] = 0x4; // Green
          led[i + 1] = 0x00; // Red
          led[i + 2] = 0x00; // Blue
          break;
        case 2:
          led[i] = 0x00; // Green
          led[i + 1] = 0x00; // Red
          led[i + 2] = 0x5; // Blue
          break;
      }
    }
    // led[0] = 0x00; // First LED Green
    // led[1] = 0x88; // First LED Red
    // led[2] = 0x00; // First LED Blue

    // led[LEDS * 3 - 3] = 0x00; // Last LED Red
    // led[LEDS * 3 - 2] = 0x00;
    // led[LEDS * 3 - 1] = 0xff; // Last LED Blue

    // transmit
    /*プロトコル
        スタートバイト 0x55 0x5B
        受信データ LEDS*3バイト
        ストップバイト 0xAA
    */
    char tx_data[LEDS * 3 + 3];
    tx_data[0] = 0x55;
    tx_data[1] = 0x5B;
    for (int i = 0; i < LEDS * 3; ++i) {
      tx_data[i + 2] = led[i];
    }
    tx_data[LEDS * 3 + 2] = 0xAA; //End

    
    ssize_t n = write(fd, tx_data, sizeof(tx_data));
    if (n < 0) { perror("write"); break; }
    usleep(1000000); // min 2000us
  }
  close(fd);
  return 0;
}
