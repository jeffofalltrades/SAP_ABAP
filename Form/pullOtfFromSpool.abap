*  IF gv_pdfvw EQ 'X'.
*    DATA: lv_rqident type tsp01-rqident,
*          lv_FILE LIKE RLGRAP-FILENAME VALUE 'C:pdf'.
*
*    SELECT SINGLE MAX( RQIDENT ) FROM TSP01
*    INTO lv_rqident
*    WHERE RQ0NAME EQ c_correspondence
*      AND RQ2NAME EQ p_bukrs
*      AND RQOWNER EQ sy-uname
*      AND RQDOCTYPE EQ 'OTF'.
*
*
*    SUBMIT RSTXPDFT4
*      WITH SPOOLNO EQ lv_rqident
*      with DOWNLOAD EQ 'X'
*      WITH p_file EQ lv_FILE
*    AND RETURN.
*  ENDIF.