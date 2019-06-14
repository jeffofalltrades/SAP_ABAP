FORM calculate_date  USING    p_umdat
                              p_webaz
                              p_werks
                     CHANGING p_umdat2.
  DATA: lv_fabkl   TYPE t001w-fabkl,
        lv_days    TYPE i VALUE 0,
        lv_alldays TYPE i VALUE 0,
        lv_date    TYPE sy-datum.

  lv_date = p_umdat.
  lv_days = p_webaz.

  SELECT SINGLE fabkl
    FROM t001w
    INTO lv_fabkl
    WHERE werks = p_werks.

  WHILE lv_days > 0.
    CALL FUNCTION 'DATE_CHECK_WORKINGDAY'
      EXPORTING
        date                       = lv_date
        factory_calendar_id        = lv_fabkl
        message_type               = 'I'
      EXCEPTIONS
        date_after_range           = 1
        date_before_range          = 2
        date_invalid               = 3
        date_no_workingday         = 4
        factory_calendar_not_found = 5
        message_type_invalid       = 6
        OTHERS                     = 7.
    IF sy-subrc = 4. "Not a working day
      lv_date = lv_date + 1.
    ELSE.
      lv_date = lv_date + 1.
      lv_days = lv_days - 1.
    ENDIF.
  ENDWHILE.

  DO.
    CALL FUNCTION 'DATE_CHECK_WORKINGDAY'
      EXPORTING
        date                       = lv_date
        factory_calendar_id        = lv_fabkl
        message_type               = 'I'
      EXCEPTIONS
        date_after_range           = 1
        date_before_range          = 2
        date_invalid               = 3
        date_no_workingday         = 4
        factory_calendar_not_found = 5
        message_type_invalid       = 6
        OTHERS                     = 7.
    IF sy-subrc = 4.
      lv_date = lv_date + 1.
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.

  p_umdat2 = lv_date.
ENDFORM.                    " CALCULATE_DATE