*&---------------------------------------------------------------------*
*& Report ZDEMO_API
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdemo_api.


*-- Variable Definition
DATA: vl_client  TYPE REF TO if_http_client,
      vl_url     TYPE string,
      vl_http_rc TYPE sysubrc,
      vl_content TYPE string.

*-- Step 1 Create destination and assign a client
CALL METHOD cl_http_client=>create_by_destination
  EXPORTING
    destination        = 'DATAUSA'   " The connextion created in SM59
  IMPORTING
    client             = vl_client
  EXCEPTIONS
    argument_not_found = 1
    plugin_not_active  = 2
    internal_error     = 3
    OTHERS             = 4.

IF sy-subrc NE 0.
  MESSAGE 'Error creating destination!' TYPE 'E'.
ENDIF.

*-- Step 2 Add parameteres to url
*--  appending first parameter to URL --> drilldowns=Nation
*-- Source: https://datausa.io/api/data?drilldowns=Nation&measures=Population
CALL METHOD cl_http_server=>append_field_url
  EXPORTING
    name  = 'drilldowns'
    value = 'Nation'
  CHANGING
    url   = vl_url.

*-- Step 3 Add parameteres to url
*-- appending second parameter to URL --> measures=Population
*-- Source: https://datausa.io/api/data?drilldowns=Nation&measures=Population
CALL METHOD cl_http_server=>append_field_url
  EXPORTING
    name  = 'measures'
    value = 'Population'
  CHANGING
    url   = vl_url.

*-- add parameters to client
cl_http_utility=>set_request_uri( request = vl_client->request
uri  = vl_url ).

*-- set method
CALL METHOD vl_client->request->set_header_field
  EXPORTING
    name  = '~request_method'
    value = 'GET'.

*-- send the information
CALL METHOD vl_client->send
  EXCEPTIONS
    http_communication_failure = 1
    http_invalid_state         = 2
    http_processing_failed     = 3
    http_invalid_timeout       = 4
    OTHERS                     = 5.

IF sy-subrc NE 0.
  MESSAGE 'Error sending information!' TYPE 'E'.
ENDIF.

CALL METHOD vl_client->receive
  EXCEPTIONS
    http_communication_failure = 1
    http_invalid_state         = 2
    http_processing_failed     = 3
    OTHERS                     = 4.

IF sy-subrc NE 0.
  MESSAGE 'Error receiving information!' TYPE 'E'.
ENDIF.

vl_client->response->get_status( IMPORTING code = vl_http_rc ).


vl_content = vl_client->response->get_cdata( ).

CALL METHOD vl_client->close
  EXCEPTIONS
    http_invalid_state = 1
    OTHERS             = 2.

IF sy-subrc NE 0.
  MESSAGE 'Error closing communication' TYPE 'E'.
ENDIF.

WRITE:/ vl_content.
