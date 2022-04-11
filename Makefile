## General Options
TARGET			=	out
OPT				=	0
SOURCE_DIR		=	src
MAIN_C			=	$(shell find $(SOURCE_DIR) -name 'main.c')
BUILD_DIR		=	build
OBJ_DIR			=	$(BUILD_DIR)/obj
TEST_DIR		=	test

## STM32 Options
CORE			=	cortex-m0plus
MCU				=	STM32G071xx		# TODO: Switch to G4!
LINKER_SCRIPT	=	drivers/STM32G071RBTx_FLASH.ld
CMSIS_DIR		=	drivers/CMSIS
STARTUP_C		=	$(CMSIS_DIR)/Device/ST/STM32G0xx/Source/Templates/system_stm32g0xx.c
STARTUP_ASM		=	$(CMSIS_DIR)/Device/ST/STM32G0xx/Source/Templates/gcc/startup_stm32g071xx.S

## Compiler options
CC		= arm-none-eabi-gcc
LD		= arm-none-eabi-gcc
AR		= arm-none-eabi-ar
AS		= arm-none-eabi-as
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE	= arm-none-eabi-size

## Compiler flags
CFLAGS	=	-O$(OPT) -g -Wall -Wextra
CFLAGS	+=	-fno-common -static
CFLAGS	+=	-ffunction-sections -fdata-sections -Wl,--gc-sections
CFLAGS	+=	-mcpu=$(CORE) -mthumb -D$(MCU)
CFLAGS	+=	-DDEVICE_SERIAL=1 -DDEVICE_SERIAL_FC=1
CFLAGS	+=	$(INC_FLAGS)

## Linker flags
LFLAGS	=	--specs=nosys.specs $(CFLAGS)
LFLAGS	+=	-T$(LINKER_SCRIPT)

###############################
# DO NOT EDIT BELOW THIS LINE #
###############################

## Include all directories with header files
INC_DIRS	:= 	$(shell find $(SOURCE_DIR) $(CMSIS_DIR) -name '*.h' -printf '%h\n')
INC_FLAGS	:=	$(addprefix -I, $(INC_DIRS))

## Source / object files
SRC				:= $(shell find $(SOURCE_DIR) -name '*.c')
OBJ 			:=	$(addprefix $(OBJ_DIR)/, $(SRC:.c=.o))
OBJ_STARTUP_C	=	$(OBJ_DIR)/startup/startup_c.o
OBJ_STARTUP_ASM	=	$(OBJ_DIR)/startup/startup_s.o

## Rules
#
## Converts the binary to a hex file
$(BUILD_DIR)/out.hex: $(BUILD_DIR)/out.elf
	$(PRINT_LINE)
	@echo "Creating target - $@"
	$(PRINT_LINE)
	$(OBJCOPY) -Oihex $< $@

## Links the object files together
$(BUILD_DIR)/out.elf: $(OBJ) $(OBJ_STARTUP_C) $(OBJ_STARTUP_ASM)
	@echo "Linking objects together with $(LINKER_SCRIPT) to - $@"
	$(CC) $(LFLAGS) $^ -o $@

## Compile user written files in src/
$(OBJ): $(OBJ_DIR)/%.o: %.c
	@echo "Compiling $<"
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

## Compile the startup.c file
$(OBJ_STARTUP_C): $(STARTUP_C)
	@echo "Compiling $<"
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

## Compile the startup.s file
$(OBJ_STARTUP_ASM): $(STARTUP_ASM)
	@echo "Compiling $<"
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

## Writes out '=' across the terminal
PRINT_LINE := printf "%`tput cols`s"|tr ' ' '=' && echo ""

## Use the flag VERBOSE=n to enable verbose outputs
ifndef VERBOSE
.SILENT:
endif

## Phony targets
.PHONY: clean

clean:
	@rm -rf $(BUILD_DIR)
	@echo Clean done

all: $(BUILD_DIR)/out.hex
