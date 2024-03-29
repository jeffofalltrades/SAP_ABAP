report bcs_example_7.

* This report provides an example for sending an Excel
* attachment in Unicode Systems

constants:
  gc_tab  type c value cl_bcs_convert=>gc_tab ,
  gc_crlf type c value cl_bcs_convert=>gc_crlf .

parameters:
  mailto type ad_smtpadr
   default 'john.doe@crazy-company.com'.                    "#EC *

data send_request   type ref to cl_bcs.
data document       type ref to cl_document_bcs .
data recipient      type ref to if_recipient_bcs .
data bcs_exception  type ref to cx_bcs.

data main_text      type bcsy_text .
data binary_content type solix_tab.
data size           type so_obj_len.
data sent_to_all    type os_boolean.

start-of-selection.
  perform create_content.
  perform send.

*&---------------------------------------------------------------------*
*&      Form  send
*&---------------------------------------------------------------------*
form send.

  try.

*     -------- create persistent send request ------------------------
      send_request = cl_bcs=>create_persistent ( ).

*     -------- create and set document with attachment ---------------
*     create document object from internal table with text
      append 'Hello world!' to main_text .                   "#EC NOTEXT
      document = cl_document_bcs=>create_document (
        i_type    = 'RAW'
        i_text    = main_text
        i_subject = 'Test Created By BCS_EXAMPLE_7' ).      "#EC NOTEXT

*     add the spread sheet as attachment to document object
      document-> add_attachment(
        i_attachment_type    = 'xls'                        "#EC NOTEXT
        i_attachment_subject = 'ExampleSpreadSheet'         "#EC NOTEXT
        i_attachment_size    = size
        i_att_content_hex    = binary_content ).

*     add document object to send request
      send_request-> set_document( document ).

*     --------- add recipient (e-mail address) -----------------------
*     create recipient object
      recipient = cl_cam_address_bcs=>create_internet_address ( mailto ).

*     add recipient object to send request
      send_request-> add_recipient( recipient ).

*     ---------- send document ---------------------------------------
      sent_to_all = send_request->send ( i_with_error_screen = 'X' ).

      commit work .

      if sent_to_all is initial.
        message i500(sbcoms ) with mailto .
      else .
        message s022(so ).
      endif .

*   ------------ exception handling ----------------------------------
*   replace this rudimentary exception handling with your own one !!!
    catch cx_bcs into bcs_exception .
      message i865(so ) with bcs_exception ->error_type.
  endtry.

endform.                    "send

*&---------------------------------------------------------------------*
*&      Form  create_content
*&---------------------------------------------------------------------*
* Create Example Content
* 1) Write example text into a string
* 2) convert this string to solix_tab
*----------------------------------------------------------------------*
form create_content.

  data lv_string type string.
  data ls_t100 type t100.

* --------------------------------------------------------------
* as example content we use some system messages out of t100
* get them for all installed languages from db
* and write one line for each language into the spread sheet

* columns are separated by TAB and each line ends with CRLF

  concatenate 'This Is Just Example Text!'                  "#EC NOTEXT
              gc_crlf gc_crlf
              into lv_string .

* header line
  concatenate lv_string
              'MSGID'    gc_tab
              'MSGNO'    gc_tab
              'Language' gc_tab                             "#EC NOTEXT
              'Text'     gc_crlf                            "#EC NOTEXT
              into lv_string .

* data lines
  select * from t100 into ls_t100
    where arbgb = 'SO' and msgnr = '182'.

    concatenate lv_string
                ls_t100-arbgb gc_tab
                ls_t100-msgnr gc_tab
                ls_t100-sprsl gc_tab
                ls_t100-text  gc_crlf
                into lv_string .

  endselect.

  select * from t100 into ls_t100
    where arbgb = 'SO' and msgnr = '316'.

    concatenate lv_string
                ls_t100-arbgb gc_tab
                ls_t100-msgnr gc_tab
                ls_t100-sprsl gc_tab
                ls_t100-text  gc_crlf
                into lv_string .

  endselect.

* --------------------------------------------------------------
* convert the text string into UTF-16LE binary data including
* byte-order-mark. Mircosoft Excel prefers these settings
* all this is done by new class cl_bcs_convert (see note 1151257)

  try.
      cl_bcs_convert=> string_to_solix(
        exporting
          iv_string   = lv_string
          iv_codepage = '4103'  "suitable for MS Excel, leave empty
          iv_add_bom  = 'X'     "for other doc types
        importing
          et_solix  = binary_content
          ev_size   = size ).
    catch cx_bcs.
      message e445(so ).
  endtry.

endform.                    "create_content

*---------------------------------------------------------------
* NOTES:
*---------------------------------------------------------------
* UTF-16LE including the BOM (Byte order mark)
* is preferred by Microsoft Excel. If you want to create
* other binary content you may choose another codepage (e.g.
* '4110' (UTF-8) which is standard for e-mails).
* Find SAP codepage names in the drop down list
* for the codepage setting of node SMTP in transaction SCOT.
* Or: leave iv_codepage and iv_add_bom empty. Then the target
* codepage is set according to SAPconnect settings
*
* Important:
* SAP neither guarantees that the attachment created
* by this report can be opened by all Excel Versions nor
* that it can be opened by any 3rd party software at all