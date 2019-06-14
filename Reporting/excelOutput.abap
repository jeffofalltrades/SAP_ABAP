DATA: lo_excel    TYPE ole2_object,
        lo_workbook TYPE ole2_object,
        lo_sheet TYPE ole2_object,
        lo_cells TYPE ole2_object. 

FORM excel_create.
* Create Excel object
  CREATE OBJECT lo_excel 'EXCEL.APPLICATION'.
  SET PROPERTY OF lo_excel 'visible' = 0.
  CALL METHOD OF lo_excel 'Workbooks'= lo_workbook.
  CALL METHOD OF lo_workbook 'Add'.

* Create first Excel sheet
  CALL METHOD OF lo_excel 'Worksheets' = lo_sheet
    EXPORTING #1 = 1.                                                
  CALL METHOD OF lo_sheet 'Activate'.
  SET PROPERTY OF lo_sheet 'Name' = 'Sheet1'.

* Populate excel sheet
  PERFORM fill_cell USING 1 1 'test'.  "fill_cell -> Row Column Data

* Save and close the excel file
  SET PROPERTY OF lo_excel 'visible' = 0.
  SET PROPERTY OF lo_excel 'DisplayAlerts' = 0.

  CALL METHOD OF lo_sheet 'SaveAs'
    EXPORTING #1 = 'C:\Users\jacob.hancock\Desktop\excelTEST6.xls' "filename
              #2 = 1.                                             "fileformat

  CALL METHOD OF lo_excel 'QUIT'.
  FREE OBJECT: lo_excel, lo_sheet, lo_workbook, lo_cells.
ENDFORM.



FORM fill_cell USING i_row i_col i_val.
  CALL METHOD OF lo_sheet 'Cells' = lo_cells
    EXPORTING
      #1 = i_row
      #2 = i_col.
  SET PROPERTY OF lo_cells 'Value' = i_val.
ENDFORM. 

excelTEST6.xls
25.0 KB



Example in action using field catagory to generate output dynamically:

*&---------------------------------------------------------------------*
*&      Form  OUTPUT_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM output_excel .
  DATA: gv_directory TYPE string,
        lv_filename  TYPE string,
        lv_buffer    TYPE string,
        lv_row       TYPE i VALUE 1,
        wa_fieldcat LIKE LINE OF t_fieldcat,
        wa_list_item LIKE LINE OF list_item,
        lv_tot_col  TYPE i VALUE 0,
        ls_dd01v TYPE dd01v.

  FIELD-SYMBOLS <fs_buffer>.

  "call up the pop-up for user to determine directory
  CALL METHOD cl_gui_frontend_services=>directory_browse
    CHANGING
      selected_folder      = gv_directory
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc EQ 0.

    "create file name and directory
    CONCATENATE sy-tcode
                sy-datum
                sy-uzeit
                sd_saknr-low
                sd_bukrs-low
    INTO lv_filename SEPARATED BY space.
    CONCATENATE gv_directory '\' lv_filename
    INTO gv_directory.
    REPLACE ALL OCCURRENCES OF '\\' IN gv_directory WITH '\'.

* Create Excel object
    CREATE OBJECT go_excel 'EXCEL.APPLICATION'.
    SET PROPERTY OF go_excel 'visible' = 0.
    CALL METHOD OF go_excel 'Workbooks'= go_workbook.
    CALL METHOD OF go_workbook 'Add'.

* Create first Excel sheet
    CALL METHOD OF go_excel 'Worksheets' = go_sheet
      EXPORTING #1 = 1.
    CALL METHOD OF go_sheet 'Activate'.
    SET PROPERTY OF go_sheet 'Name' = 'Sheet1'.

* store header
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
      input  = sd_saknr-low
      IMPORTING
      output = sd_saknr-low.
    CONCATENATE 'G/L Account:' sd_saknr-low
    INTO lv_buffer SEPARATED BY space.
    PERFORM fill_cell USING lv_row 1 lv_buffer.
    ADD 1 TO lv_row.

    CONCATENATE 'Company Code:' sd_bukrs-low
    INTO lv_buffer SEPARATED BY space.
    PERFORM fill_cell USING lv_row 1 lv_buffer.
    ADD 1 TO lv_row.

    CONCATENATE stichtag+4(2) '/' stichtag+6(2) '/' stichtag+0(4)
    INTO lv_buffer.
    CONCATENATE 'As of Date:' lv_buffer
    INTO lv_buffer SEPARATED BY space.
    PERFORM fill_cell USING lv_row 1 lv_buffer.
    ADD 3 TO lv_row.



* Populate excel sheet

    "loop through the header texts
    LOOP AT t_fieldcat INTO wa_fieldcat WHERE tech IS INITIAL.
      "if the text is blank
      IF wa_fieldcat-seltext_l IS INITIAL.
        "select the data dictionary desription
        SELECT SINGLE scrtext_l
          FROM dd04t
          INTO lv_buffer
        WHERE rollname EQ wa_fieldcat-rollname
          AND ddlanguage EQ sy-langu
          AND as4local   = 'A'.
        IF sy-subrc EQ 0.
          PERFORM fill_cell USING lv_row
                                  wa_fieldcat-col_pos
                                  lv_buffer.
        ENDIF.
      "else just grab from fieldcat
      ELSE.
        PERFORM fill_cell USING lv_row
                                wa_fieldcat-col_pos
                                wa_fieldcat-seltext_l.
      ENDIF.
      CLEAR wa_fieldcat.
      ADD 1 TO lv_tot_col.
    ENDLOOP.
    ADD 1 TO lv_row.

    "start looping through data
    LOOP AT list_item INTO wa_list_item.

      "for each column
      DO lv_tot_col TIMES.
        "assign one column at a time to field symbol
        ASSIGN COMPONENT sy-index OF STRUCTURE wa_list_item
        TO <fs_buffer>.
        lv_buffer = <fs_buffer>.
        "store in sheet
        PERFORM fill_cell USING lv_row
                                sy-index
                                lv_buffer.
      ENDDO.

      CLEAR wa_list_item.
      ADD 1 TO lv_row.
    ENDLOOP.

* Save and close the excel file
    SET PROPERTY OF go_excel 'visible' = 0.
    SET PROPERTY OF go_excel 'DisplayAlerts' = 0.

    CALL METHOD OF go_sheet 'SaveAs'
      EXPORTING #1 = gv_directory
                #2 = 1.

    CALL METHOD OF go_excel 'QUIT'.
    FREE OBJECT: go_excel, go_sheet, go_workbook, go_cells.

    MESSAGE 'Output complete' TYPE 'S'.
  ENDIF.

ENDFORM.


FORM fill_cell USING i_row i_col i_val.
  CALL METHOD OF go_sheet 'Cells' = go_cells
    EXPORTING
      #1 = i_row
      #2 = i_col.
  SET PROPERTY OF go_cells 'Value' = i_val.
ENDFORM. 




