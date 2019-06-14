*------------------------------------------------------------------------------------------------------------------------------------
* TITLE
* AUTHOR    JMCDONALD
* DATE WRITTEN
* R/3 RELEASE
* VALIDATION DOC:
*------------------------------------------------------------------------------------------------------------------------------------
* <Description of program function>

*------------------------------------------------------------------------------------------------------------------------------------
* CHANGE HISTORY
* Date      By        Change label, Correction Number & Brief Description  Release
*
*****************************************************************************************

REPORT  zmrerp0073_ds_inventory.

************************************************************************
*                           T A B L E S                                *
************************************************************************
TABLES: mchb , cabn, ekko.
************************************************************************
*                           T Y P E S                                  *
************************************************************************
TYPES:
  BEGIN OF ty_output,
    test type string,
  END OF ty_output.

************************************************************************
*                       C O N S T A N T S                              *
************************************************************************

************************************************************************
*                   S E L E C T  -  O P T I O N S                      *
*                       P A R A M E T E R S                            *
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK data WITH FRAME TITLE text -s01.
SELECT-OPTIONS:
  s_matnr FOR mchb- matnr,
  s_werks FOR mchb- werks,
  s_atnam FOR cabn- atnam,
  s_charg FOR mchb- charg,
  s_licha FOR mchb- charg,
  s_lifnr FOR ekko- lifnr,
  s_ebeln FOR ekko- ebeln.
SELECTION-SCREEN END OF BLOCK data .

SELECTION-SCREEN BEGIN OF BLOCK options WITH FRAME TITLE text- s02.
SELECTION-SCREEN COMMENT /2(50 ) text- s03.

PARAMETERS:
  p_sum  RADIOBUTTON GROUP bttn DEFAULT 'X' ,
  p_det  RADIOBUTTON GROUP bttn.

SELECTION-SCREEN SKIP 1.
PARAMETERS:
  p_layout TYPE disvariant- variant. " Layout
SELECTION-SCREEN END OF BLOCK options.

************************************************************************
*                  D A T A     D E F I N I T I O N                     *
************************************************************************

************************************************************************
*                        V A R I A B L E S                             *
************************************************************************

************************************************************************
*                  I N T E R N A L   T A B L E S                       *
************************************************************************
DATA:
      t_output TYPE STANDARD TABLE OF ty_output.
************************************************************************
*                        S T R U C T U R E S                           *
************************************************************************

************************************************************************
*                    I N I T I A L I Z A T I O N                       *
************************************************************************

************************************************************************
*              A T    S E L E C T I O N   -  S C R E E N               *
************************************************************************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layout.
  "Let the user pick a layout to use in the report
  DATA: ls_layout TYPE salv_s_layout_info,
        ls_key    TYPE salv_s_layout_key .

  ls_key-report = sy-repid .

  ls_layout = cl_salv_layout_service=> f4_layouts(
  s_key    = ls_key
  restrict = cl_salv_layout=> restrict_none ).

  p_layout = ls_layout- layout.

************************************************************************
*             S T A R T   -   O F   -  S E L E C T I O N               *
************************************************************************
START-OF-SELECTION.


  PERFORM display_report USING t_output.

END-OF-SELECTION.
************************************************************************
*                   C L A S S   D E F I N I T I O N                    *
************************************************************************

************************************************************************
*                C L A S S   I M P L E M N T A T I O N                 *
************************************************************************

************************************************************************
*                               F O R M S                              *
************************************************************************
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_REPORT
*&---------------------------------------------------------------------*
*       Display the ALV Grid
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
            t_table      = p_output .
      CATCH cx_salv_msg .
    ENDTRY .
*modify layout, columns, etc of the grid
    PERFORM modify_alv USING lcl_alv .
*Display the grid
    lcl_alv-> display( ).
  ELSE.
    MESSAGE text -e01 TYPE 'I'. "There was no data found for selected criteria
  ENDIF.
ENDFORM.                    " DISPLAY_REPORT

*&---------------------------------------------------------------------*
*&      Form  MODIFY_ALV
*&---------------------------------------------------------------------*
*       Modify the ALV grid: optimize columns, hide columns, set names
*----------------------------------------------------------------------*
*      -->P_ALV  ALV Grid Object
*----------------------------------------------------------------------*
FORM modify_alv  USING    p_alv TYPE REF TO cl_salv_table .

  DATA: lr_columns    TYPE REF TO cl_salv_columns_table,
        lr_column     TYPE REF TO cl_salv_column_table ,
        lr_sorts      TYPE REF TO cl_salv_sorts ,
        lr_aggregs    TYPE REF TO cl_salv_aggregations ,
        lr_functions  TYPE REF TO cl_salv_functions,
        lr_display    TYPE REF TO cl_salv_display_settings ,
        lr_selections TYPE REF TO cl_salv_selections,
        lr_filters    TYPE REF TO cl_salv_filters ,
        lv_title      TYPE        lvc_title,
        lr_layout     TYPE REF TO cl_salv_layout ,
        l_key         TYPE salv_s_layout_key .


  TRY.
* Set Columns to optimized width
      lr_columns = p_alv->get_columns ( ).
      lr_columns-> set_optimize( ).
* Set Columns to hide from user at display
*      lr_column ?= lr_columns->get_column( columnname = 'KVGR1' ).
*      lr_column->set_visible( '' ).
* Set columns to always hide from the user (fields used for getting data ect.)
*      lr_column ?= lr_columns->get_column( columnname = 'KNUMH' ).
*      lr_column->set_technical( ).
* Add sorts to the alv display
*      lr_sorts = p_alv->get_sorts( ).
*      lr_sorts->add_sort(
*        columnname = 'KNUMA'
*        position = 1
*        subtotal = if_salv_c_bool_sap=>true ). "if you want subtotals set to true
*set aggregation (shows total at bottom of ALV
*      lr_aggregs = p_alv->get_aggregations( ).
*      lr_aggregs->add_aggregation(
*        columnname = 'KAWRT_K'
*        aggregation = if_salv_c_aggregation=>total
*      ).
* Set ALV to display tool bar
      lr_functions = p_alv->get_functions ( ).
      lr_functions-> set_all( if_salv_c_bool_sap =>true ).
* Enable Striped Pattern (Zebra)
      lr_display = p_alv->get_display_settings ( ).
      lr_display-> set_striped_pattern( cl_salv_display_settings =>true ).
*  Set ALV title
      lv_title = text-t01 .
      lr_display-> set_list_header( value = lv_title ). "
* Enable selection boxes on left side of ALV display
      lr_selections = p_alv->get_selections ( ).
      lr_selections-> set_selection_mode( if_salv_c_selection_mode =>row_column ).
* Set a filter on a field
*       lr_filters = p_alv->get_filters().
*       lr_filters->add_filter(
*          columnname = 'SEATSOPEN'
*          sign = 'I'
*          option = 'GT'
*          low = '20'
*        ).

* Set names of columns.
*      PERFORM set_column_name USING lr_columns:
*          'BUKRS' text-100,
*          'KNUMA' text-101.
* etc.

* Set layout based on user selection
*      lr_layout = p_alv->get_layout(  ).
*      IF p_layout IS NOT INITIAL.
*        lr_layout->set_initial_layout( p_layout ).
*      ENDIF .
*      l_key-report = sy-repid.
*      lr_layout->set_key( l_key ).
*      lr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

    CATCH cx_root.
  ENDTRY.

ENDFORM.                    " MODIFY_ALV
*&---------------------------------------------------------------------*
*&      Form  SET_COLUMN_NAME
*&---------------------------------------------------------------------*
*       Set Column Name
*----------------------------------------------------------------------*
*      -->P_COLUMNS  Columns Object
*      -->P_Column   Column Name
*      -->P_TEXT     Text
*----------------------------------------------------------------------*
FORM set_column_name  USING   p_columns TYPE REF TO cl_salv_columns_table
                               value(p_column )
                               p_text .
  DATA: lr_column  TYPE REF TO cl_salv_column_table,
        l_short    TYPE        scrtext_s,
        l_medium   TYPE        scrtext_m,
        l_long     TYPE        scrtext_l.
  TRY.
      lr_column ?= p_columns-> get_column( columnname = p_column ).
      l_short = l_medium = l_long = p_text.
      lr_column-> set_short_text( value = l_short ).
      lr_column-> set_medium_text( value = l_medium ).
      lr_column-> set_long_text( value = l_long ).
    CATCH cx_root.
  ENDTRY.

ENDFORM.                    " SET_COLUMN_NAME