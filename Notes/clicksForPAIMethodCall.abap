CALL METHOD cl_gui_cfw=>set_new_ok_code 
         EXPORTING new_code = 'DUMMY'.






METHOD on_double_click.
    READ TABLE t_detail_output INTO w_detail INDEX row.

    CASE column.
      WHEN 'A2PO'.
        CASE w_detail-a2po.
          WHEN 'X'.
            w_detail-a2po = ' '.

            w_volume = w_volume - w_detail-form_volume.
            w_vials = w_vials - w_detail-vials.
            w_scrap = w_scrap - w_detail-scrap.
          WHEN ' '.
            w_detail-a2po = 'X'.

            w_volume = w_volume + w_detail-form_volume.
            w_vials = w_vials + w_detail-vials.
            w_scrap = w_scrap + w_detail-scrap.
        ENDCASE.
        MODIFY t_detail_output FROM w_detail INDEX row.
        CALL METHOD cl_gui_cfw=>set_new_ok_code
          EXPORTING
            new_code = 'DUMMY'.
        wr_alv->refresh( ).
      WHEN 'A2STO'.
        CASE w_detail-a2sto.
          WHEN 'X'.
            w_detail-a2sto = ' '.

            w_volume2 = w_volume2 - w_detail-form_volume.
            w_vials2 = w_vials2 - w_detail-vials.
            w_scrap2 = w_scrap2 - w_detail-scrap.
          WHEN ' '.
            w_detail-a2sto = 'X'.

            w_volume2 = w_volume2 + w_detail-form_volume.
            w_vials2 = w_vials2 + w_detail-vials.
            w_scrap2 = w_scrap2 + w_detail-scrap.
        ENDCASE.
        MODIFY t_detail_output FROM w_detail INDEX row.
        CALL METHOD cl_gui_cfw=>set_new_ok_code
          EXPORTING
            new_code = 'DUMMY'.
        wr_alv->refresh( ).
    ENDCASE.
  ENDMETHOD.                    "on_double_click