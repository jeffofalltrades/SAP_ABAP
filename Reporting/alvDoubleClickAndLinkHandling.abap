




SET PARAMETER ID 'BES' FIELD wa_po-ebeln. 
CALL TRANSACTION 'ME23N' |AND SKIP FIRST SCREEN|. 




*Object Oriented method:
************************************************************************
*                         M E T H O D S                                *
************************************************************************

"Class and methods for handling double click in ALV
*-----------------------------------------------------------------------------*
*           CLASS lcl_handle_events DEFINITION
*-----------------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.
  PUBLIC SECTION.
    METHODS: on_double_click FOR EVENT double_click OF cl_salv_events_table
             IMPORTING row column.
    METHODS: on_link_click FOR EVENT link_click OF cl_salv_events_table
             IMPORTING row column.
ENDCLASS."lcl_handle_events DEFINITION


*-----------------------------------------------------------------------------*
*           CLASS lcl_handle_events Implementation
*-----------------------------------------------------------------------------*
CLASS lcl_handle_events IMPLEMENTATION.
  METHOD on_double_click.
    "put code here for what you want to happen during double click.
    "example code included.
    READ TABLE gi_output INTO gw_output INDEX row.
    IF sy-subrc = 0.
      SET PARAMETER ID 'VF' FIELD gw_output-vbeln.
      CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
    ENDIF.

  ENDMETHOD.                    "on_double_click

  METHOD on_link_click.
    "Put code here for what you want to happen during link click
    "example code included.
    READ TABLE gi_output INTO gw_output INDEX row.
    IF sy-subrc = 0.
      IF column = 'VBELN'.
        SET PARAMETER ID 'VF' FIELD gw_output-vbeln.
        CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
      ENDIF.
      IF column = 'VGBEL'.
        SET PARAMETER ID 'VL' FIELD gw_output-vgbel.
        CALL TRANSACTION 'VL03N' AND SKIP FIRST SCREEN.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "on_link_click
ENDCLASS."lcl_handle_events IMPLEMENTATION.


*-----------------------------------------------------------------------------*
*           Put this bit down in form for modifying ALV
*-----------------------------------------------------------------------------*

DATA: lr_column     TYPE REF TO cl_salv_column_table,

"data for double click event in ALV
      gr_events     TYPE REF TO lcl_handle_events,
      lr_events     TYPE REF TO cl_salv_events_table.

"set up object for handling double click event
lr_events = p_alv->get_event( ).
"create an event object
CREATE OBJECT gr_events.
"add handler to event object
SET HANDLER gr_events->on_double_click FOR lr_events.
SET HANDLER gr_events->on_link_click   FOR lr_events.
"set vbeln as hotspot link
lr_column ?= lr_columns->get_column( columnname = 'VBELN' ).
lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).


















*User command method:



*GRID
   CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
     EXPORTING
       i_callback_program     = wa_vari-report
       i_callback_pf_status_set = 'SET_PF_STATUS'
       i_callback_user_command  = 'USER_COMMAND'
       i_structure_name       = 't_report'
       i_grid_title           = wa_title
       i_grid_settings        = wa_sett
       is_layout              = wa_layout
       is_variant             = wa_vari
       it_events              = i_events
       it_event_exit          = i_event_exit
       i_save                 = 'A'
       it_fieldcat            = i_headercat
     TABLES
       t_outtab               = t_report
     EXCEPTIONS
       program_error          = 1
       OTHERS                 = 2.
   IF sy-subrc <> 0.
     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
   ENDIF.
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       Routine for the GUI functions not included in standard ALV FM
*----------------------------------------------------------------------*
*      -->R_UCOMM      Function code from the GUI
*      -->RS_SELFIELD  Options
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm     LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

* Hotspot Invoice
if rs_selfield-sel_tab_field = 't_report-VBELN'.
set parameter id 'VF' field rs_selfield-value.
call transaction 'VF03' and skip first screen.
endif.

* Hotspot Delivery
if rs_selfield-sel_tab_field = 't_report-DELIVERY'.
set parameter id 'VL' field rs_selfield-value.
call transaction 'VL03N' and skip first screen.
endif.

* Hotspot TO
if rs_selfield-sel_tab_field = 't_report-TANUM'.
set parameter id 'TAN' field rs_selfield-value.
read table t_report index rs_selfield-tabindex.
set parameter id 'LGN' field t_report-LGNUM.
call transaction 'LT21' and skip first screen.
endif.

ENDFORM.  "User_command
