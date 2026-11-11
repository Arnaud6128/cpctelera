##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2015 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##------------------------------------------------------------------------------

###########################################################################
##                          CPCTELERA ENGINE                             ##
##                     Makefile for building SDCC                        ##
##-----------------------------------------------------------------------##
## This makefile configures & builds SDCC for z80 processor architecture ##
## In general, there is no need to make changes to this file.            ##
###########################################################################

# LOCATIONS
INSTALLDIRS=bin share
SRCDIR=src
SRCARCHIVE=sdcc-4.6.0.tar.gz
SRCSTAMP=.src_extracted
OBJDIR=obj
MAIN_MAKE=$(OBJDIR)/Makefile
TMP_MAIN_MAKE=$(OBJDIR)/Makefile.tmp.replace
SDBINUTILS_TAG=\(-C ..SDCC_SDBINUTILS.$$\)
SDBINUTILS_REPLACE=\1 MAKEINFO=true
CONFIG=configure_sdcc_for_z80.sh
TARGET=sdcc

## Function to replace a tag in a file with another information
##
##  $(1) Searched tag
##  $(2) Replacement
##  $(3) File where to search for the tag
##  $(4) Temporal file for operating
##
define replaceTag
	cat "$(3)" | sed "s/$(1)/$(2)/g" > $(4)
	mv "$(4)" "$(3)"
endef

# TARGETS
.PHONY: all clean cleanall $(TARGET) extract-src build-sdcc remove-src

# MAIN TARGET
all: $(TARGET)

# SDCC: $(SRCARCHIVE) holds the sources ($(SRCDIR)) and the files SDCC needs to work (share, libexec, peep).
# They are extracted for the build; once SDCC is installed only the sources and the build tree are removed:
# share, libexec and peep stay in place. If '$(SRCDIR)' already exists (extracted by hand), it is used and kept.
ifeq ($(wildcard $(SRCDIR)/configure)$(wildcard $(SRCARCHIVE)),)
ifneq ($(wildcard bin/sdcc bin/sdcc.exe),)
sdcc:
	@echo "SDCC is already installed and its sources are not available: nothing to build."
else
sdcc:
	$(error <<ERROR>> Neither '$(SRCARCHIVE)' nor '$(SRCDIR)' found: the sources of SDCC are missing)
endif
else
sdcc:
	@$(MAKE) --no-print-directory extract-src
	@$(MAKE) --no-print-directory build-sdcc
	@$(MAKE) --no-print-directory remove-src
endif

extract-src:
	@if [ ! -f "$(SRCDIR)/configure" ]; then \
	   echo "Extracting SDCC ($(SRCARCHIVE))..."; \
	   tar -xzf "$(SRCARCHIVE)" && touch "$(SRCSTAMP)" || { echo "Error extracting '$(SRCARCHIVE)'"; exit 1; }; \
	fi

build-sdcc:
	@echo "Configuring SDCC for z80..."
	cd $(SRCDIR) && ./$(CONFIG)
	@echo "Inserting MAKEINFO=true into main Makefile..."
	@$(call replaceTag,$(SDBINUTILS_TAG),$(SDBINUTILS_REPLACE),$(MAIN_MAKE),$(TMP_MAIN_MAKE))
	@echo "Compiling SDCC for z80..."
	$(MAKE) -C $(OBJDIR) 
	$(MAKE) -C $(OBJDIR) install MAKEINFO=true

# Sources and build tree are removed only if they were extracted by this makefile
remove-src:
	@if [ -f "$(SRCSTAMP)" ]; then \
	   echo "Removing the sources and the build tree of SDCC (share, libexec and peep are kept)..."; \
	   rm -rf "$(SRCDIR)" "$(OBJDIR)" "$(SRCSTAMP)"; \
	fi

# CLEANING TARGETS
cleanall: clean
	@echo "Removing install directories ($(INSTALLDIRS))..."
	@rm -rf $(INSTALLDIRS)
clean:
	@echo "Removing all object files..."
	-@$(MAKE) -C $(OBJDIR) distclean
	@rm -rf $(OBJDIR)
