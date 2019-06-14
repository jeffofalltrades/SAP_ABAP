* if the system has some accessibility options installed, this works

DATA ovoice TYPE ole2_object.
CREATE OBJECT ovoice 'SAPI.SpVoice'.
IF sy-subrc = 0.  
  CALL METHOD OF ovoice 'Speak'    
    EXPORTING #1 = 'ROFLCOPTER goes soi soi soi soi soi soi soi soi soi'.
ENDIF.