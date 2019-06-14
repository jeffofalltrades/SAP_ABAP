*&---------------------------------------------------------------------*
*&      Form  SETUP_DATES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_V_FIRST_OF_MONTH  text
*      -->P_V_END_OF_MONTH  text
*----------------------------------------------------------------------*
FORM setup_dates  USING    pv_first_of_month
                           pv_end_of_month.
  "set end_of_month to current date
  pv_end_of_month  = sy-datum.
  "substitue in 01 for the date segement. That gives first of current month
  pv_end_of_month+6(2) = '01'.
  "set the end of month to end of month (which
  "again is current month) minus 1 to get end of last month
  pv_end_of_month = pv_end_of_month - 1.
  "set fist of month = to end of month and replace date with 01
  pv_first_of_month = pv_end_of_month.
  pv_first_of_month+6(2) = '01'.
ENDFORM.                    " SETUP_DATES