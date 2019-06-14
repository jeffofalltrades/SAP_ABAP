REPORT ZLISTBOX.
types: begin of t_ekko,
  ebeln type ekko-ebeln,
  end of t_ekko.
data: it_ekko TYPE STANDARD TABLE OF t_ekko,
      wa_ekko like line of it_ekko.

TYPE-POOLS: VRM.
DATA: NAME  TYPE VRM_ID,
      LIST  TYPE VRM_VALUES,
      VALUE LIKE LINE OF LIST.

PARAMETERS: P_PARM(10) AS LISTBOX VISIBLE LENGTH 10.

****************************************************
*AT SELECTION-SCREEN OUTPUT.
AT SELECTION-SCREEN OUTPUT.

  SELECT ebeln
   up to 10 rows
    from ekko
    into table it_ekko.

  loop at it_ekko into wa_ekko.
    VALUE-KEY =  wa_ekko-ebeln.
    VALUE-TEXT = wa_ekko-ebeln.
    APPEND VALUE TO LIST.
  endloop.

  NAME = 'P_PARM'.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      ID     = NAME
      VALUES = LIST.

********************************************************
*START-OF-SELECTION.
START-OF-SELECTION.
  WRITE: / 'SELECTED VALUE KEY:', P_PARM.