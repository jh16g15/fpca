#ifndef PRINTF_CONFIG_H_
#define PRINTF_CONFIG_H_

#define PRINTF_SUPPORT_DECIMAL_SPECIFIERS       0       // %f, %F           support float/double
#define PRINTF_SUPPORT_EXPONENTIAL_SPECIFIERS   0       // %e, %E, %g, %G   support scientific notation
#define PRINTF_SUPPORT_WRITEBACK_SPECIFIER      0       // %n               support intermediate "chars written" outupt
#define PRINTF_SUPPORT_MSVC_STYLE_INTEGER_SPECIFIERS 0  // %I32, %I8 etc    support integer bit size specifiers
#define PRINTF_SUPPORT_LONG_LONG                0       // %ll              support long long printing (affects %p as well)

#define PRINTF_ALIAS_STANDARD_FUNCTION_NAMES_SOFT    0  // alias printf() etc to use instead of printf_() etc
#define PRINTF_ALIAS_STANDARD_FUNCTION_NAMES_HARD    0

#define PRINTF_INTEGER_BUFFER_SIZE              32
#define PRINTF_DECIMAL_BUFFER_SIZE              32
#define PRINTF_DEFAULT_FLOAT_PRECISION          6
#define PRINTF_MAX_INTEGRAL_DIGITS_FOR_DECIMAL  9
#define PRINTF_LOG10_TAYLOR_TERMS               4
#define PRINTF_CHECK_FOR_NUL_IN_FORMAT_SPECIFIER 1  // optional safety check for terminated string formats

#endif // PRINTF_CONFIG_H_

