##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine
##  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU Lesser General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU Lesser General Public License for more details.
##
##  You should have received a copy of the GNU Lesser General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##------------------------------------------------------------------------------

#################
# CARTRIDGE module: cartridge (.cpr) of the CPC Plus / GX4000
#   Commands of the front-end macro CARTRIDGE (see cfg/cartridge.mk):
#     ADD_BANK_FILE : add a file at the end of a bank (1-31). The files of a bank are put one after
#                     the other, in the order of the commands. An error stops the build if they do not fit.
#                     Optional 3rd argument LOWER: the file is read by the lower ROM, so its bank must be 1-7
#                     (checked); UPPER (or nothing): any bank
#     SET_HEADER    : C header where the place of each file is written (bank, offset, size)
#   The bank 0 is the reset and the boot (first 256 bytes of the binary, from the crt0 of the cartridge), then
#   the program of the project at 0x0100 (copied to the RAM by the boot at Z80CODELOC).
#   The crt0 (CART_CRT0, in build_config.mk) is assembled here and linked first with the program.
#   A project builds a cartridge when build_config.mk defines CPR (CPR := $(PROJNAME).cpr, TARGET := $(CPR)).
#   The banks are 16 KB, 32 at most. The file CPR is $(CPR), in build_config.mk
#################
.SECONDEXPANSION:

CART_BANK_SIZE   := 16384
CART_VALID_BANKS := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
CART_LOWER_BANKS := 1 2 3 4 5 6 7
# The crt0 is a file of the project (it is not in src/: it would be compiled twice and not linked first)
CART_CRT0_SRC    ?= cart/cpct_cart_crt0.s
CART_HEADER      :=
CART_MKCART      ?= $(CPCT_PATH)/tools/scripts/cpct_mkcart
CART_FILES_ARGS  :=
CART_ALL_FILES   :=

#################
# ADD_BANK_FILE: Add a file at the end of a bank
# $(1): File
# $(2): Bank (1-31)
# $(3): Optional window the file is read from: LOWER (lower ROM, bank must be 1-7) or UPPER (any bank)
#################
define CARTRIDGE_ADD_BANK_FILE
    $(if $(filter $(2),$(CART_VALID_BANKS)),,$(error <<ERROR>> [CARTRIDGE] '$(2)' is not a valid bank for '$(1)': 1-31 (the bank 0 is the boot and the program)))
    $(if $(filter-out LOWER UPPER,$(3)),$(if $(strip $(3)),$(error <<ERROR>> [CARTRIDGE] '$(3)' is not a valid ROM for '$(1)': LOWER or UPPER)))
    $(if $(filter LOWER,$(3)),$(if $(filter $(2),$(CART_LOWER_BANKS)),,$(error <<ERROR>> [CARTRIDGE] '$(1)' is read by the lower ROM: bank '$(2)' must be 1-7)))
    CART_FILES_ARGS += $(2):$(1)
    CART_ALL_FILES  += $(1)
endef

#################
# SET_HEADER: C header with the place of each file
# $(1): Header file
#################
# The header is made before the C files are compiled (they include it)
define CARTRIDGE_SET_HEADER
    CART_HEADER := $(1)
$(1): $$$$(CART_ALL_FILES) cfg/cartridge.mk
	@$$(CART_MKCART) -n -H "$(1)" -w "$$(OBJDIR)/cart" $$(CART_FILES_ARGS)
$$(C_OBJFILES): $(1)
endef

#################
# CARTRIDGE: Front-end macro
#################
define CARTRIDGE
# Set the list of valid commands
$(eval CARTRIDGE_F_FUNCTIONS := ADD_BANK_FILE SET_HEADER)

# Check that command parameter ($(1)) is exactly one-word
$(call ENSURE_SINGLE_VALUE,$(1),<<ERROR>> [CARTRIDGE] '$(strip $(1))' is not a valid command.)

# Filter given command
$(eval CARTRIDGE_F_SF = $(filter $(CARTRIDGE_F_FUNCTIONS),$(1)))

# If the given command is valid, we execute its definition immediately
$(if $(CARTRIDGE_F_SF)\
	,$(eval $(call CARTRIDGE_$(CARTRIDGE_F_SF),$(strip $(2)),$(strip $(3)),$(strip $(4))))\
	,$(error <<ERROR>> [CARTRIDGE] '$(strip $(1))' is not a valid command. Valid commands: {$(CARTRIDGE_F_FUNCTIONS)}))
endef

#################
# Recipe: the cartridge (the files of the banks are known when this rule is expanded)
#################
ifneq ($(strip $(CPR)),)
# The crt0 of the cartridge: assembled, and linked first with the program
$(CART_CRT0): $$(CART_CRT0_SRC)
	@mkdir -p $(dir $@)
	$(Z80ASM) -g $(Z80ASMFLAGS) $@ $<

$(IHXFILE): $(CART_CRT0)

$(CPR): $(BINFILE) $$(CART_ALL_FILES) cfg/cartridge.mk
	@$(call PRINT,$(PROJNAME),"Creating cartridge '$(CPR)'")
	@$(CART_MKCART) -r "$(RASM)" -o "$(CPR)" -p "$(BINFILE)" -a "$(Z80CODELOC)" \
	    $(if $(CART_HEADER),-H "$(CART_HEADER)") -w "$(OBJDIR)/cart" $(CART_FILES_ARGS)
	@$(call PRINT,$(PROJNAME),"Cartridge '$(CPR)' ready")

OBJS2CLEAN += $(OBJDIR)/cart $(CPR)
endif