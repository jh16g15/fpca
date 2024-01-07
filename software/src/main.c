#include "cpu.h"

#ifdef BASYS3
#define BTN_U 3
#define BTN_L 2
#define BTN_R 1
#define BTN_D 0
#endif

#include "platform.h"
#include "uart.h"
#include "timer.h"
#include "gpio.h"
#include "utils.h"
// #include "ssd1306_i2c.h"
#include "spi.h"
#include "console.h"

#include "printf.h"
#include "ff.h"
#include "diskio.h"

#include "memtest.h"

void wait_for_btn_press(int btn){
    printf_(">\n");
    while(get_bit(GPIO_BTN, btn) != 0){} // wait for 0
    while(get_bit(GPIO_BTN, btn) != 1){} // wait for 1
    while(get_bit(GPIO_BTN, btn) != 0){} // wait for 0
}

// Peripherals defined globally
static struct uart uart0;
static struct timer timer0;

#define MAIN_USE_FATFS
// #define MAIN_USE_MEMTEST


#define KBYTE 1024

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

int psram_memtest(u32 size){
    volatile u8 *PSRAM = (volatile u8*)0x60000000;
    printf_("Start Memtest @%p, size= %i KB!\n", PSRAM, size);
    printf_("Begin PSRAM Test Writes\n");

    for (u16 j = 0; j < size; j++){
        for (u16 i = 0; i < KBYTE; i++){
            // printf_("(u8)i+j=%i", (u8)i + j);
            // psram_write_byte(j*KBYTE+i, (u8)(i+j));
            PSRAM[j * KBYTE + i] = (u8)(i + j);
        }
        printf_("KB Written: %i/%i\r", j + 1, size);
    }
    printf_("\nBegin PSRAM Test Read + Verify\n");
    for (u16 j = 0; j < size; j++){
        for (u16 i = 0; i < KBYTE; i++)
        {
            // u8 data = psram_read_byte(j*KBYTE+i);
            u8 data = PSRAM[j * KBYTE + i];
            if (data != (u8)(i+j)){
                printf_("OOPS @ 0x%x, got 0x%x, expected 0x%x\n", i, data, i+j);
            }
        }
        printf_("KB Read   : %i/%i\r", j + 1, size);
    }
    printf_("\nPSRAM Test Done!\n");
}


void main(void)
{

    Q_SSEG = 0xc1de;
    // PLATFORM INIT CODE
    uart_init(&uart0, (volatile void *)PLATFORM_UART0_BASE);
    timer_init(&timer0, (volatile void *)PLATFORM_TIMER0_BASE);

    uart_set_baud(&uart0, 9600);
    GPIO_LED = 0xF;

    // test SPI ram on PMOD B (working!!!)
    // spi_test();

    Q_SSEG = 0x0;
    // pointer to initial terminal created on the stack, containing the static address of the terminal
    console_init();
    cls();

    printf_("Hello World\n");

    // Test APS6404 PSRAM pmod for correct operation
    u32 PSRAM_KBYTES = 8 * 1024;

    printf_("Start PSRAM Test!\n");
    write_u8(PLATFORM_PSRAM_BASE, 0x81);
    u8 rdat8 = read_u8(PLATFORM_PSRAM_BASE);
    write_u16(PLATFORM_PSRAM_BASE, 0x5aa5);
    u16 rdat16 = read_u16(PLATFORM_PSRAM_BASE);
    write_u32(PLATFORM_PSRAM_BASE, 0x81abed1);
    u32 rdat32 = read_u32(PLATFORM_PSRAM_BASE);
    printf_("rdat: 0x%x 0x%x 0x%x\n", rdat8, rdat16, rdat32);
    // wait_for_btn_press(BTN_D);


    psram_memtest(1); //start with short test that should fail quickly
    #ifdef MAIN_USE_MEMTEST
    psram_memtest(PSRAM_KBYTES/8);   // longer test
    #endif
    printf_("\nAll PSRAM Tests Done!\n");
    // wait_for_btn_press(BTN_D);

#ifdef MAIN_USE_FATFS
    FATFS fs;   // filesystem object
    FIL file;   // file object

    char line[100]; // line buffer
    FRESULT fr; // fatfs result

    f_mount(&fs, "", 1);
    printf_("Filesystem Mounted!\n");
    printf_("Listing 0:\n");
    list_dir("0:");
    printf_("Opening 0:wifi.txt...\n");
    fr = f_open(&file, "0:wifi.txt", FA_READ);
    if (fr) printf_("failed to open 0:wifi.txt with error code 0x%x\n", fr);
    printf_("Opened 0:wifi.txt\n");
    // read and print each line
    while (f_gets(line, sizeof line, &file)){
        printf_(line);
    }
    printf_("\nEOF reached!\n");

    printf_("Closing 0:wifi.txt\n");
    f_close(&file);

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