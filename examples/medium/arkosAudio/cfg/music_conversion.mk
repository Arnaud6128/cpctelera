# Default values
#$(eval $(call AKS2DATA, SET_FOLDER   , src/ ))
#$(eval $(call AKS2DATA, SET_OUTPUTS  , s    )) # { bin, s }
#$(eval $(call AKS2DATA, SET_PLAYER   , akg  )) # { akg, akm, fx }
#$(eval $(call AKS2DATA, SET_EXTRAPAR ,      )) 
# Conversion
#$(eval $(call AKS2DATA, EXECUTE , )) # must be set before last song
#$(eval $(call AKS2DATA, CONVERT      , music.aks , name , mem_address )) # mem_adress only for bin output

$(eval $(call AKS2DATA, SET_OUTPUTS  , s  )) 
$(eval $(call AKS2DATA, SET_PLAYER , akg )) 
$(eval $(call AKS2DATA, CONVERT , music/molusk.aks , music , ))
$(eval $(call AKS2DATA, SET_PLAYER , fx )) 
$(eval $(call AKS2DATA, CONVERT , music/sfx.aks , effects ,  ))
