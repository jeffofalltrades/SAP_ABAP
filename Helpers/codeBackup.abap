
* I think a mess of this was borrowed from some SDN forum post somewhere.

REPORT ZPULL_PROGRAMS NO STANDARD PAGE HEADING LINE-SIZE 132
LINE-COUNT 65.
************************************************************************
* Date: 6/9/99 SAP R/3 3.1H
* This program will download all programs specified in select option
* created by the creator specified in the select option.
* The parameter for file path must be entered in format:
* C:\TEMP\ or A:\JOE\ the actual name of the program will be
* the name of the file, it is added on dynamically. So when downloading
* this program it would end up being C:\TEMP\ZPROGRAM.txt
************************************************************************
TABLES: TRDIR.

SELECT-OPTIONS: S-NAME FOR TRDIR-NAME,
  S-CNAM FOR TRDIR-CNAM.

PARAMETERS: P-FILE(128) DEFAULT 'C:\',
  p_downld(1).

DATA: W-FL-SIZE TYPE I,
  W-PATH(128),
  W-TOTAL TYPE I,
  w_filename type string.

DATA: BEGIN OF ITAB OCCURS 0,
  NAME LIKE TRDIR-NAME,
  CNAM LIKE TRDIR-CNAM,
  END OF ITAB.

DATA: BEGIN OF REPORT OCCURS 0,
  LINE(300),
  END OF REPORT.

START-OF-SELECTION.

  SELECT NAME CNAM FROM TRDIR INTO CORRESPONDING FIELDS OF TABLE ITAB
  WHERE NAME IN S-NAME
  AND CNAM IN S-CNAM
  ORDER BY NAME.
  LOOP AT ITAB.
  REFRESH REPORT. CLEAR REPORT. CLEAR: W-PATH.
  READ REPORT ITAB-NAME INTO REPORT.
  CHECK: SY-SUBRC EQ 0.

  concatenate p-file itab-name '.txt' into w-path.
  move w-path to w_filename.
* MOVE: P-FILE TO W-PATH(60),
* ITAB-NAME TO W-PATH+60(8),
* '.txt' TO W-PATH+70(4).
* CONDENSE W-PATH NO-GAPS.

  DESCRIBE FIELD REPORT LENGTH W-FL-SIZE
  in character mode.

  if not p_downld is initial.

  CALL FUNCTION 'GUI_DOWNLOAD'
  EXPORTING
* BIN_FILESIZE =
  FILENAME = w_filename
  FILETYPE = 'ASC'
* APPEND = ' '
* WRITE_FIELD_SEPARATOR = ' '
* HEADER = '00'
* TRUNC_TRAILING_BLANKS = ' '
* WRITE_LF = 'X'
* COL_SELECT = ' '
* COL_SELECT_MASK = ' '
* DAT_MODE = ' '
* CONFIRM_OVERWRITE = ' '
* NO_AUTH_CHECK = ' '
* CODEPAGE = ' '
* IGNORE_CERR = ABAP_TRUE
* REPLACEMENT = '#'
* WRITE_BOM = ' '
* TRUNC_TRAILING_BLANKS_EOL = 'X'
* IMPORTING
* FILELENGTH =
  TABLES
  DATA_TAB = report
  EXCEPTIONS
  FILE_WRITE_ERROR = 1
  NO_BATCH = 2
  GUI_REFUSE_FILETRANSFER = 3
  INVALID_TYPE = 4
  NO_AUTHORITY = 5
  UNKNOWN_ERROR = 6
  HEADER_NOT_ALLOWED = 7
  SEPARATOR_NOT_ALLOWED = 8
  FILESIZE_NOT_ALLOWED = 9
  HEADER_TOO_LONG = 10
  DP_ERROR_CREATE = 11
  DP_ERROR_SEND = 12
  DP_ERROR_WRITE = 13
  UNKNOWN_DP_ERROR = 14
  ACCESS_DENIED = 15
  DP_OUT_OF_MEMORY = 16
  DISK_FULL = 17
  DP_TIMEOUT = 18
  FILE_NOT_FOUND = 19
  DATAPROVIDER_EXCEPTION = 20
  CONTROL_FLUSH_ERROR = 21
  OTHERS = 22.

  else.
  sy-subrc = 0.
  endif.

  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
* WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  WRITE: /1 'ERROR - NO DOWNLOAD', ITAB-NAME,
  sy-msgid, sy-msgty, sy-msgv1.
  Else.

* CALL FUNCTION 'WS_DOWNLOAD'
* EXPORTING
* BIN_FILESIZE = W-FL-SIZE
* FILENAME = W-PATH
* FILETYPE = 'ASC'
* TABLES
* DATA_TAB = REPORT
* EXCEPTIONS
* FILE_OPEN_ERROR = 1
* FILE_WRITE_ERROR = 2
* INVALID_FILESIZE = 3
* INVALID_TABLE_WIDTH = 4
* INVALID_TYPE = 5
* NO_BATCH = 6
* UNKNOWN_ERROR = 7
* OTHERS = 8.
* IF SY-SUBRC EQ 0.
  WRITE: /1 'DOWNLOADED:', ITAB-NAME.
  ADD 1 TO W-TOTAL.

  ENDIF.
  ENDLOOP.

  WRITE: /1 'TOTAL REPORTS DOWNLOADED:', W-TOTAL.
  SKIP 2.
  WRITE: /1 '***End of', SY-REPID, '***'. 