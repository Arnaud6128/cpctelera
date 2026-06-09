##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
##  Copyright (C) 2026 Arnaud BOUCHE (@Arnaud6128)
##------------------------------------------------------------------------------

.DEFAULT_GOAL := all

# Constants
SECTOR_TIMESTAMP := obj/.disk_sectors.timestamp
A2D_ERR          := <<ERROR>> [FILE2SECTOR -

# Script variables
DSK_INPUT := 
DATA_FILES_ARGS := 

# Target injection
inject_sectors: $(SECTOR_TIMESTAMP)

#################
# SET_DSK_FILE: Set destination disk
# $(1): Disk file
#################
define FILE2SECTOR_SET_DSK_FILE
    DSK_INPUT := $(1)
endef

#################
# ADD_DATA_FILE: Add file to write data to track/sector
# $(1): File
# $(2): Track/sector location
#################
define FILE2SECTOR_ADD_DATA_FILE
    # Add pair File / Disk location
    DATA_FILES_ARGS += $(1)|$(2)
endef

#################
# FILE2SECTOR: Front-end macro
#################
define FILE2SECTOR
# Set the list of valid commands
$(eval FILE2SECTOR_F_FUNCTIONS := SET_DSK_FILE ADD_DATA_FILE)

# Check that command parameter ($(1)) is exactly one-word
$(call ENSURE_SINGLE_VALUE,$(1),<<ERROR>> [FILE2SECTOR] '$(strip $(1))' is not a valid command.)

# Filter given command
$(eval FILE2SECTOR_F_SF = $(filter $(FILE2SECTOR_F_FUNCTIONS),$(1)))

# If the given command is valid, we execute its definition immediately
$(if $(FILE2SECTOR_F_SF)\
	,$(eval $(call FILE2SECTOR_$(FILE2SECTOR_F_SF),$(strip $(2)),$(strip $(3))))\
	,$(error <<ERROR>> [FILE2SECTOR] '$(strip $(1))' is not a valid command. Valid commands: {$(FILE2SECTOR_F_FUNCTIONS)}))
endef

#################
# Recipe: all
#################
run_disk_manager: $(SECTOR_TIMESTAMP)

.SECONDEXPANSION:
$(SECTOR_TIMESTAMP): cfg/disk_sector_manager.mk $$(DSK_INPUT)
	$(call ENSUREFILEEXISTS,$(1),$(A2D_ERR) CONVERT]: File '$(DSK_INPUT)' does not exist or is not readable.)
	
	@$(call PRINT,$(PROJNAME),"Adding data into $(DSK_INPUT) tracks...")
	@$(foreach item,$(DATA_FILES_ARGS),\
		item_str="$(item)"; \
		file=$$(echo $$item_str | cut -d'|' -f1); \
		args=$$(echo $$item_str | cut -d'|' -f2); \
		size=$$(stat -L -c %s $$file); \
		echo -e "\033[36mWriting file \033[0m$$file ($$size bytes)\033[36m to\033[0m $$args"; \
		command="$(RASM) -inline 'incbin \"$$file\": edsk writesect,\"${DSK_INPUT}\",0,$$,\"$$args\"'"; \
		eval $$command > obj/file2sector.log; \
	)
	@rm rasmoutput.bin -f
	@$(call PRINT,$(PROJNAME),"Adding data done")
	@touch $(SECTOR_TIMESTAMP)