    *&---------------------------------------------------------------------*

    *&      Form  PREPARE_AND_SEND_MAIL

    *&---------------------------------------------------------------------*

    *       Prepares the message and sends the email

    *----------------------------------------------------------------------*

    FORM PREPARE_AND_SEND_MAIL .

     "data for e-mail sending

     DATA:

       lv_subject           TYPE so_obj_des,

       lv_message_body      TYPE bcsy_text,

       lv_message_line      LIKE LINE OF lv_message_body,

       lv_sender_mail       TYPE adr6-smtp_addr,

       lv_recipient_mail    TYPE adr6-smtp_addr,

       lv_RESULT            TYPE boolean,

       lv_recipients        TYPE TABLE OF uiys_iusr,

       ls_recipients        LIKE LINE OF lv_recipients.

       "Set the email receiver

       ls_recipients-email = ‘Email Receiver here’.

       APPEND ls_recipients TO lv_recipients.

       "Set the sender (optional)

       lv_sender_mail = ‘Sender Email (Optional)’.

       "Set the subject

       lv_subject = ‘Subject Here’.

       "Create the body

       lv_message_line = ‘Body Here’.

       APPEND lv_message_line TO lv_message_body.

       "Send the mail

       PERFORM send_mail USING lv_subject

                               lv_message_body

                               lv_sender_mail

                               lv_recipient_mail

                               lv_recipients

                      CHANGING lv_RESULT.

    ENDFORM.                    " PREPARE_AND_SEND_MAIL

    *&---------------------------------------------------------------------*

    *&      Form  SEND_MAIL

    *&---------------------------------------------------------------------*

    *       Sends the email

    *----------------------------------------------------------------------*

    *      -->SUBJECT         e-mail subject line

    *      -->MESSAGE_BODY    body of e-mail

    *      -->SENDER_MAIL     optional sender e-mail

    *      -->RECIPIENT_MAIL  optional single recipient field

    *      -->RECIPIENTS      table of e-mail receipients

    *      -->RESULT          error boolean

    *----------------------------------------------------------------------*

    FORM send_mail USING subject TYPE so_obj_des

                        message_body TYPE bcsy_text

                        sender_mail TYPE adr6-smtp_addr

                        recipient_mail TYPE adr6-smtp_addr

                        recipients TYPE table

               CHANGING result TYPE boolean.

    *Data Declaration

     DATA:

       lo_sender         TYPE REF TO if_sender_bcs VALUE IS INITIAL,

       l_send            TYPE adr6-smtp_addr ,

       l_rec             TYPE  adr6-smtp_addr ,

       itab              TYPE TABLE OF sval,

       ls_itab           TYPE sval,

       i_return,

       lo_send_request   TYPE REF TO cl_bcs VALUE IS INITIAL,

       ls_recipient      TYPE uiys_iusr,

       lo_recipient      TYPE REF TO if_recipient_bcs VALUE IS INITIAL,

       lv_recipient_uid  TYPE uname,

       lv_recipient_mail TYPE adr6-smtp_addr.

    *Prepare Mail Object

     CLASS cl_bcs DEFINITION LOAD.

     lo_send_request = cl_bcs=>create_persistent( ).

    * Message body and subject

     DATA: lo_document TYPE REF TO cl_document_bcs VALUE IS INITIAL.

     lo_document = cl_document_bcs=>create_document(

     i_type = 'RAW'

     i_text =  message_body

     i_subject = subject ).


    * Pass the document to send request

     lo_send_request->set_document( lo_document ).

     TRY.

         IF sender_mail IS NOT INITIAL.

           lo_sender = cl_cam_address_bcs=>create_internet_address( sender_mail ).

         ELSE.

           lo_sender = cl_sapuser_bcs=>create( sy-uname ).

         ENDIF.

    * Set sender

         lo_send_request->set_sender(

         EXPORTING

         i_sender = lo_sender ).

       CATCH cx_address_bcs.

         RETURN.

     ENDTRY.

    * Set  recipients

     IF recipients[] IS INITIAL.

       IF recipient_mail IS NOT INITIAL.

         lo_recipient = cl_cam_address_bcs=>create_internet_address( recipient_mail ).

       ELSE.

         lo_recipient = cl_sapuser_bcs=>create( sy-uname ).

       ENDIF.

       lo_send_request->add_recipient(

       EXPORTING

       i_recipient = lo_recipient

       i_express = 'X' ).

     ELSE.

       LOOP AT recipients INTO ls_recipient.

         IF ls_recipient-iusrid IS NOT INITIAL.

           lv_recipient_uid = ls_recipient-iusrid.

           lo_recipient = cl_sapuser_bcs=>create( lv_recipient_uid ).

         ELSEIF ls_recipient-email IS NOT INITIAL.

           lv_recipient_mail = ls_recipient-email .

           lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_recipient_mail ).

         ENDIF.

         lo_send_request->add_recipient(

             EXPORTING

             i_recipient = lo_recipient

             i_express = 'X' ).

       ENDLOOP.

     ENDIF.

     TRY.

    ** Send email

         lo_send_request->set_send_immediately( 'X' ).

         lo_send_request->send(

         EXPORTING

         i_with_error_screen = 'X'

         RECEIVING

         result = result ).

         COMMIT WORK.

         WAIT UP TO 1 SECONDS.

       CATCH cx_send_req_bcs.

         result = ''.

     ENDTRY.

    ENDFORM.                    "SEND_MAIL