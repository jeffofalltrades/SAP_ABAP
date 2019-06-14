************************************************************************
*                  S E L E C T  -  O P T I O N S                       *
*                       P A R A M E T E R S                            *
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK selectfields WITH FRAME TITLE text-sec.
SELECTION-SCREEN SKIP.
PARAMETERS:     p_sales RADIOBUTTON GROUP cond USER-COMMAND push DEFAULT 'X'.
SELECTION-SCREEN BEGIN OF BLOCK sales.
SELECT-OPTIONS: s_svkorg FOR knvv-vkorg,
                s_svtweg FOR knvv-vtweg.
SELECTION-SCREEN END OF BLOCK sales.

SELECTION-SCREEN SKIP.
PARAMETERS:     p_purch RADIOBUTTON GROUP cond.
SELECTION-SCREEN BEGIN OF BLOCK purch.
SELECT-OPTIONS: s_pekorg FOR lfm1-ekorg.
SELECTION-SCREEN END OF BLOCK purch.

SELECTION-SCREEN SKIP.
PARAMETERS:     p_other RADIOBUTTON GROUP cond.
SELECTION-SCREEN BEGIN OF BLOCK other.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 5.
PARAMETERS:     p_cdtail RADIOBUTTON GROUP grp1.
SELECTION-SCREEN COMMENT 7(30) text-det.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 5.
PARAMETERS:     p_cheadr RADIOBUTTON GROUP grp1.
SELECTION-SCREEN COMMENT 7(30) text-hed.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN ULINE /5(20).
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 5.
PARAMETERS:     p_cprcng RADIOBUTTON GROUP grp2.
SELECTION-SCREEN COMMENT 7(30) text-prc.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 5.
PARAMETERS:     p_cdeals RADIOBUTTON GROUP grp2.
SELECTION-SCREEN COMMENT 7(30) text-dea.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK other.
SELECTION-SCREEN SKIP.
* detailed selection critera for "Other Conditions"
SELECTION-SCREEN BEGIN OF BLOCK soptions WITH FRAME TITLE text-oth.
SELECT-OPTIONS: s_oaedat FOR kona-aedat,
                s_oerdat FOR kona-erdat,
                s_oernam FOR kona-ernam,
                s_ovkorg FOR kona-vkorg,
                s_ovtweg FOR kona-vtweg,
                s_ospart FOR kona-spart,
                s_odeals FOR kona-knuma,
                s_ovkbur FOR kona-vkbur,
                s_ovkgrp FOR kona-vkgrp.
SELECTION-SCREEN END OF BLOCK soptions.
* detailed selection criteria for "Sales Condition" and "Purchase Condition"
SELECTION-SCREEN BEGIN OF BLOCK coptions WITH FRAME TITLE text-oth.
SELECT-OPTIONS: s_ckschl FOR konh-kschl,
                s_cudate FOR cdhdr-udate,
                s_cuname FOR cdhdr-username.
SELECTION-SCREEN END OF BLOCK coptions.

SELECTION-SCREEN END OF BLOCK selectfields.

************************************************************************
*               A T    S E L E C T I O N   S C R E E N                 *
************************************************************************
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
* to deal with radio button groups...
    CASE 'X'.                  " radio button is selected
      WHEN p_sales.
        IF screen-name CS 's_p'
        OR screen-name CS 'p_c'.
          screen-input = 0.    " make others gray
        ENDIF.
        IF screen-name CS 's_o'.
          screen-active = 0.    " don't show "other" details
        ENDIF.
        MODIFY SCREEN.
      WHEN p_purch.
        IF screen-name CS 's_s'
        OR screen-name CS 'p_c'
        OR screen-name CS 's_ck'.
          screen-input = 0.    " make others gray
        ENDIF.
        IF screen-name CS 's_o'.
          screen-active = 0.    " don't show "other" details
        ENDIF.
        MODIFY SCREEN.
      WHEN p_other.
        IF screen-name CS 's_p'
        OR screen-name CS 's_s'.
          screen-input = 0.    " make others gray
        ENDIF.
        IF screen-name CS 's_c'.
          screen-active = 0.    " don't show "other" details
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.