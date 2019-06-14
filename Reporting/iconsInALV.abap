*You need this at top of program
  TYPE-POOLS: icon.

*inside internal table structure, add an extra column
  icon type icon-id            "<----- fill it with whatever icon you want

*icon names can be found by going into se16 and looking at table ICON

*work area example:
  if wa_sflight-fldate >= sy-datum.
      wa_sflight-dateicon = icon_flight.
    else.
      wa_sflight-dateicon = icon_time_control.
    endif.

*ALV code
*Must set the column to read icons
*example code:
  data: lr_column    TYPE REF TO cl_salv_column_table,
        lr_columns   TYPE REF TO cl_salv_columns_table.

*icon column for flight dates
  lr_columns = p_alv->get_columns( ).
  lr_column ?= lr_columns->get_column( columnname = 'DATEICON' ).
  lr_column->set_icon( ). "set as icon
  lr_column->set_short_text( 'Icon' ).
  lr_column->set_medium_text( 'Date Icon' ).
  lr_column->set_long_text( 'Date Icon' ).