DATA: it_raw           TYPE          truxs_t_text_data.


  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
*     I_FIELD_SEPERATOR          =
*     I_LINE_HEADER              =
      i_tab_raw_data             = it_raw"can be empty    type truxs_t_text_data
      i_filename                 = p_infile"filename like RLGRAP-FILENAME char limit 128
    TABLES
      i_tab_converted_data       = t_text"internal table with same number of columns as the excel file
*   EXCEPTIONS
*     CONVERSION_FAILED          = 1
*     OTHERS                     = 2
            .
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.