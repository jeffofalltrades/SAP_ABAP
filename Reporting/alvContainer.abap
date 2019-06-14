
*global object
 DATA: gr_cont         TYPE REF TO            cl_gui_custom_container,"container for ALV grid 


"screen flow logic:
PROCESS BEFORE OUTPUT.
 MODULE STATUS_0100.
 MODULE create_control.
*
PROCESS AFTER INPUT.
 MODULE USER_COMMAND_0100.



*----------------------------------------------------------------------*
*  MODULE status_0100 OUTPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S100'.
  SET TITLEBAR  'T100'.
ENDMODULE.   " STATUS_0100  OUTPUT




*----------------------------------------------------------------------*
*  MODULE create_control OUTPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE create_control OUTPUT.
  DATA p_alv TYPE REF TO cl_salv_table.

  IF gr_cont IS NOT BOUND.
* create container control and link it to the dynpro
    CREATE OBJECT gr_cont
      EXPORTING
        container_name              = 'CONTROL_AREA'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
      MESSAGE a015(bc405).
    ENDIF.

* create ALV and link it to the container control
    TRY.
        cl_salv_table=>factory(
          EXPORTING
            r_container    = gr_cont
*    CONTAINER_NAME =
          IMPORTING
            r_salv_table   = p_alv
          CHANGING
            t_table        = it_sflight
        ).
      CATCH cx_salv_msg .
    ENDTRY.
    PERFORM modify_alv USING p_alv.
    p_alv->display( ).
  ENDIF.
ENDMODULE.    " create_control  OUTPUT


*----------------------------------------------------------------------*
*  MODULE user_command_0100 INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      SET SCREEN 0.
      CALL METHOD gr_cont->free.
      CLEAR gr_cont.
  ENDCASE.
ENDMODULE. " USER_COMMAND_0100  INPUT

        