* I had a note in my old notes to "Ignore all the BDC junk" but I don't have a
* instance of SAP to run in to modify the code to remove it. I created this in 
* a hurry one time for an implementation project where approximately 15
* developers were all creating transports and sending stuff to QA to test. 
* We had a promotion plan document that wasn't getting updated (go figure,
* organizing developers and getting them to enter statuses in a Waterfall
* framework is like hearding cats in a yarn factory). So, the spreadsheet was 
* out of order out of whack and nobody was keeping track with dependencies. So,
* I made this. And provided them with the excel output from it. And they ignored
* it and continued to spend time trying to oraganize the spreadsheet based on 
* trial and error (mostly error). Soon after I rolled off the project and soon after
* that rolled out the door at the company I was working for. 
* Hopefully if you get to this program somehow and use it, the folks in charge will
* use what you export. 
* If you use it, please drop me a line and hit me with a pull request for any updates!

*&---------------------------------------------------------------------*
*& Report ZMDLC0004_SOURCE_LIST
*&---------------------------------------------------------------------*
* TITLE Source List BDC Conversion
* AUTHOR JMCDONALD (Jeff McDonald, RSI)
* DATE WRITTEN 06-NOV-12
* R/3 RELEASE ECC 6.0, RS6K900372
* VALIDATION DOC: <SAPxxxxxxxx>
*-----------------------------------------------------------------------------
*
*
*-----------------------------------------------------------------------------
* CHANGE HISTORY
* Date By Change label, Correction Number & Brief Description Release
* 06-NOV-12 JMCDONALD RD6K900586 Initial creation
******************************************************************************

REPORT zpmt_mic.
INCLUDE bdcrecxy.
TYPE-POOLS: icon .

************************************************************************
* T Y P E S *
************************************************************************
TYPES:
  BEGIN OF ty_batch,
  trkorr TYPE e070-trkorr,
  END OF ty_batch,

  BEGIN OF ty_output,
  as4user TYPE e070-as4user,
  trkorr TYPE e070-trkorr,
  as4text TYPE e07t-as4text,
  as4date TYPE e070-as4date,
  as4time TYPE e070-as4time,
  END OF ty_output.



************************************************************************
* D A T A D E F I N I T I O N *
************************************************************************
************************************************************************
* V A R I A B L E S *
************************************************************************


************************************************************************
* I N T E R N A L T A B L E S *
************************************************************************
DATA: t_input_tab TYPE alsmex_tabline OCCURS 0 WITH HEADER LINE,
  t_batch TYPE STANDARD TABLE OF ty_batch INITIAL SIZE 0,
  t_output TYPE STANDARD TABLE OF ty_output.

************************************************************************
* S T R U C T U R E S *
************************************************************************
DATA: w_batch TYPE ty_batch,
  w_output TYPE ty_output.

************************************************************************
* S E L E C T - O P T I O N S *
* P A R A M E T E R S *
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK input WITH FRAME TITLE text-200.
PARAMETERS: p_infile LIKE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN END OF BLOCK input .



************************************************************************
* S T A R T - O F - S E L E C T I O N *
************************************************************************
START-OF-SELECTION.
  PERFORM read_file. "read in the data
  PERFORM get_e070.
  PERFORM display_messages USING t_output."output errors and other messages

END-OF-SELECTION.

************************************************************************
* A T S E L E C T I O N - S C R E E N *
************************************************************************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infile.
  "handle matchcode button hit with open file dialog
  PERFORM open_dialog CHANGING p_infile.


************************************************************************
* S U P P O R T I N G S U B R O U T I N E S *
************************************************************************

*&---------------------------------------------------------------------*
*& Form OPEN_DIALOG
*&---------------------------------------------------------------------*
* Shows the user the file dialog for finding their file in a pop
* up window.
*----------------------------------------------------------------------*
* <-> i_file gives the open file dialog. Also sets the i_file
* value needed for the reading of data.
*----------------------------------------------------------------------*
FORM open_dialog CHANGING p_file TYPE rlgrap-filename.
  DATA l_infile TYPE string.


  "display the open file dialog
  CALL FUNCTION 'WS_FILENAME_GET'
  EXPORTING
  def_filename = '*.txt'
  def_path = p_file
* mask = i_mask
  mode = 'O'
* title = ''
  IMPORTING
  filename = p_file
  EXCEPTIONS
  inv_winsys = 04
  no_batch = 08
  selection_cancel = 12
  selection_error = 16.
  "display system message on error
  IF sy-subrc <> 0.
  "MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
  "WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "convert the file name to a string.
  l_infile = p_file.
  "use regex to test if file name ends in .txt
  "REGEX pattern: finds instance of '.txt' in the string. is escape character for .
  " $ looks at the end of the string. This verifies that the .txt is at the end of the string.
  FIND REGEX '$' IN l_infile.

  "sy-subrc won't equal 0 if pattern not found.
  IF sy-subrc <> 0.
  "clear the file selection fields so that user has to reselect
  CLEAR : p_infile, l_infile.
  "display message asking the user to select a new file in .txt format.
  "type I used due to error message causing errors since a pop up window is open at this time
  MESSAGE text-me1 TYPE 'I'.
  ENDIF.
ENDFORM. " OPEN_DIALOG
*&---------------------------------------------------------------------*
*& Form READ_FILE
*&---------------------------------------------------------------------*
* Reads in the tab delimited text document for use in the program.
*----------------------------------------------------------------------*
* --> filename used to direct to location of file to pull data from
* <-- t_batch fills it with the data needed for the
*----------------------------------------------------------------------*
FORM read_file.
  DATA: l_infile TYPE string.

  "convert the file path into a string as required by GUI_UPLOAD
  l_infile = p_infile.

  "get the data from the file located at l_infile and store in t_batch
  CALL FUNCTION 'GUI_UPLOAD'
  EXPORTING
  filename = l_infile
  filetype = 'ASC'
  has_field_separator = '#'
  TABLES
  data_tab = t_batch
  EXCEPTIONS
  file_open_error = 1
  file_read_error = 2
  no_batch = 3
  gui_refuse_filetransfer = 4
  invalid_type = 5
  no_authority = 6
  unknown_error = 7
  bad_data_format = 8
  header_not_allowed = 9
  separator_not_allowed = 10
  header_too_long = 11
  unknown_dp_error = 12
  access_denied = 13
  dp_out_of_memory = 14
  disk_full = 15
  dp_timeout = 16
  OTHERS = 17.
  "output system message on error
  IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 .
  ENDIF.
ENDFORM. " READ_FILE



*&---------------------------------------------------------------------*
*& Form DISPLAY_REPORT
*&---------------------------------------------------------------------*
* Display the ALV Grid
*----------------------------------------------------------------------*
* --> p_output takes in the file needed to output to ALV after report
* runs.
*----------------------------------------------------------------------*
FORM display_messages USING p_output.
  DATA: lcl_alv TYPE REF TO cl_salv_table.
*if the output table is not empty
  IF p_output IS NOT INITIAL .
  TRY.
  "create teh ALV object
  CALL METHOD cl_salv_table=>factory
  IMPORTING
  r_salv_table = lcl_alv
  CHANGING
  t_table = p_output.
  CATCH cx_salv_msg .
  ENDTRY .
*modify layout, columns, etc of the grid
  PERFORM modify_alv USING lcl_alv.
*Display the grid
  lcl_alv->display( ).
  ELSE.
  MESSAGE text-001 TYPE 'I'.
  ENDIF.
ENDFORM. " DISPLAY_REPORT
*&---------------------------------------------------------------------*
*& Form GET_E070
*&---------------------------------------------------------------------*
* text
*----------------------------------------------------------------------*
* --> p1 text
* <-- p2 text
*----------------------------------------------------------------------*
FORM get_e070 .

  LOOP AT t_batch INTO w_batch.
  CONDENSE w_batch-trkorr.
  MODIFY t_batch FROM w_batch.
  CLEAR w_batch.
  ENDLOOP.

  IF t_batch IS NOT INITIAL.
  SELECT trkorr
  as4date
  as4time
  as4user
  FROM e070
  INTO CORRESPONDING FIELDS OF TABLE t_output
  FOR ALL ENTRIES IN t_batch
  WHERE trkorr = t_batch-trkorr.

  LOOP AT t_output INTO w_output.
  SELECT SINGLE as4text FROM e07t
  INTO w_output-as4text
  WHERE trkorr = w_output-trkorr.
  MODIFY t_output FROM w_output.
  CLEAR: w_output.
  ENDLOOP.

  SORT t_output ASCENDING BY trkorr.

  ENDIF.

ENDFORM. " GET_E070

*&---------------------------------------------------------------------*
*& Form MODIFY_ALV
*&---------------------------------------------------------------------*
* Modify the ALV grid: optimize columns, hide columns, set names
*----------------------------------------------------------------------*
* -->P_ALV ALV Grid Object
*----------------------------------------------------------------------*
FORM modify_alv USING p_alv TYPE REF TO cl_salv_table .

  DATA: lr_columns TYPE REF TO cl_salv_columns_table,
  lr_column TYPE REF TO cl_salv_column_table ,
  lr_sorts TYPE REF TO cl_salv_sorts ,
  lr_aggregs TYPE REF TO cl_salv_aggregations ,
  lr_functions TYPE REF TO cl_salv_functions,
  lr_display TYPE REF TO cl_salv_display_settings ,
  lr_selections TYPE REF TO cl_salv_selections,
  lv_title TYPE lvc_title.
  TRY.
* Set Columns to optimized width
  lr_columns = p_alv->get_columns( ).
  lr_columns->set_optimize( ).
* Set ALV to display tool bar
  lr_functions = p_alv->get_functions( ).
  lr_functions->set_all( if_salv_c_bool_sap=>true ).
* Enable Striped Pattern (Zebra)
  lr_display = p_alv->get_display_settings( ).
  lr_display->set_striped_pattern( cl_salv_display_settings=>true ).

  CATCH cx_root.
  ENDTRY.

ENDFORM. " MODIFY_ALV

***INCLUDE BDCRECXY


*----------------------------------------------------------------------*
* Batchinputdata of single transaction
DATA: BDCDATA LIKE BDCDATA OCCURS 0 WITH HEADER LINE.
* Nodata-Character
DATA: NODATA_CHARACTER VALUE '/'.

*----------------------------------------------------------------------*
* create batchinput session *
*----------------------------------------------------------------------*
FORM OPEN_GROUP
  USING P_GROUP LIKE APQI-GROUPID
  P_USER LIKE APQI-USERID
  P_KEEP LIKE APQI-QERASE
  P_HOLDDATE LIKE APQI-STARTDATE
  P_CTU LIKE APQI-PUTACTIVE.

  IF P_CTU <> 'X'.
  CALL FUNCTION 'BDC_OPEN_GROUP'
  EXPORTING CLIENT = SY-MANDT
  GROUP = P_GROUP
  USER = P_USER
  KEEP = P_KEEP
  HOLDDATE = P_HOLDDATE.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* end batchinput session *
*----------------------------------------------------------------------*
FORM CLOSE_GROUP USING P_CTU LIKE APQI-PUTACTIVE.
  IF P_CTU <> 'X'.
* close batchinput group
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Start new transaction according to parameters *
*----------------------------------------------------------------------*
FORM BDC_TRANSACTION TABLES P_MESSTAB
  USING P_TCODE
  P_CTU
  P_MODE
  P_UPDATE.
DATA: L_SUBRC LIKE SY-SUBRC.

  IF P_CTU <> 'X'.
  CALL FUNCTION 'BDC_INSERT'
  EXPORTING TCODE = P_TCODE
  TABLES DYNPROTAB = BDCDATA
  EXCEPTIONS OTHERS = 1.
  ELSE.
  CALL TRANSACTION P_TCODE USING BDCDATA
  MODE P_MODE
  UPDATE P_UPDATE
  MESSAGES INTO P_MESSTAB.
  ENDIF.
  L_SUBRC = SY-SUBRC.
  REFRESH BDCDATA.
  SY-SUBRC = L_SUBRC.
ENDFORM.

*----------------------------------------------------------------------*
* Start new screen *
*----------------------------------------------------------------------*
FORM BDC_DYNPRO USING PROGRAM DYNPRO.
  CLEAR BDCDATA.
  BDCDATA-PROGRAM = PROGRAM.
  BDCDATA-DYNPRO = DYNPRO.
  BDCDATA-DYNBEGIN = 'X'.
  APPEND BDCDATA.
ENDFORM.

*----------------------------------------------------------------------*
* Insert field *
*----------------------------------------------------------------------*
FORM BDC_FIELD USING FNAM FVAL.
  IF fval <> NODATA_CHARACTER.
  CLEAR BDCDATA.
  BDCDATA-FNAM = FNAM.
  BDCDATA-FVAL = FVAL.
  APPEND BDCDATA.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Insert field *
*----------------------------------------------------------------------*
FORM BDC_NODATA USING P_NODATA.
  NODATA_CHARACTER = P_NODATA.
ENDFORM.

