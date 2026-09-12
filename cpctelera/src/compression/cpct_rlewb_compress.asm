;;-----------------------------LICENSE NOTICE------------------------------------
;;  This file is part of CPCtelera: An Amstrad CPC Game Engine 
;;  Copyright (C) 2026 ronaldo / Fremos / Cheesetea / ByteRealms (@FranGallegoBR)
;;  Copyright (C) 2026 Arnaud Bouche (@Arnaud6128)
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU Lesser General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU Lesser General Public License for more details.
;;
;;  You should have received a copy of the GNU Lesser General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;-------------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: cpct_rlewb_compress
;;
;;   Compresses uncompressed input data into Wonder Boy RLE (RLEWB) stream format.
;;
;; Input Parameters:
;;   (2B HL) src    - Pointer to uncompressed source data
;;   (2B DE) dst    - Pointer to destination buffer for compressed stream
;;   (2B BC) length - Length of input data to compress (in bytes, up to 65535)
;;
;; Return Value:
;;   (2B DE) Compressed length in bytes (SDCC __sdcccall(1))
;;   (2B HL) Compressed length in bytes (Standard ASM)
;;
;; Destroyed Register values: 
;;   AF, BC, DE, HL
;;   (IX is preserved)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    push ix                     ;; [4] Préserver IX (requis par les conventions SDCC)
    push de                     ;; [3] Sauvegarder le pointeur dst initial

main_loop$:
    ;; Vérifier si le compteur 16 bits est épuisé (BC == 0 ?)
    ld   a, b                   ;; [1]
    or   c                      ;; [1]
    jr   z, end_compression$    ;; [2/3]

    ;; Consommer le premier octet de la nouvelle séquence
    ld   a, (hl)                ;; [2] A = valeur courante
    inc  hl                     ;; [2]
    dec  bc                     ;; [2]
    ld__ixl_a                   ;; [2] IXL = val
    ld__ixh #1                  ;; [3] IXH = run_length = 1

count_loop$:
    ;; Reste-t-il des octets dans le tampon source ?
    ld   a, b                   ;; [1]
    or   c                      ;; [1]
    jr   z, count_done$         ;; [2/3]

    ;; Limite maximale RLEWB par bloc (254 répétitions)
    ld__a_ixh                  ;; [2]
    cp   #254                   ;; [2]
    jr   z, count_done$         ;; [2/3]

    ;; Comparaison avec l'octet suivant
    ld   a, (hl)                ;; [2]
    cp__ixl                    ;; [2] Compare avec IXL (val)
    jr   nz, count_done$        ;; [2/3] Valeur différente -> séquence terminée

    ;; Octet identique validé
    inc  hl                     ;; [2]
    dec  bc                     ;; [2]
    inc__ixh                   ;; [2] run_length++
    jr   count_loop$            ;; [3]

count_done$:
    ;; Décision selon la valeur de l'octet et sa répétition
    ld__a_ixl                   ;; [2] A = val
    cp   #0x80                  ;; [2] Est-ce le Control Digit (0x80) ?
    jr   z, write_cd$           ;; [2/3]

    ;; ---------------------------------------------------------
    ;; Cas 1 : Octet normal (val != 0x80)
    ;; ---------------------------------------------------------
    ld__a_ixh                   ;; [2] A = run_length
    cp   #4                     ;; [2] Rentable en RLEWB seulement à partir de 4 octets
    jr   c, write_raw$          ;; [2/3] Si < 4 -> sortie directe en octets bruts

    ;; RLE : 0x80, [run_length], [val]
    ld   a, #0x80               ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    ld__a_ixh                  ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    ld__a_ixl                  ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    jr   main_loop$             ;; [3]

write_raw$:
    ;; Écriture de 1 à 3 octets bruts (consomme run_length sans toucher à BC)
    ld__a_ixl                  ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    dec__ixh                   ;; [2]
    jr   nz, write_raw$         ;; [2/3]
    jr   main_loop$             ;; [3]

    ;; ---------------------------------------------------------
    ;; Cas 2 : Octet d'échappement (val == 0x80)
    ;; ---------------------------------------------------------
write_cd$:
    ld   a, #0x80               ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    ld__a_ixh                  ;; [2] A = run_length
    cp   #1                     ;; [2]
    jr   z, write_cd_isolated$  ;; [2/3]

    ;; 0x80 répété : 0x80, [run_length], 0x80
    ld   (de), a                ;; [2] Écrit run_length
    inc  de                     ;; [2]
    ld   a, #0x80               ;; [2]
    ld   (de), a                ;; [2] Écrit 0x80
    inc  de                     ;; [2]
    jr   main_loop$             ;; [3]

write_cd_isolated$:
    ;; 0x80 isolé : 0x80, 0x00
    xor  a                      ;; [1]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    jr   main_loop$             ;; [3]

    ;; ---------------------------------------------------------
    ;; Marqueur de fin de flux
    ;; ---------------------------------------------------------
end_compression$:
    ;; Marqueur de fin RLEWB : 0x80, 0xFF
    ld   a, #0x80               ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]
    ld   a, #0xFF               ;; [2]
    ld   (de), a                ;; [2]
    inc  de                     ;; [2]

    ;; Calcul de la longueur totale compressée = DE final - DE initial
    pop  bc                     ;; [3] BC = dst initial
    ld   a, e                   ;; [1]
    sub  c                      ;; [1]
    ld   l, a                   ;; [1]
    ld   a, d                   ;; [1]
    sbc  a, b                   ;; [1]
    ld   h, a                   ;; [1] HL = taille compressée

    ;; Retour double : DE pour __sdcccall(1), HL pour les appels ASM
    ld   d, h                   ;; [1]
    ld   e, l                   ;; [1] DE = taille compressée

    pop  ix                     ;; [4] Restaurer IX
    ret                         ;; [3]