
*&---------------------------------------------------------------------*
*&      Form  LOCK_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0026   text
*----------------------------------------------------------------------*
FORM lock_table  USING p_tabname
                       p_location.

  DATA:    lv_varkey LIKE rstable-varkey.

  concatenate
    sy-mandt
    p_location
  into lv_varkey separated by ' '.

  CALL FUNCTION 'ENQUEUE_E_TABLE'
   EXPORTING
*   MODE_RSTABLE         = 'E'
     tabname              = p_tabname
     varkey               = lv_varkey
*   X_TABNAME            = ' '
*   X_VARKEY             = ' '
*   _SCOPE               = '2'
*   _WAIT                = ' '
*   _COLLECT             = ' '
* EXCEPTIONS
*   FOREIGN_LOCK         = 1
*   SYSTEM_FAILURE       = 2
*   OTHERS               = 3
            .
  IF sy-subrc <> 0.
    MESSAGE e398(00) WITH 'Unable to lock ZSERIAL' RAISING unable_to_lock_table.
    EXIT.

* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.                    " LOCK_TABLE









*&---------------------------------------------------------------------*
*&      Form  UNLOCK_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0104   text
*----------------------------------------------------------------------*
FORM unlock_table  USING p_tabname
                         p_location.
  DATA:    lv_varkey LIKE rstable-varkey.

  concatenate
    sy-mandt
    p_location
  into lv_varkey separated by ' '.

  CALL FUNCTION 'DEQUEUE_E_TABLE'
   EXPORTING
*   MODE_RSTABLE       = 'E'
      tabname            = p_tabname
      varkey             = lv_varkey
*   X_TABNAME          = ' '
*   X_VARKEY           = ' '
*   _SCOPE             = '3'
*   _SYNCHRON          = ' '
*   _COLLECT           = ' '
            .

ENDFORM.                    " UNLOCK_TABLE



