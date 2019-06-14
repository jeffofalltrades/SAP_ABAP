ASSIGN ('(program name)variable name' to <your field symbol>






*&---------------------------------------------------------------------*
*& Module Pool       ZTEST_JM
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*


PROGRAM  ztest_jm.

DATA: new_table TYPE REF TO data.
DATA: new_line  TYPE REF TO data.

FIELD-SYMBOLS: <l_table> TYPE ANY TABLE,
<l_line>  TYPE ANY,
<l_field> TYPE ANY.


ASSIGN new_table->* TO <l_table>.
CREATE DATA new_line LIKE LINE OF <l_table>.
ASSIGN new_line->* TO <l_line>.

"WRITING TO DYNAMIC TABLE
DO 30 TIMES.
  ASSIGN COMPONENT 'SUBRC' OF STRUCTURE <l_line> TO <l_field>.
  <l_field> = sy-index.
  INSERT <l_line> INTO TABLE <l_table>.
ENDDO.

"READING FROM DYNAMIC TABLE
LOOP AT <l_table> ASSIGNING <l_line>.
  ASSIGN COMPONENT 'SUBRC' OF STRUCTURE <l_line> TO <l_field>.
  WRITE <l_field>.
ENDLOOP.