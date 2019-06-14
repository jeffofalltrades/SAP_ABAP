*&---------------------------------------------------------------------*
*&      Form  base_n_increment
*&---------------------------------------------------------------------*
*       form increments the base36 value passed to it.
*----------------------------------------------------------------------*
*       <-> p_value base 36 value in string format to be incremented by
*           1 by this form.
*       --> p_base for taking in the value of the desired base
*       --> p_length for taking in the length of the desired string
*----------------------------------------------------------------------*
FORM base_n_increment USING p_length TYPE i
                            p_base   TYPE i
                   CHANGING p_value  TYPE string.

  "DATA Declarations
  DATA :  lv_123abc           TYPE    string, "String of characters used in Base36(offset = integer value)
          lv_result           TYPE    string, "string for storing incremented value in
          lv_isremainder(1)   TYPE    c,      "flag for remainders
          lv_isfirst(1)       TYPE    c,      "bool for first run through
          lv_index            TYPE    i,      "index for while loop
          lv_current_char(1)  TYPE    c,      "current character in the string being referenced
          lv_current_int      TYPE    i.      "converted int of current char being referenced


  "initialization
  lv_123abc       = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
  lv_isremainder  = ' '.
  lv_isfirst      = 'X'.

  "set index to p_value - 1 to handle offset
  lv_index = STRLEN( p_value ) - 1.


  WHILE lv_index >= 0.

    "get character to evaluate
    lv_current_char = p_value+lv_index(1).

    "get the index of the character and store
    SEARCH lv_123abc FOR lv_current_char.
    lv_current_int = sy-fdpos.

    "if the current int is out of range of the base throw and error
    IF lv_current_int >= p_base.
      MESSAGE e398(00) WITH 'Number passed was out of range of base.'.
    ENDIF.

    "increment the integer value by 1
    IF lv_isfirst = 'X'.
      lv_isfirst = ' '.
      lv_current_int = lv_current_int + 1.
    ENDIF.

    "check remainder flag and increment by 1 if true
    IF lv_isremainder = 'X'.
      lv_isremainder = ' '.
      lv_current_int = lv_current_int + 1.
    ENDIF.

    "check if out of range of base after remainder add
    "subtract base and set remainder flag
    IF lv_current_int >= p_base.
      lv_isremainder = 'X'.
      lv_current_int = lv_current_int - p_base.
    ENDIF.

    "convert the int back to a character
    lv_current_char = lv_123abc+lv_current_int(1).

    "concatenate the chracter onto front of result string
    CONCATENATE lv_current_char lv_result INTO lv_result.

    lv_index = lv_index - 1.
   
  ENDWHILE.

  "if remainder still exists then there is string overrun
  IF lv_isremainder = 'X'.
    MESSAGE e398(00) WITH 'Serial number overrun.'.
  ENDIF.

  "add leading zeros to string
  WHILE STRLEN( lv_result ) < p_length.
    CONCATENATE '0' lv_result INTO lv_result.
  ENDWHILE.

  "return result
  p_value = lv_result.

ENDFORM.                    "base_n_increment