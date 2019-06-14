* so, TH_REDISPATCH.... maybe don't use that...
* but if you have a program that runs long and there
* is a demand for it to not timeout even though the 
* timeout limits are set for a reason... This will
* make the timeout start over.
* Rest of this is just making the progress indicator work

REPORT zjefftest.


PERFORM write_status using '1 percent integer' 1.

PERFORM write_status using '1 percent integer' 50.

PERFORM write_status using '1 percent integer' 99.


FORM write_status  USING i_message
                         i_percentage.


  CALL FUNCTION 'TH_REDISPATCH'.


  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = i_percentage
      text       = i_message.

ENDFORM.                    " WRITE_STATUS