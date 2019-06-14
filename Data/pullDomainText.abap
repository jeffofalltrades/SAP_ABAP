     CALL FUNCTION 'DOMAIN_VALUE_GET'
      EXPORTING
        I_DOMNAME  = wa_domname
        I_DOMVALUE = wa_domvalue
      IMPORTING
        E_DDTEXT   = wa_ddtext
      EXCEPTIONS
        NOT_EXIST  = 1
        OTHERS     = 2.
    if sy- subrc <> 0.
      wa_screen_error = c_true.
      message 'Reason Code is invalid' type 'E' .
    endif .