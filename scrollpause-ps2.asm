; PET/CBM Editor ROM Project - Scroll Pause/Resume Control - B
; ==========================   SCROLLPAUSE-B.ASM
;
;--------------- Check Keyboard Scroll Control


.wait:

   	lda KEYFLAGS
    and #MOD_SCROLL
    bne .wait        ; If SCROLL key active, wait
    rts
