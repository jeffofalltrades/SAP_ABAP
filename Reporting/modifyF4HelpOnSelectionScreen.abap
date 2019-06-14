TYPES:  BEGIN OF ty_mtart,
          mtart TYPE mara-mtart,
          mtbez TYPE t134t-mtbez,
        END OF ty_mtart.
DATA:   t_mtart TYPE STANDARD TABLE OF ty_mtart.

INITIALIZATION.


  SELECT sign opt low high
    FROM zprog_fld_val
    INTO TABLE r_mtart
    WHERE prog_name = 'ZXMG0U02'
      AND fieldname = 'MTART_PRG'.

  SELECT mtart mtbez
    FROM t134t
    INTO TABLE t_mtart
    WHERE spras EQ sy-langu.

  DELETE t_mtart WHERE mtart NOT IN r_mtart.

AT SELECTION-SCREEN OUTPUT.
  IF sy-calld NE 'X'.
    CLEAR: p_charg, p_aufnr.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mtart-low.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'S_MTART'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'S_MTART-LOW'
      value       = 'S_MTART'
      value_org   = 'S'
    TABLES
      value_tab   = t_mtart.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mtart-high.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'S_MTART'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'S_MTART-HIGH'
      value       = 'S_MTART'
      value_org   = 'S'
    TABLES
      value_tab   = t_mtart.