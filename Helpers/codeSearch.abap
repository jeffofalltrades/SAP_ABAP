*

*&---------------------------------------------------------------------*
*& Report  ZAMYSRCH
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZAMYSRCH NO STANDARD PAGE HEADING
       LINE-SIZE 132 LINE-COUNT 0 .

TABLES: TRDIR , TADIR.

SELECTION-SCREEN COMMENT /35(21 ) TEXT- 001.
SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK BOX1 WITH FRAME TITLE TEXT- 002.
SELECT-OPTIONS PROGNAME FOR TRDIR-NAME .
SELECT-OPTIONS AUTHOR FOR TRDIR-CNAM MATCHCODE OBJECT ZUSR.
SELECT-OPTIONS DATE FOR TRDIR-UDAT .
SELECTION-SCREEN END OF BLOCK BOX1.
SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN SKIP 1.
PARAMETERS: SRCHSTRG (40) OBLIGATORY.
SELECTION-SCREEN ULINE.
PARAMETERS: LIMIT (6) TYPE N DEFAULT 999999.
SELECTION-SCREEN SKIP 1.

DATA: BEGIN OF SEARCH_TABLE OCCURS 10 ,
      SEARCH_STRING( 40).
DATA: END OF SEARCH_TABLE.

DATA: BEGIN OF INT_TRDIR OCCURS 2000 ,
      NAME LIKE TRDIR-NAME ,
      UNAM LIKE TRDIR-UNAM ,
      UDAT LIKE TRDIR-UDAT ,
      SUBC LIKE TRDIR-SUBC ,
      APPL LIKE TRDIR-APPL .
DATA: END OF INT_TRDIR.

data: abap_name like TRDIR- NAME,
      string_found type c length 40.

DATA: BEGIN OF ABAP_CODE OCCURS 1000 ,
      CODE_LINE( 255).
DATA: END OF ABAP_CODE.

DATA: NONE_FOUND TYPE I VALUE 0,
      LINES_SEARCHED LIKE SY-TABIX ,
      LINES_FOUND( 3) TYPE P,
      LINE_IN_CODE( 3) TYPE P,
      FOUND_LINE TYPE I ,
      STRING_LENGTH TYPE I ,
      COMMA_FOUND TYPE I ,
      STRING_MATCH TYPE I .

INITIALIZATION.
  MOVE 'Z*'         TO PROGNAME -LOW.
  MOVE 'I'          TO PROGNAME -SIGN.
  MOVE 'CP'         TO PROGNAME -OPTION.
  APPEND PROGNAME.
  MOVE SY- UNAME     TO AUTHOR -LOW.
  MOVE ''           TO AUTHOR -HIGH.
  MOVE 'I'          TO AUTHOR -SIGN.
  MOVE 'EQ'         TO AUTHOR -OPTION.
  APPEND AUTHOR.
  MOVE '19970215'   TO DATE -LOW.
  MOVE SY- DATUM     TO DATE- HIGH.
  MOVE 'I'          TO DATE- SIGN.
  MOVE 'BT'         TO DATE- OPTION.
  APPEND DATE.
  SET CURSOR FIELD SRCHSTRG.

AT SELECTION-SCREEN.
  IF PROGNAME- LOW IS INITIAL.
    IF PROGNAME- HIGH IS INITIAL.
      MOVE 'Z*'         TO PROGNAME- LOW.
      MOVE 'I'          TO PROGNAME- SIGN.
      MOVE 'CP'         TO PROGNAME- OPTION.
      APPEND PROGNAME.
    ENDIF .
  ENDIF.
  IF AUTHOR- LOW IS INITIAL.
    IF AUTHOR- HIGH IS INITIAL.
      MOVE SY-UNAME     TO AUTHOR- LOW.
      MOVE ''           TO AUTHOR- HIGH.
      MOVE 'I'          TO AUTHOR- SIGN.
      MOVE 'EQ'         TO AUTHOR- OPTION.
      APPEND AUTHOR.
    ENDIF .
  ENDIF.
  IF DATE-LOW IS INITIAL.
    IF DATE -HIGH IS INITIAL .
      MOVE '19970811'   TO DATE- LOW.
      MOVE SY-DATUM     TO DATE-HIGH .
      MOVE 'I'          TO DATE-SIGN .
      MOVE 'BT'         TO DATE-OPTION .
      APPEND DATE .
    ENDIF .
  ENDIF.

START-OF-SELECTION.
  PERFORM PARSE_SRCHSTRG.
  PERFORM GET_ABAP_LIST.
  IF NONE_FOUND = 1.
    WRITE :/ TEXT -003, AUTHOR-LOW .
  ELSE.
    PERFORM SEARCH_ABAP_CODE.
  ENDIF.

END-OF-SELECTION.
  SKIP 2.
  ULINE.
  FORMAT COLOR 6 INTENSIFIED ON .
  WRITE:/ 'LINES OF CODE SEARCHED: ', LINES_SEARCHED .
  WRITE:/ 'LINES OF CODE FOUND   : ', LINES_FOUND .

AT LINE-SELECTION.
  SET PARAMETER ID 'UFI' FIELD string_found .
  EDITOR-CALL FOR REPORT abap_NAME DISPLAY-MODE .
  SET PARAMETER ID 'RID' FIELD 'ZBSNSRCH' .

*&---------------------------------------------------------------------*
*&      Form  PARSE_SRCHSTRG
*&---------------------------------------------------------------------*
*       text                                                           *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PARSE_SRCHSTRG.
  CONDENSE SRCHSTRG.
  COMMA_FOUND = 1.
  STRING_LENGTH = 0.
  WHILE COMMA_FOUND = 1.
    IF SRCHSTRG CA ','.
      STRING_LENGTH = SY-FDPOS .
      SEARCH_TABLE- SEARCH_STRING = SRCHSTRG (STRING_LENGTH).
      APPEND SEARCH_TABLE.
      STRING_LENGTH = STRING_LENGTH + 1.
      SRCHSTRG = SRCHSTRG+STRING_LENGTH.
    ELSE .
      SEARCH_TABLE- SEARCH_STRING = SRCHSTRG .
      APPEND SEARCH_TABLE.
      COMMA_FOUND = 0.
    ENDIF .
  ENDWHILE.
ENDFORM.                               " PARSE_SRCHSTRG

*&---------------------------------------------------------------------*
*&      Form  GET_ABAP_LIST
*&---------------------------------------------------------------------*
*       text                                                           *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ABAP_LIST.
  SELECT NAME UNAM UDAT SUBC APPL
         INTO TABLE INT_TRDIR FROM TRDIR
         UP TO LIMIT ROWS
         WHERE NAME IN PROGNAME
         AND ( CNAM IN AUTHOR OR UNAM IN AUTHOR )
         AND UDAT IN DATE.
  IF SY- SUBRC NE 0 .
    NONE_FOUND = 1.
    EXIT .
  ENDIF.
ENDFORM.                               " GET_ABAP_LIST

*&---------------------------------------------------------------------*
*&      Form  SEARCH_ABAP_CODE
*&---------------------------------------------------------------------*
*       text                                                           *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SEARCH_ABAP_CODE.
  SORT INT_TRDIR BY NAME.
  LOOP AT INT_TRDIR.
    CLEAR LINE_IN_CODE.
    REFRESH ABAP_CODE.
    READ REPORT INT_TRDIR-NAME INTO ABAP_CODE.
    CLEAR FOUND_LINE.
    LOOP AT ABAP_CODE.
      clear string_found.
      LINES_SEARCHED = LINES_SEARCHED + 1.
      LINE_IN_CODE = LINE_IN_CODE + 1.
      STRING_MATCH = 1.
      PERFORM SEARCH_STRING.
      IF STRING_MATCH = 1 .
*      IF ABAP_CODE-CODE_LINE CS SRCHSTRG.
        LINES_FOUND = LINES_FOUND + 1.
        FOUND_LINE = 1.
        WRITE :/ LINES_FOUND INTENSIFIED ON COLOR 7,
                LINE_IN_CODE INTENSIFIED ON COLOR 4 ,
                INT_TRDIR-NAME , INT_TRDIR- UNAM,
                ABAP_CODE-CODE_LINE .
        abap_name = INT_TRDIR-NAME .
        HIDE : abap_name, string_found.
      ENDIF .
    ENDLOOP .
    IF FOUND_LINE > 0 . ULINE. ENDIF.
  ENDLOOP.
ENDFORM.                               " SEARCH_ABAP_CODE
*&---------------------------------------------------------------------*
*&      Form  SEARCH_STRING
*&---------------------------------------------------------------------*
*       text                                                           *
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SEARCH_STRING.
  STRING_MATCH = 0.
  LOOP AT SEARCH_TABLE.
    translate ABAP_CODE-CODE_LINE to upper case.
    IF ABAP_CODE- CODE_LINE CS SEARCH_TABLE -SEARCH_STRING.
      STRING_MATCH = 1.
      string_found = SEARCH_TABLE-SEARCH_STRING .
    ENDIF .
  ENDLOOP.
ENDFORM.                               " SEARCH_STRING