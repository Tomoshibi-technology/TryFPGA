// spidev_stream.c
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define LEDS 120

int main(void)
{
  const char *dev = "/dev/spidev4.0";
  uint8_t  mode  = SPI_MODE_3;
  uint32_t speed = 10 * 1000 * 1000;

  int fd = open(dev, O_WRONLY);
  if (fd < 0) { perror("open"); return 1; }

  ioctl(fd, SPI_IOC_WR_MODE,          &mode);
  ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ,  &speed);




  static uint8_t led[LEDS * 3];
  for (int i = 0; i < LEDS * 3; i += 3) {
    led[i] = 0x22; // Green
    led[i + 1] = 0x22; // Red
    led[i + 2] = 0x00+i/3; // Blue
  }

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

  for(;;){
    ssize_t n = write(fd, tx_data, sizeof(tx_data));
    if (n < 0) { perror("write"); break; }
    usleep(2000000); // 300ms = 300,000us
  }

  close(fd);
  return 0;
}
