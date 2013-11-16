
SHELL := /bin/zsh

TARGET:=Demo
#TOOLCHAIN_PATH:=~/sat/bin
TOOLCHAIN_PREFIX:=arm-none-eabi
OPTLVL:=3 # Optimization level, can be [0, 1, 2, 3, s].

#PROJECT_NAME:=$(notdir $(lastword $(CURDIR)))
# TOP:=$(shell readlink -f "../..")
DISCOVERY:=$(STMSDKDIR)/Utilities/STM32F4-Discovery
STMLIB:=$(STMSDKDIR)/Libraries
STD_PERIPH:=$(STMLIB)/STM32F4xx_StdPeriph_Driver
STARTUP:=$(STMLIB)/CMSIS/ST/STM32F4xx/Source/Templates/gcc_ride7
LINKER_SCRIPT:=$(CURDIR)/TrueSTUDIO/STM32F4-Discovery_Demo/stm32_flash.ld
#LINKER_SCRIPT:=$(CURDIR)/../stm32_flash.ld


INCLUDE=-I$(CURDIR)
INCLUDE+=-I$(STMLIB)/CMSIS/Include
INCLUDE+=-I$(STMLIB)/CMSIS/ST/STM32F4xx/Include
INCLUDE+=-I$(STD_PERIPH)/inc
INCLUDE+=-I$(DISCOVERY)
INCLUDE+=-I$(STMLIB)/STM32_USB_OTG_Driver/inc
INCLUDE+=-I$(STMLIB)/STM32_USB_Device_Library/Class/hid/inc
INCLUDE+=-I$(STMLIB)/STM32_USB_Device_Library/Core/inc

# vpath is used so object files are written to the current directory instead
# of the same directory as their source files
vpath %.c $(DISCOVERY) $(STD_PERIPH)/src \
          $(STMLIB)/STM32_USB_OTG_Driver/src \
          $(STMLIB)/STM32_USB_Device_Library/Class/hid/src \
          $(STMLIB)/STM32_USB_Device_Library/Core/src
vpath %.s $(STARTUP)

ASRC=startup_stm32f4xx.s

# Project Source Files
SRC=selftest.c
SRC+=stm32f4xx_it.c
SRC+=system_stm32f4xx.c
SRC+=usb_bsp.c
SRC+=usbd_desc.c
SRC+=usbd_usr.c
SRC+=main.c

# Discovery Source Files
SRC+=stm32f4_discovery_lis302dl.c
SRC+=stm32f4_discovery.c
SRC+=stm32f4_discovery_audio_codec.c

# Standard Peripheral Source Files
SRC+=stm32f4xx_syscfg.c
SRC+=misc.c
SRC+=stm32f4xx_adc.c
SRC+=stm32f4xx_dac.c
SRC+=stm32f4xx_dma.c
SRC+=stm32f4xx_exti.c
SRC+=stm32f4xx_flash.c
SRC+=stm32f4xx_gpio.c
SRC+=stm32f4xx_i2c.c
SRC+=stm32f4xx_rcc.c
SRC+=stm32f4xx_spi.c
SRC+=stm32f4xx_tim.c

# USB Source Files
SRC+=usb_dcd_int.c
SRC+=usb_core.c
SRC+=usb_dcd.c
SRC+=usbd_hid_core.c
SRC+=usbd_req.c
SRC+=usbd_core.c
SRC+=usbd_ioreq.c

CDEFS=-DUSE_STDPERIPH_DRIVER
CDEFS+=-DSTM32F4XX
CDEFS+=-DMANGUSTA_DISCOVERY
CDEFS+=-DUSE_USB_OTG_FS
CDEFS+=-DHSE_VALUE=8000000

MCUFLAGS=-mcpu=cortex-m4 -mthumb
#MCUFLAGS=-mcpu=cortex-m4 -mthumb -mlittle-endian -mfpu=fpa -mfloat-abi=hard -mthumb-interwork
#MCUFLAGS=-mcpu=cortex-m4 -mfpu=vfpv4-sp-d16 -mfloat-abi=hard
COMMONFLAGS=-O$(OPTLVL) -g -Wall
CFLAGS=$(COMMONFLAGS) $(MCUFLAGS) $(INCLUDE) $(CDEFS)

LDLIBS=
LDFLAGS=$(COMMONFLAGS) -fno-exceptions -ffunction-sections -fdata-sections \
        -nostartfiles -Wl,--gc-sections,-T$(LINKER_SCRIPT)

#####
#####

OBJ = $(SRC:%.c=%.o) $(ASRC:%.s=%.o)

CC=$(TOOLCHAIN_PREFIX)-gcc
LD=$(TOOLCHAIN_PREFIX)-gcc
OBJCOPY=$(TOOLCHAIN_PREFIX)-objcopy
AS=$(TOOLCHAIN_PREFIX)-as
AR=$(TOOLCHAIN_PREFIX)-ar
GDB=$(TOOLCHAIN_PREFIX)-gdb

#-include jenn.mk

Demo.bin: $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LDLIBS)
	$(OBJCOPY) -O ihex $@ $(TARGET).hex
	$(OBJCOPY) -O binary $@ $(TARGET).bin

all: $(TARGET)

.PHONY: clean

clean:
	rm -f $(OBJ)
	rm -f $(TARGET).elf
	rm -f $(TARGET).hex
	rm -f $(TARGET).bin

flash: $(TARGET).bin
	echo -ne "reset halt\nflash write_image erase $$(PWD)/$< 0x08000000 bin\nreset run\nexit\n" | nc localhost 4444
