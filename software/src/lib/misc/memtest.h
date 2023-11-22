#ifndef _MEMTEST_H
#define _MEMTEST_H

#include "printf.h"
// #include "utils.h"

// Barr, Michael. "Software-Based Memory Testing," Embedded Systems Programming, July 2000, pp. 28-40.
// https://barrgroup.com/resources/free-source-code-memory-tests-c
// #define NULL 0
// typedef unsigned char datum;    /* Set the data bus width to 8 bits.  */
typedef unsigned int datum;    /* Set the data bus width to 32 bits.  */


/**********************************************************************
 *
 * Function:    memTestDataBus()
 *
 * Description: Test the data bus wiring in a memory region by
 *              performing a walking 1's test at a fixed address
 *              within that region.  The address (and hence the
 *              memory region) is selected by the caller.
 *
 * Notes:
 *
 * Returns:     0 if the test succeeds.
 *              A non-zero result is the first pattern that failed.
 *
 **********************************************************************/

datum memTestDataBus(volatile datum * address)
{
    datum pattern;


    /*
     * Perform a walking 1's test at the given address.
     */
    for (pattern = 1; pattern != 0; pattern <<= 1)
    {
        /*
         * Write the test pattern.
         */
        *address = pattern;

        /*
         * Read it back (immediately is okay for this test).
         */
        if (*address != pattern)
        {
            printf_("memTestDataBus Walking Ones test pattern error: %i\n", pattern);
            return (pattern);
        }
    }
    printf_("memTestDataBus PASSED\n");
    return (0);

}   /* memTestDataBus() */

/**********************************************************************
 *
 * Function:    memTestAddressBus()
 *
 * Description: Test the address bus wiring in a memory region by
 *              performing a walking 1's test on the relevant bits
 *              of the address and checking for aliasing. This test
 *              will find single-bit address failures such as stuck
 *              -high, stuck-low, and shorted pins.  The base address
 *              and size of the region are selected by the caller.
 *
 * Notes:       For best results, the selected base address should
 *              have enough LSB 0's to guarantee single address bit
 *              changes.  For example, to test a 64-Kbyte region,
 *              select a base address on a 64-Kbyte boundary.  Also,
 *              select the region size as a power-of-two--if at all
 *              possible.
 *
 * Returns:     NULL if the test succeeds.
 *              A non-zero result is the first address at which an
 *              aliasing problem was uncovered.  By examining the
 *              contents of memory, it may be possible to gather
 *              additional information about the problem.
 *
 **********************************************************************/
datum * memTestAddressBus(volatile datum * baseAddress, unsigned long nBytes)
{
    unsigned long addressMask = (nBytes/sizeof(datum) - 1);
    unsigned long offset;
    unsigned long testOffset;

    datum pattern     = (datum) 0xAAAAAAAA;
    datum antipattern = (datum) 0x55555555;


    /*
     * Write the default pattern at each of the power-of-two offsets.
     */
    for (offset = 1; (offset & addressMask) != 0; offset <<= 1)
    {
        baseAddress[offset] = pattern;
    }

    /*
     * Check for address bits stuck high.
     */
    testOffset = 0;
    baseAddress[testOffset] = antipattern;

    for (offset = 1; (offset & addressMask) != 0; offset <<= 1)
    {
        if (baseAddress[offset] != pattern)
        {
            printf_("memTestAddressBus stuck high error: %i\n", pattern);
            return ((datum *)&baseAddress[offset]);
        }
    }

    baseAddress[testOffset] = pattern;

    /*
     * Check for address bits stuck low or shorted.
     */
    for (testOffset = 1; (testOffset & addressMask) != 0; testOffset <<= 1)
    {
        baseAddress[testOffset] = antipattern;

		if (baseAddress[0] != pattern)
		{
            printf_("memTestAddressBus stuck low error0: %i\n", pattern);
            return ((datum *)&baseAddress[testOffset]);
        }

        for (offset = 1; (offset & addressMask) != 0; offset <<= 1)
        {
            if ((baseAddress[offset] != pattern) && (offset != testOffset))
            {
                printf_("memTestAddressBus stuck low error1: %i\n", pattern);
                return ((datum *)&baseAddress[testOffset]);
            }
        }

        baseAddress[testOffset] = pattern;
    }
    printf_("memTestAddressBus PASSED\n");
    return (0); // NULL

}   /* memTestAddressBus() */

/**********************************************************************
 *
 * Function:    memTestDevice()
 *
 * Description: Test the integrity of a physical memory device by
 *              performing an increment/decrement test over the
 *              entire region.  In the process every storage bit
 *              in the device is tested as a zero and a one.  The
 *              base address and the size of the region are
 *              selected by the caller.
 *
 * Notes:
 *
 * Returns:     NULL if the test succeeds.
 *
 *              A non-zero result is the first address at which an
 *              incorrect value was read back.  By examining the
 *              contents of memory, it may be possible to gather
 *              additional information about the problem.
 *
 **********************************************************************/
datum * memTestDevice(volatile datum * baseAddress, unsigned long nBytes)
{
    unsigned long offset;
    unsigned long nWords = nBytes / sizeof(datum);

    datum pattern;
    datum antipattern;


    /*
     * Fill memory with a known pattern.
     */
    for (pattern = 1, offset = 0; offset < nWords; pattern++, offset++)
    {
        baseAddress[offset] = pattern;
    }

    /*
     * Check each location and invert it for the second pass.
     */
    for (pattern = 1, offset = 0; offset < nWords; pattern++, offset++)
    {
        // printf_("memTestDevice: %i, address %p, actual 0x%x expected 0x%x\n", offset, &baseAddress[offset], baseAddress[offset], pattern);
        if (baseAddress[offset] != pattern)
        {
            printf_("memTestDevice Error0 Offset: 0x%x, address %p, actual 0x%x expected 0x%x\n", offset, &baseAddress[offset], baseAddress[offset], pattern);
            // return ((datum *)&baseAddress[offset]);
        }

        antipattern = ~pattern;
        baseAddress[offset] = antipattern;
    }

    /*
     * Check each location for the inverted pattern and zero it.
     */
    for (pattern = 1, offset = 0; offset < nWords; pattern++, offset++)
    {
        antipattern = ~pattern;
        if (baseAddress[offset] != antipattern)
        {
            printf_("memTestDevice Error1 Offset: %i\n", offset);
            return ((datum *)&baseAddress[offset]);
        }
    }
    printf_("memTestDevice PASSED\n");
    return (0); // NULL

}   /* memTestDevice() */

int memTest(void)
{
#define BASE_ADDRESS  (volatile datum *) 0x60000000
#define NUM_BYTES     (1 * 1024) // 1KB

    if ((memTestDataBus(BASE_ADDRESS) != 0) ||
        (memTestAddressBus(BASE_ADDRESS, NUM_BYTES) != 0) ||
        (memTestDevice(BASE_ADDRESS, NUM_BYTES) != 0))
    {
        return (-1);
    }
    else
    {
        return (0); // NULL
    }

}   /* memTest() */

#endif // _MEMTEST_H