

# Music (AKM player) as a binary relocated at 0x300 (RAM, copied from a bank of the cartridge), sound effects as assembly
$(eval $(call AKS2DATA, SET_FOLDER   , assets/ ))
$(eval $(call AKS2DATA, SET_OUTPUTS  , bin_file ))
$(eval $(call AKS2DATA, SET_PLAYER   , akm  ))
$(eval $(call AKS2DATA, CONVERT      , music/molusk.aks , music , 0x300))
$(eval $(call AKS2DATA, SET_FOLDER   , src/ ))
$(eval $(call AKS2DATA, SET_OUTPUTS  , s    ))
$(eval $(call AKS2DATA, SET_PLAYER   , fx   ))
$(eval $(call AKS2DATA, CONVERT      , music/sfx.aks , effects , ))
