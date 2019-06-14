* Transport dependencies program (for include dependencies)
* no idea who ZCRAIG6 is... I might have borrowed some of this code from 
* online and modified. Same as transportDepdency.abap, I haven't used
* this in a very long time. 
* If you use it, please drop me a line and hit me with a pull request for any updates!


*&---------------------------------------------------------------------*
*& Report ZCRAIG6
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zjefftest.

TYPES: BEGIN OF ty_data,
  trkorr TYPE e070-trkorr,
  as4user TYPE e070-as4user,
  as4date TYPE e070-as4date,
  as4time TYPE e070-as4time,
  as4text TYPE e07t-as4text,
  pgmid TYPE e071-pgmid,
  object TYPE e071-object,
  obj_name TYPE e071-obj_name,
  include TYPE wbcrossgt-include,
  END OF ty_data.


TYPES: BEGIN OF ty_dep,
  transport TYPE e070-trkorr,
  dependency TYPE e070-trkorr,
  END OF ty_dep.

TYPES: BEGIN OF ty_out,
  trkorr TYPE e070-trkorr,
  as4user TYPE e070-as4user,
  as4date TYPE e070-as4date,
  as4time TYPE e070-as4time,
  as4text TYPE e07t-as4text,
  dependencies TYPE e070-trkorr,
  dep_text TYPE e07t-as4text,
  dep_user TYPE e070-as4user,
  END OF ty_out.
TYPES: BEGIN OF ty_cross,
  name TYPE wbcrossgt-name,
  include TYPE wbcrossgt-include,
  obj_name TYPE e071-obj_name,
  END OF ty_cross.
************************************************************************
TYPES:
  BEGIN OF ty_batch,
  trkorr TYPE e070-trkorr,
  END OF ty_batch.

DATA: tdata TYPE STANDARD TABLE OF ty_data WITH HEADER LINE,
  t_batch TYPE STANDARD TABLE OF ty_batch INITIAL SIZE 0,
  tobj TYPE STANDARD TABLE OF ty_data WITH HEADER LINE,
  t71 TYPE STANDARD TABLE OF ty_data WITH HEADER LINE,
  dep TYPE STANDARD TABLE OF ty_dep WITH HEADER LINE,
  out TYPE STANDARD TABLE OF ty_out WITH HEADER LINE,
  trans TYPE i,
  depen TYPE i,
  tcross TYPE STANDARD TABLE OF ty_cross WITH HEADER LINE.

RANGES r_trkorr FOR e070-trkorr.


"Class and methods for handling double click in ALV
*-----------------------------------------------------------------------------*
* CLASS lcl_handle_events DEFINITION
*-----------------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.
  PUBLIC SECTION.
  METHODS: on_double_click FOR EVENT link_click OF cl_salv_events_table
  IMPORTING row column.
ENDCLASS."lcl_handle_events DEFINITION





SELECTION-SCREEN BEGIN OF BLOCK input.

SELECT-OPTIONS: p_unam FOR tdata-as4user,
s_trans FOR tdata-trkorr.
PARAMETERS:
  p_infile LIKE rlgrap-filename," OBLIGATORY,
  p_str TYPE string,
  p_tran RADIOBUTTON GROUP bttn DEFAULT 'X' ,
  p_tabl RADIOBUTTON GROUP bttn.

SELECTION-SCREEN END OF BLOCK input .

************************************************************************
* A T S E L E C T I O N - S C R E E N *
************************************************************************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infile.
  "handle matchcode button hit with open file dialog
  PERFORM open_dialog CHANGING p_infile.

START-OF-SELECTION.
  IF p_infile IS NOT INITIAL.
  PERFORM read_file. "read in the data
  ELSE.
  r_trkorr = s_trans.
  r_trkorr[] = s_trans[].
  ENDIF.
  "get all transports for user
  SELECT
  e070~trkorr
  e070~as4user
  e070~as4date
  e070~as4time
  e07t~as4text
  e071~pgmid
  e071~object
  e071~obj_name
  FROM e070 INNER JOIN e071
  ON e070~trkorr EQ e071~trkorr
  INNER JOIN e07t
  ON e070~trkorr EQ e07t~trkorr
 INTO TABLE tdata
 WHERE as4user IN p_unam
  AND e070~trstatus EQ 'R'
  AND e070~trfunction EQ 'K'
  AND e070~trkorr IN r_trkorr.

  LOOP AT tdata.
  WRITE tdata-obj_name TO tdata-include.
  MODIFY tdata.
  CLEAR tdata.
  ENDLOOP.

  "make copy of tdata to get unique objects we care about
  tobj[] = tdata[].
  SORT tobj[] ASCENDING BY pgmid object obj_name.
  DELETE ADJACENT DUPLICATES FROM tobj[] COMPARING pgmid object obj_name.

  "get all transports that match the objects user has touched
  IF tobj[] IS NOT INITIAL AND p_tran EQ 'X'.
  SELECT
  e070~trkorr
  e070~as4user
  e070~as4date
  e070~as4time
  e07t~as4text
  e071~pgmid
  e071~object
  e071~obj_name
  FROM e070 INNER JOIN e071
  ON e070~trkorr EQ e071~trkorr
  INNER JOIN e07t
  ON e070~trkorr EQ e07t~trkorr
  INTO TABLE t71
  FOR ALL ENTRIES IN tobj
  WHERE e070~trstatus EQ 'R'
  AND e070~trfunction EQ 'K'
  AND e071~obj_name EQ tobj-obj_name
  AND e071~pgmid EQ tobj-pgmid
  AND e071~object EQ tobj-object
  AND e070~as4date GT '20160101'.


  "loop at users transports
  LOOP AT tdata.
  IF tdata-obj_name+0(1) NE 'Z'
  OR NOT tdata-obj_name CS p_str.
  CONTINUE.
  ENDIF.
  "loop through t71 for the objects and give the dependency
  LOOP AT t71 WHERE obj_name EQ tdata-obj_name
  AND as4date LE tdata-as4date
  AND as4time LT tdata-as4time.

  dep-transport = tdata-trkorr.
  dep-dependency = t71-trkorr.
  APPEND dep.
  CLEAR t71.
  CLEAR dep.
  ENDLOOP.
  CLEAR tdata.
  ENDLOOP.

  ELSEIF tobj[] IS NOT INITIAL.

  LOOP AT tdata.
  IF tdata-include+0(1) NE 'Z'.
  DELETE tdata[] INDEX sy-tabix.
  ENDIF.
  ENDLOOP.

  SELECT name include
  FROM wbcrossgt
  INTO TABLE tcross
  FOR ALL ENTRIES IN tdata
  WHERE include EQ tdata-include
  AND direct EQ 'X'.

  LOOP AT tcross.
  IF tcross-name+0(1) NE 'Z'
  OR tcross-name CS '\'
  OR tcross-name EQ 'ZCL_XAP_UTILITIES'
  OR tcross-name EQ 'ZPROG_FLD_VAL'
  OR tcross-name EQ 'ZWW_STR_ENHACTIVATE'
  OR tcross-name EQ 'ZWW_STR_PROG_FLD_VAL'.

  DELETE tcross[] INDEX sy-tabix.
  ELSE.
  WRITE tcross-include TO tcross-obj_name.
  MODIFY tcross.
  ENDIF.
  ENDLOOP.

  SORT tcross[] BY name include.
  DELETE ADJACENT DUPLICATES FROM tcross[].

  IF tcross IS NOT INITIAL.
  SELECT
  e070~trkorr
  e070~as4user
  e070~as4date
  e070~as4time
  e07t~as4text
  e071~pgmid
  e071~object
  e071~obj_name
  FROM e070 INNER JOIN e071
  ON e070~trkorr EQ e071~trkorr
  INNER JOIN e07t
  ON e070~trkorr EQ e07t~trkorr
  INTO TABLE t71
  FOR ALL ENTRIES IN tcross
  WHERE e070~trstatus EQ 'R'
  AND e070~trfunction EQ 'K'
  AND e071~obj_name EQ tcross-name
  AND e070~as4date GT '20160101'
  AND e071~object EQ 'TABL'.
  ENDIF.

  LOOP AT tcross.
  LOOP AT tdata WHERE obj_name EQ tcross-obj_name.
  IF NOT tdata-obj_name CS p_str.
  CONTINUE.
  ENDIF.
  LOOP AT t71 WHERE obj_name EQ tcross-name
  AND ( as4date LE tdata-as4date OR
  ( as4date EQ tdata-as4date
  AND as4time LT tdata-as4time ) ).
  dep-transport = tdata-trkorr.
  dep-dependency = t71-trkorr.
  APPEND dep.
  CLEAR t71.
  CLEAR dep.
  ENDLOOP.

  ENDLOOP.
  ENDLOOP.



  ENDIF.



  SORT dep[].
  DELETE ADJACENT DUPLICATES FROM dep[].

  LOOP AT dep.
  READ TABLE tdata WITH KEY trkorr = dep-transport.
  MOVE-CORRESPONDING tdata TO out.
  LOOP AT t71 WHERE trkorr = dep-dependency.
  out-dependencies = t71-trkorr.
  out-dep_text = t71-as4text.
  out-dep_user = t71-as4user.

  APPEND out.
  CLEAR out.
  EXIT.
  ENDLOOP.
  CLEAR dep.
  ENDLOOP.


  PERFORM display_report USING out[].



*&---------------------------------------------------------------------*

*& Form DISPLAY_REPORT

*&---------------------------------------------------------------------*

* Display the ALV Grid

*----------------------------------------------------------------------*

FORM display_report USING p_output.
  DATA: lcl_alv TYPE REF TO cl_salv_table.

*if the output table is not empty

  IF p_output IS NOT INITIAL .
  TRY.
  CALL METHOD cl_salv_table=>factory
  IMPORTING
  r_salv_table = lcl_alv
  CHANGING
  t_table = p_output.
  CATCH cx_salv_msg .
  ENDTRY .
*modify layout, columns, etc of the grid

  PERFORM modify_alv USING lcl_alv .
*Display the grid

  lcl_alv->display( ).
  ELSE.
  MESSAGE text-e01 TYPE 'I'.
  "There was no data found for selected criteria

  ENDIF.
ENDFORM. " DISPLAY_REPORT

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
  lr_filters TYPE REF TO cl_salv_filters ,
  lv_title TYPE lvc_title,

  lr_layout TYPE REF TO cl_salv_layout ,
  l_key TYPE salv_s_layout_key .

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


  lr_selections = p_alv->get_selections( ).
  lr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

* Add sorts to the alv display

  lr_sorts = p_alv->get_sorts( ).

  lr_sorts->add_sort(
  columnname = 'TRKORR'
  position = 1
  subtotal = if_salv_c_bool_sap=>false ).
  lr_sorts->add_sort(
  columnname = 'AS4DATE'
  position = 2
  subtotal = if_salv_c_bool_sap=>false ).
  lr_sorts->add_sort(
  columnname = 'AS4TIME'
  position = 3
  subtotal = if_salv_c_bool_sap=>false ).
  lr_sorts->add_sort(
  columnname = 'AS4TEXT'
  position = 4
  subtotal = if_salv_c_bool_sap=>false ).


  DATA:
  "data for double click event in ALV
  gr_events TYPE REF TO lcl_handle_events,
  lr_events TYPE REF TO cl_salv_events_table.

  "set up object for handling double click event
  lr_events = p_alv->get_event( ).
  "create an event object
  CREATE OBJECT gr_events.
  "add handler to event object
  SET HANDLER gr_events->on_double_click FOR lr_events.
  "set vbeln as hotspot link
  lr_column ?= lr_columns->get_column( columnname = 'TRKORR' ).
  lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
  CATCH cx_root.
  ENDTRY.

ENDFORM. " MODIFY_ALV
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
  DATA: l_infile TYPE string,
  w_batch LIKE LINE OF t_batch.

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

  LOOP AT t_batch INTO w_batch.
  r_trkorr-sign = 'I'.
  r_trkorr-option = 'EQ'.
  r_trkorr-low = w_batch-trkorr.

  APPEND r_trkorr.
  ENDLOOP.

ENDFORM. " READ_FILE



*-----------------------------------------------------------------------------*
* CLASS lcl_handle_events Implementation
*-----------------------------------------------------------------------------*
CLASS lcl_handle_events IMPLEMENTATION.
  METHOD on_double_click.
  DATA: te071 TYPE STANDARD TABLE OF e071,
  we071 TYPE e071.
  "put code here for what you want to happen during double click.
  "example code included.
  READ TABLE out[] INTO out INDEX row.
  IF sy-subrc = 0.
  IF column EQ 'TRKORR'.

  IF p_tran EQ 'X'.
  SELECT
  a~trkorr
  a~as4pos
  a~pgmid
  a~object
  a~obj_name
  a~objfunc
  a~lockflag
  a~gennum
  a~lang
  a~activity
  FROM e071 AS a INNER JOIN e071 AS b
  ON a~obj_name EQ b~obj_name
  INTO TABLE te071
  WHERE a~trkorr EQ out-trkorr
  AND b~trkorr EQ out-dependencies.


  ELSE.
  SELECT
  trkorr
  as4pos
  pgmid
  object
  obj_name
  objfunc
  lockflag
  gennum
  lang
  activity
  FROM e071
  INTO TABLE te071
  WHERE trkorr EQ out-dependencies
  AND object EQ 'TABL'.
  ENDIF.

  LOOP AT te071 INTO we071 WHERE obj_name+0(1) NE 'Z'.
  DELETE te071 INDEX sy-tabix.
  ENDLOOP.




  PERFORM display_report USING te071.
  REFRESH te071.
  ENDIF.
  ENDIF.

  ENDMETHOD. "on_double_click
ENDCLASS.