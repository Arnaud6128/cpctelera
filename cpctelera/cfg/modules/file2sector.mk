##-----------------------------LICENSE NOTICE------------------------------------
##  This file is part of CPCtelera: An Amstrad CPC Game Engine 
##  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
##  Copyright (C) 2026 Arnaud BOUCHE (@Arnaud6128)
##------------------------------------------------------------------------------

# Constants
# Time stamp tile
SECTOR_TIMESTAMP := .disk_sectors.timestamp
A2D_ERR          := <<ERROR>> [AKS2DATA -

# Script variables
DSK_INPUT := 
DATA_FILES_ARGS := 

#################
# SET_DSK_FILE: Set destination disk
# $(1): Disk file
#################
define FILE2SECTOR_SET_DSK_FILE
	# Ensure that DSK file exists
	$(call ENSUREFILEEXISTS,$(1),$(A2D_ERR) CONVERT]: File '$(1)' does not exist or is not readable)
    DSK_INPUT := $(1)
endef

#################
# ADD_DATA_FILE: Add file to write data to track/sector
# $(1): File
# $(2): Track/sector location
#################
define FILE2SECTOR_ADD_DATA_FILE
    # Add pair file / location
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
all: $(SECTOR_TIMESTAMP)
$(SECTOR_TIMESTAMP): cfg/disk_sector_manager.mk

	@$(call PRINT,$(PROJNAME),"Adding data into $(DSK_INPUT) tracks...")	
	$(eval command:=)	
	@$(foreach item,$(DATA_FILES_ARGS),\
		item_str="$(item)"; \
		file=$$(echo $$item_str | cut -d'|' -f1); \
		args=$$(echo $$item_str | cut -d'|' -f2); \
		echo -e "\033[36mWriting file data $$file to $$args\033[0m"; \
		command="$(RASM) -inline 'incbin \"$$file\": edsk writesect,\"${DSK_INPUT}\",0,$$,\"$$args\"'"; \
		eval $$command > /dev/null; \
	)
	@$(call PRINT,$(PROJNAME),"Done")
	@touch $(SECTOR_TIMESTAMP)