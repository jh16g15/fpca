#include "cpu.h"

#ifdef BASYS3
#define BTN_U 3
#define BTN_L 2
#define BTN_R 1
#define BTN_D 0
#endif

#include "uart.h"
#include "gpio.h"
#include "utils.h"
// #include "ssd1306_i2c.h"
#include "spi.h"
#include "console.h"

#include "printf.h"
#include "ff.h"
#include "diskio.h"

void wait_for_btn_press(int btn){
    while(get_bit(GPIO_BTN, btn) != 0){} // wait for 0
    while(get_bit(GPIO_BTN, btn) != 1){} // wait for 1
    while(get_bit(GPIO_BTN, btn) != 0){} // wait for 0
}

u8 spi_ram_read(u32 addr){
    spi_start();
    spi_write_byte(0x3); // send Read instruction
    // send 24-bit address
    spi_write_byte((0xFF0000 & addr) >> 16);
    spi_write_byte((0x00FF00 & addr) >> 8);
    spi_write_byte((0x0000FF & addr));
    // read byte
    u8 data = spi_read_byte();
    spi_stop();
    return data;
}

void spi_ram_write(u32 addr, u8 data){
    spi_start();
    spi_write_byte(0x2); // send Write instruction
    // send 24-bit address
    spi_write_byte((0xFF0000 & addr) >> 16);
    spi_write_byte((0x00FF00 & addr) >> 8);
    spi_write_byte((0x0000FF & addr));
    // write byte
    spi_write_byte(data);
    spi_stop();
}

void spi_check(u32 addr){
    u8 rdata;
    rdata = spi_ram_read(addr);
    Q_SSEG = rdata;
    GPIO_LED = addr;
    wait_for_btn_press(BTN_L);
}

void spi_test(){
    spi_ram_write(0x0, 0x00);
    spi_ram_write(0x1, 0x11);
    spi_ram_write(0x2, 0x22);
    spi_ram_write(0x3, 0x33);
    spi_ram_write(0x4, 0x44);
    spi_ram_write(0x5, 0x55);

    spi_check(0x0);
    spi_check(0x1);
    spi_check(0x2);
    spi_check(0x3);
    spi_check(0x4);
    spi_check(0x5);
}

// #define MAIN_USE_FATFS

FRESULT list_dir (const char *path)
{
    FRESULT res;
    DIR dir;
    FILINFO fno;
    int nfile, ndir;


    res = f_opendir(&dir, path);                       /* Open the directory */
    if (res == FR_OK) {
        nfile = ndir = 0;
        for (;;) {
            res = f_readdir(&dir, &fno);                   /* Read a directory item */
            if (res != FR_OK || fno.fname[0] == 0) break;  /* Error or end of dir */
            if (fno.fattrib & AM_DIR) {            /* Directory */
                printf_("   <DIR>   %s\n", fno.fname);
                ndir++;
            } else {                               /* File */
                printf_("%10u %s\n", fno.fsize, fno.fname);
                nfile++;
            }
        }
        f_closedir(&dir);
        printf_("%d dirs, %d files.\n", ndir, nfile);
    } else {
        printf_("Failed to open \"%s\". (%u)\n", path, res);
    }
    return res;
}

// reads PSRAM ID register and confirms density
void psram_read_id(void)
{
    printf_("Reading PSRAM ID\n");
    spi_stop();
    spi_start();
    spi_write_byte(0x9F);   // PSRAM READ ID

    spi_write_byte(0xFF);   // PSRAM Address (unused for this cmd)
    spi_write_byte(0xFF);   // PSRAM Address (unused for this cmd)
    spi_write_byte(0xFF);   // PSRAM Address (unused for this cmd)

    u8 manu_id = spi_read_byte();
    u8 kgd = spi_read_byte();
    u8 eid[6];
    eid[5] = spi_read_byte();
    eid[4] = spi_read_byte();
    eid[3] = spi_read_byte();
    eid[2] = spi_read_byte();
    eid[1] = spi_read_byte();
    eid[0] = spi_read_byte();

    spi_stop();
    u8 density = eid[5] >> 5;  // top 3 bits represent density
    u8 density_MB = 2 << (density + 3);
    eid[5] = eid[5] & 0x1F;
    printf_("MANU: 0x%x, KGD: 0x%x, Capacity: %dMB, EID: 0x%x%x%x%x%x%x\n", manu_id, kgd, density_MB, eid[5], eid[4], eid[3], eid[2], eid[1], eid[0]);
}

void main(void)
{
    Q_SSEG = 0xc1de;
    uart_set_baud(9600);
    GPIO_LED = 0xF;

    // test SPI ram on PMOD B (working!!!)
    // spi_test();

    Q_SSEG = 0x0;
    // pointer to initial terminal created on the stack, containing the static address of the terminal
    console_init();
    cls();

    printf_("Hello World\n");

    // Test APS6404 PSRAM pmod for correct operation
    psram_read_id();

#ifdef MAIN_USE_FATFS
    FATFS fs;
    f_mount(&fs, "", 1);
    list_dir("0:");


    #endif

    printf_("CPU Arch      : %s\n", "RISC-V RV32I");
    printf_("CPU Frequency : %i MHz\n", GPIO_SOC_FREQ/1000000);
    printf_("CPU Memory    : %i KB\n", GPIO_SOC_MEM/1024);

    // SECTOR 0 ANALYSIS
    // 440 bytes of 0x0 (22 lines of 20 bytes)
    // 0xbe 0xdb 0x94 0x12 0x00 0x00 (6 bytes with last bootcode)

    // Partition 0
    // 00 82 03 00 0B FE FF C5 00 20 00 00 46 AC EC 00

    // Little Endian!

    // 00   Inactive
    // 82   Beginning of partition (Head)
    // 0030 Beginning of partition (Cylinder/Sector)
    // 0B   Type of Partition   - 32bit FAT!
    // FE   End of Partition (Head)
    // C5FF End of Partition (Cylinder/Sector)
    // 00002000   Sectors between MBR and First Sector in partition
    // 00ECAC46   Number of Sectors in Partition (=15510598, which x512b = 8GB!!)

    int tmp = 21;
    int test_var = 0;

    printf_("Happy days! Test Var location (on stack): %p\n", &test_var);
    putchar_(1);
    putchar_(' ');
    putchar_(' ');
    putchar_(1);
    putchar_(' ');
    while(1){}
    while(1){
        putchar_(test_var);
        printf_("test_var=%i\n", test_var);
        test_var++;

        // cls();
    }


}