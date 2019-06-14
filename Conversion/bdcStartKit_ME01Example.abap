* I used to always use this as my starting basis for making BDC programs.
* The example was for ME01 transaction BDC. This was from 2012. Your
* milage may vary.

REPORT ZPMT_MIC.
INCLUDE bdcrecxy. 
TYPE-POOLS: icon .

************************************************************************ 
*                       T Y P E S                                      *
************************************************************************ 
TYPES:
BEGIN OF ty_batch, 
  matnr           LIKE    alsmex_tabline-value, 

...... 

END OF ty_batch, 

BEGIN OF ty_batch_head, 
  matnr           LIKE    alsmex_tabline-value, 

END OF ty_batch_head, 

BEGIN OF ty_output, 
  icon            TYPE    icon-id, 
  msgtyp          TYPE    c LENGTH 32,  "custom field. no data dict equivalent
  msgtxt          TYPE    c LENGTH 255, "custom field. no def in FM FORMAT_MESSAGE
  matnr           LIKE    eord-matnr, 

END OF ty_output, 



************************************************************************ 
*                  D A T A     D E F I N I T I O N                     *
************************************************************************ 
************************************************************************ 
*                        V A R I A B L E S                             *
************************************************************************ 


************************************************************************ 
*                  I N T E R N A L   T A B L E S                       *
************************************************************************ 
DATA: t_input_tab  TYPE                   alsmex_tabline OCCURS 0 WITH HEADER LINE,
      t_batch      TYPE STANDARD TABLE OF ty_batch INITIAL SIZE 0, 
      t_messtab    TYPE STANDARD TABLE OF bdcmsgcoll,
      t_output     TYPE STANDARD TABLE OF ty_output,
      t_vendor_num TYPE STANDARD TABLE OF ty_vendor_num.

************************************************************************ 
*                        S T R U C T U R E S                           *
************************************************************************ 
DATA: w_batch      TYPE                   ty_batch,
      w_vendor_num TYPE                   ty_vendor_num,
      w_messtab    TYPE                   bdcmsgcoll,
      w_output     TYPE                   ty_output.

************************************************************************ 
*                   S E L E C T - O P T I O N S                      *
*                       P A R A M E T E R S                            *
************************************************************************ 
SELECTION-SCREEN BEGIN OF BLOCK input WITH FRAME TITLE text-200. 
PARAMETERS: p_infile LIKE rlgrap-filename OBLIGATORY.
SELECTION-SCREEN END OF BLOCK input .

SELECTION-SCREEN BEGIN OF BLOCK options WITH FRAME TITLE text-201.
PARAMETERS: p_pass  AS CHECKBOX DEFAULT 'X', 
            p_info  AS CHECKBOX DEFAULT 'X' ,
            p_warn  AS CHECKBOX DEFAULT 'X' ,
            p_error AS CHECKBOX DEFAULT 'X' .
SELECTION-SCREEN END OF BLOCK options.


************************************************************************ 
*            S T A R T  -  O F  - S E L E C T I O N                *
************************************************************************ 
START-OF-SELECTION.
  PERFORM read_file.                      "read in the data
  PERFORM format_data.                    "format the data
  PERFORM process_via_bdc.                "execute BDC steps
  PERFORM display_messages USING t_output."output errors and other messages
END-OF-SELECTION.

************************************************************************ 
*            A T    S E L E C T I O N  - S C R E E N                 *
************************************************************************ 
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infile.
  "handle matchcode button hit with open file dialog 
  PERFORM open_dialog CHANGING p_infile.


************************************************************************ 
*          S U P P O R T I N G    S U B R O U T I N E S                * 
************************************************************************ 

*&---------------------------------------------------------------------* 
*&      Form  OPEN_DIALOG 
*&---------------------------------------------------------------------* 
*       Shows the user the file dialog for finding their file in a pop 
*       up window. 
*----------------------------------------------------------------------* 
*   <-> i_file  gives the open file dialog. Also sets the i_file 
*               value needed for the reading of data. 
*----------------------------------------------------------------------* 
FORM open_dialog  CHANGING p_file TYPE rlgrap-filename. 
  DATA l_infile TYPE string.


  "display the open file dialog 
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING 
      def_filename     = '*.txt' 
      def_path         = p_file
*     mask             = i_mask 
      mode             = 'O'
*     title            = '' 
    IMPORTING 
      filename         = p_file
    EXCEPTIONS 
      inv_winsys       = 04 
      no_batch         = 08 
      selection_cancel = 12
      selection_error  = 16.
  "display system message on error 
  IF sy-subrc <> 0. 
    "MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno 
    "WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4. 
  ENDIF.

  "convert the file name to a string. 
  l_infile = p_file. 
  "use regex to test if file name ends in .txt 
  "REGEX pattern:   finds instance of '.txt' in the string. is escape character for .
  "               $       looks at the end of the string. This verifies that the .txt is at the end of the string.
  FIND REGEX '$' IN l_infile. 

  "sy-subrc won't equal 0 if pattern not found. 
  IF sy-subrc <> 0. 
    "clear the file selection fields so that user has to reselect 
    CLEAR : p_infile, l_infile.
    "display message asking the user to select a new file in .txt format.
    "type I used due to error message causing errors since a pop up window is open at this time
    MESSAGE text-me1 TYPE 'I'.
  ENDIF.
ENDFORM.                    " OPEN_DIALOG
*&---------------------------------------------------------------------* 
*&      Form  READ_FILE 
*&---------------------------------------------------------------------* 
*       Reads in the tab delimited text document for use in the program. 
*----------------------------------------------------------------------* 
* -->  filename  used to direct to location of file to pull data from 
*  <-- t_batch   fills it with the data needed for the 
*----------------------------------------------------------------------* 
FORM read_file. 
  DATA: l_infile  TYPE  string. 

  "convert the file path into a string as required by GUI_UPLOAD 
  l_infile = p_infile. 

  "get the data from the file located at l_infile and store in t_batch 
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING 
      filename                = l_infile
      filetype                = 'ASC'
      has_field_separator     = '#' 
    TABLES 
      data_tab                = t_batch
    EXCEPTIONS 
      file_open_error         = 1 
      file_read_error         = 2 
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5 
      no_authority            = 6 
      unknown_error           = 7 
      bad_data_format         = 8 
      header_not_allowed      = 9 
      separator_not_allowed   = 10
      header_too_long         = 11 
      unknown_dp_error        = 12 
      access_denied           = 13 
      dp_out_of_memory        = 14 
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17. 
  "output system message on error 
  IF sy-subrc <> 0. 
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 .
  ENDIF.
ENDFORM.                    " READ_FILE


*&---------------------------------------------------------------------* 
*&      Form  FORMAT_DATA 
*&---------------------------------------------------------------------* 
*       Takes care of formatting the data that was read into the internal
*       table (date formatting, sorting the data, etc) 
*----------------------------------------------------------------------* 
*  <->  t_batch   Takes in t_batch data and formats fields 
*----------------------------------------------------------------------* 
FORM format_data. 

  "sort by the matnr werks. that way the multiple calls to same matnr werks are
  "grouped together and data might be cached for the call making it a little faster
  SORT t_batch ASCENDING BY matnr werks.
  CLEAR w_batch. 

  LOOP AT t_batch INTO w_batch.
    "make sure dates don't include seperators. 
    REPLACE ALL OCCURRENCES OF '.' IN w_batch-vdatu WITH ''.
    REPLACE ALL OCCURRENCES OF '.' IN w_batch-bdatu WITH ''.
    REPLACE ALL OCCURRENCES OF '/' IN w_batch-vdatu WITH ''.
    REPLACE ALL OCCURRENCES OF '/' IN w_batch-bdatu WITH ''.
    REPLACE ALL OCCURRENCES OF '-' IN w_batch-vdatu WITH ''.
    REPLACE ALL OCCURRENCES OF '-' IN w_batch-bdatu WITH ''.
    MODIFY t_batch FROM w_batch .
    CLEAR : w_batch. 
  ENDLOOP.

  IF t_batch IS NOT INITIAL .
    SELECT altkn lifnr
    FROM lfb1
    INTO CORRESPONDING FIELDS OF TABLE t_vendor_num
    FOR ALL ENTRIES IN t_batch
    WHERE altkn = t_batch-altkn. 
  ENDIF.

  SORT t_vendor_num BY altkn.

ENDFORM.                    " FORMAT_DATA


*&---------------------------------------------------------------------* 
*&      Form  PROCESS_DATA 
*&---------------------------------------------------------------------* 
*       BDC code that runs the transaction and inserts the data into 
*       the transaction ME01 
*----------------------------------------------------------------------* 
* -->  t_batch   takes in t_batch data to insert into ME01 
*  <-- t_messtab Exports the messages from the ME01 runs 
*----------------------------------------------------------------------* 
FORM process_via_bdc. 

  "declare local data needed for BDC 
  DATA:
        l_ctu       LIKE  apqi-putactive, 
        l_mode      LIKE  apqi-putactive, 
        l_update    LIKE  apqi-putactive, 
        l_group     LIKE  apqi-groupid, 
        l_user      LIKE  apqi-userid, 
        l_keep      LIKE  apqi-qerase, 
        l_holddate  LIKE  apqi-startdate ,
        l_nodata    LIKE  apqi-putactive. 

  "initialize data 
  l_ctu       =     'X'.
  l_mode      =     'N'.      "display nothing
  l_update    =     'S'.      "sync update
  l_user      =     sy-uname .
  l_nodata    =     '/'.

  "loop through the read data 
  LOOP AT t_batch INTO w_batch WHERE matnr IS NOT INITIAL
                                 AND werks IS NOT INITIAL .
    "initialize the BDC run. 
    PERFORM bdc_nodata      USING l_nodata. 
    PERFORM open_group      USING l_group l_user  l_keep l_holddate l_ctu.

    "program           screen 
    PERFORM bdc_dynpro      USING 'SAPLMEOR'        '0200'.
    "field             value           action 
    PERFORM bdc_field       USING 'EORD-MATNR'      w_batch-matnr.  "set the material field
    PERFORM bdc_field       USING 'EORD-WERKS'      w_batch-werks.  "set the plant field
    PERFORM bdc_field       USING 'BDC_OKCODE'      '/00'.          "enter key push 

    "program           screen 
    PERFORM bdc_dynpro      USING 'SAPLMEOR'        '0205'.
    "field             value           action 
    PERFORM bdc_field       USING 'BDC_OKCODE'      '=NS'.         "hit the new entries button so index 2 is clear

    "program           screen 
    PERFORM bdc_dynpro      USING 'SAPLMEOR'        '0205'.
    "field             value           action 
    PERFORM bdc_field       USING 'EORD-VDATU(02)'  w_batch-vdatu. "fill valid from date
    PERFORM bdc_field       USING 'EORD-BDATU(02)'  w_batch-bdatu. "fill valid to date
    PERFORM bdc_field       USING 'EORD-EKORG(02)'  w_batch-ekorg. "fill purchase org field

    "get the lifnr data: 
    READ TABLE t_vendor_num INTO w_vendor_num WITH KEY altkn = w_batch-altkn BINARY SEARCH.

    PERFORM bdc_field       USING 'EORD-LIFNR(02)'  w_vendor_num-lifnr. "fill vendor field 
    PERFORM bdc_field       USING 'EORD-MEINS(02)'  w_batch-meins. "fill order unit field
    PERFORM bdc_field       USING 'RM06W-FESKZ(02)' w_batch-feskz. "fill fixed source field
    PERFORM bdc_field       USING 'EORD-NOTKZ(02)'  w_batch-notkz. "fill blocked source of supply field
    PERFORM bdc_field       USING 'EORD-AUTET(02)'  w_batch-autet. "fill mrp field
    PERFORM bdc_field       USING 'EORD-EMATN(02)'  w_batch-ematn. "fill mrp material field
    PERFORM bdc_field       USING 'BDC_OKCODE'      '=NS'.         "hit the new entries button so index 2 is clear


    PERFORM bdc_field       USING 'BDC_OKCODE'      '=BU'.         "Save the entry.


    "submit the BDC to run the transactio n. 
    PERFORM bdc_transaction TABLES t_messtab  USING 'ME01' l_ctu l_mode l_update.
    PERFORM close_group USING l_ctu .

    "handle the messages that occured 
    PERFORM process_bdc_messages.
    CLEAR w_batch.
  ENDLOOP.


ENDFORM.                    " PROCESS_DATA



*&---------------------------------------------------------------------* 
*&      Form  PROCESS_BDC_MESSAGES 
*&---------------------------------------------------------------------* 
*       Handles the output from the BDC run to be used in the final 
*       output. Sets up icons and based on selection screen input 
*       determines which messages to keep and discard. 
*----------------------------------------------------------------------* 
*  --> t_messtab   Takes in message table and pulls needed data 
*   <--t_output    exports formatted output table with data about errors
*----------------------------------------------------------------------* 
FORM process_bdc_messages . 
  "loop through messages 
  LOOP AT t_messtab INTO w_messtab.
    "get the formatted message text and store in workarea msgtxt field 
    CALL FUNCTION 'FORMAT_MESSAGE'
      EXPORTING 
        id   = w_messtab-msgid
        lang = 'E'
        no   = w_messtab-msgnr
        v1   = w_messtab-msgv1
        v2   = w_messtab-msgv2
        v3   = w_messtab-msgv3
        v4   = w_messtab-msgv4
      IMPORTING 
        msg  = w_output-msgtxt .

    "based on the message type, assign text and icon 
    CASE w_messtab-msgtyp .
      WHEN 'S'. "success 
        IF p_pass = 'X' .                    "if user wants to display this type
          w_output-msgtyp = text-150.       "set text for type
          w_output-icon = icon_green_light . "set icon
        ELSE .
          CLEAR w_messtab.  "clear the data
          CONTINUE .         "continue on to next run
        ENDIF .
      WHEN 'E'. "error 
        IF p_error = 'X' .                   "if user wants to display this type
          w_output-msgtyp = text-151.       "set text for type
          w_output-icon = icon_red_light .   "set icon
        ELSE .
          CLEAR w_messtab.  "clear the data
          CONTINUE .         "continue on to next run
        ENDIF .
      WHEN 'W'. "warning 
        IF p_warn = 'X' .                    "if user wants to display this type
          w_output-msgtyp = text-152.       "set text for type
          w_output-icon = icon_yellow_light ."set icon
        ELSE .
          CLEAR w_messtab.  "clear the data
          CONTINUE .         "continue on to next run
        ENDIF .
      WHEN 'I'. "informative 
        IF p_info = 'X' .                    "if user wants to display this type
          w_output-msgtyp = text-153.       "set text for type
          w_output-icon = icon_yellow_light ."set icon
        ELSE .
          CLEAR w_messtab.  "clear the data
          CONTINUE .         "continue on to next run
        ENDIF .
    ENDCASE .

    "store relevant error data in the work area 


    APPEND w_output TO t_output.
    CLEAR : w_messtab, w_output.
  ENDLOOP.

  REFRESH t_messtab. 
  CLEAR t_messtab. 

ENDFORM.                    " PROCESS_BDC_MESSAGES


*&---------------------------------------------------------------------* 
*&      Form  DISPLAY_REPORT 
*&---------------------------------------------------------------------* 
*       Display the ALV Grid 
*----------------------------------------------------------------------* 
*  --> p_output takes in the file needed to output to ALV after report 
*                runs. 
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
            t_table      = p_output .
      CATCH cx_salv_msg .
    ENDTRY .
*modify layout, columns, etc of the grid 
    PERFORM modify_alv USING lcl_alv .
*Display the grid 
    lcl_alv->display( ).
  ELSE.
    MESSAGE text-001 TYPE 'I'.
  ENDIF.
ENDFORM.                    " DISPLAY_REPORT


*&---------------------------------------------------------------------* 
*&      Form  MODIFY_ALV 
*&---------------------------------------------------------------------* 
*       Modify the ALV grid: optimize columns, hide columns, set names 
*----------------------------------------------------------------------* 
*     -->P_ALV  ALV Grid Object 
*----------------------------------------------------------------------* 
FORM modify_alv  USING    p_alv TYPE REF TO cl_salv_table .

  DATA: lr_columns    TYPE REF TO cl_salv_columns_table, 
        lr_column     TYPE REF TO cl_salv_column_table ,
        lr_sorts      TYPE REF TO cl_salv_sorts ,
        lr_aggregs    TYPE REF TO cl_salv_aggregations ,
        lr_functions  TYPE REF TO cl_salv_functions,
        lr_display    TYPE REF TO cl_salv_display_settings ,
        lr_selections TYPE REF TO cl_salv_selections,
        lv_title      TYPE        lvc_title. 
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
* Set ALV Title Text 
      lv_title = text-400 .
      lr_display->set_list_header( value = lv_title ). 
* Enable selection boxes on left side of ALV display 
      lr_selections = p_alv->get_selections( ).
      lr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ). 

* Set names of columns. 
      PERFORM set_column_name USING lr_columns :
            'ICON'   text-107, 
            'MSGTYP' text-100, 
            'MATNR'  text-101, 
            'WERKS'  text-102, 
            'VDATU'  text-103, 
            'BDATU'  text-104, 
            'EMATN'  text-105, 
            'MSGTXT' text-106, 
            'EKORG'  text-108, 
            'ALTKN'  text-109, 
            'AUTET'  text-110, 
            'MEINS'  text-111, 
            'FESKZ'  text-112, 
            'NOTKZ'  text-113. 

* Turn on icons for icon column 
      lr_columns = p_alv->get_columns( ).
      lr_column ?= lr_columns->get_column( columnname = 'ICON' ). 
      lr_column->set_icon( ). "set as icon 

    CATCH cx_root.
  ENDTRY.

ENDFORM.                    " MODIFY_ALV
*&---------------------------------------------------------------------* 
*&      Form  SET_COLUMN_NAME 
*&---------------------------------------------------------------------* 
*       Sets column names 
*----------------------------------------------------------------------* 
*     -->P_COLUMNS  column object 
*     -->P_Column   name of the column to be modified 
*     -->P_TEXT     text to be displayed in column header 
*----------------------------------------------------------------------* 
FORM set_column_name  USING   p_columns       TYPE REF TO cl_salv_columns_table
                              value(p_column) TYPE any
                              p_text          TYPE any.
  DATA: lr_column  TYPE REF TO cl_salv_column_table, 
        l_short    TYPE        scrtext_s, 
        l_medium   TYPE        scrtext_m,
        l_long     TYPE        scrtext_l. 
  TRY.
      "get the column object 
      lr_column ?= p_columns->get_column( columnname = p_column ). 
      "store the input text into the local fields for the column header length
      l_short = l_medium = l_long = p_text. 
      "set the values for short, medium, and long text 
      lr_column->set_short_text( value = l_short ). 
      lr_column->set_medium_text( value = l_medium ). 
      lr_column->set_long_text( value = l_long ). 
    CATCH cx_root.
  ENDTRY.

ENDFORM.                    " SET_COLUMN_NAME


