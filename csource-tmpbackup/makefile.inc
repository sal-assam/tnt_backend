#Location of TNT
DIRTNT := /share/apps/tnt/mk_inc

#Specify include file to use, which will give main library and compiler options
include $(DIRTNT)/makefile_matnag.inc

# Specify the compilers to use and any additional compiler flags
CC := icc
FF := ifort

CFLAGS := $(LIBFLAGS)
FFLAGS := $(ALLLIBS)

# Extra flags for compiling OpenMP parallelism into TNT
CFLAGS += -DTNT_OMP -openmp
FFLAGS += -DTNT_OMP -openmp

MAKE := make
MKFLAGS =
