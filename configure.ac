AC_PREREQ([2.69])
AC_INIT([lvbs], [0.1], [snambakam@microsoft.com])
AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_CONFIG_HEADERS([include/config.h])
AC_CONFIG_MACRO_DIR([m4])

# Checks for programs
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LIBTOOL

# Check for ioctl headers
AC_CHECK_HEADERS([sys/ioctl.h ioctl.h])

# Configure output
AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/cli/Makefile
])
AC_OUTPUT
