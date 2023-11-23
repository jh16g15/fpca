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
#include "spi_psram.h"

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

// #define MAIN_USE_FATFS
// #define MAIN_USE_MEMTEST

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

    u32 KBYTE = 1024;
    u32 PSRAM_KBYTES = 4 * 1024;

    psram_init();
    psram_read_id();
    printf_("Start PSRAM Test!\n");
    printf_("Begin PSRAM Test Writes\n");

    for (u16 j = 0; j < PSRAM_KBYTES; j++){
        for (u16 i = 0; i < KBYTE; i++){
            psram_write_byte(j*KBYTE+i, (u8)(i+j));
        }
        printf_("KB Written: %i / %i\r", j + 1, PSRAM_KBYTES);
    }
    printf_("Begin PSRAM Test Read + Verify\n");
    for (u16 j = 0; j < PSRAM_KBYTES; j++){
        for (u16 i = 0; i < KBYTE; i++)
        {
            u8 data = psram_read_byte(j*KBYTE+i);
            if (data != (u8)(i+j)){
                printf_("OOPS @ 0x%x, got 0x%x\n", i, data);
            }
        }
        printf_("KB Read   : %i / %i\r", j + 1, PSRAM_KBYTES);
    }
    printf_("PSRAM Test Done!\n");
    wait_for_btn_press(BTN_D);

#ifdef MAIN_USE_FATFS
    FATFS fs;
    f_mount(&fs, "", 1);
    list_dir("0:");
#endif
    psram_read_id();

#ifdef MAIN_USE_MEMTEST
    printf_("Test PSRAM with memtest (takes a while!)\n");
    int ret = memTest();
    printf_("memTest returned %i\n", ret);

    wait_for_btn_press(BTN_D);

    write_u32(PLATFORM_PSRAM_BASE, 0x00beef00);
    u32 rdat32 = read_u32(PLATFORM_PSRAM_BASE);
    printf_("0x%x\n", rdat32);

    printf_("Start Single Address Memtest\n");
    volatile u32 *psram = (u32*)PLATFORM_PSRAM_BASE;
    // test writing a bunch of values to the same address
    for (u32 i = 0; i < 256; i++){
    // try reverse (slightly different behaviour)
    // for (u32 i = 255; i >= 0; i--){
        psram[0] = i;
        printf_("%i \n", i); // delay
        rdat32 = psram[0];
        if (rdat32 != i){
            printf_("ERR Address %p, Exp 0x%x Act 0x%x\n", &psram[0], i, rdat32);
            wait_for_btn_press(BTN_D);
        }
    }
    printf_("Single Address Memtest done\n");

    // while(1){}
    u8 i = 10;
    printf_("Test PSRAM (press down)\n");
    wait_for_btn_press(BTN_D);
    while(1){
        // write_u32(PSRAM_BASE, 0x12345678);

        write_u32(PLATFORM_PSRAM_BASE+4, 0x7a6b5c4d);

        u8 rdat0 = read_u8(PLATFORM_PSRAM_BASE+4);
        u8 rdat1 = read_u8(PLATFORM_PSRAM_BASE+4+1);
        u8 rdat2 = read_u8(PLATFORM_PSRAM_BASE+4+2);
        u8 rdat3 = read_u8(PLATFORM_PSRAM_BASE+4+3);
        rdat32 = read_u32(PLATFORM_PSRAM_BASE+4);
        printf_("0x%x, 0x%x, 0x%x, 0x%x: 0x%x\n", rdat3, rdat2, rdat1, rdat0, rdat32);
        i++;
        while(1){}
    }
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