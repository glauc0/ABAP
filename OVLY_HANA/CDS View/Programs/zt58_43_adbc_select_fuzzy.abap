*&---------------------------------------------------------------------*
*& Report zt58_43_adbc_select_fuzzy
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zt58_43_adbc_select_fuzzy.

TYPES: BEGIN OF lty_employee,
                client        TYPE snwd_employee-client,
                node_key      TYPE snwd_employee-node_key,
                employee_id   TYPE snwd_employee-employee_id,
                first_name    TYPE snwd_employee-first_name,
                middle_name   TYPE snwd_employee-middle_name,
                last_name     TYPE snwd_employee-last_name,
       END OF lty_employee,
       lty_t_emplyee TYPE SORTED TABLE OF lty_employee WITH NON-UNIQUE KEY client
                                                                           node_key.

DATA: gv_con_name TYPE dbcon-con_name,
      gv_nome TYPE snwd_employees-first_name,
      lt_employees TYPE lty_t_emplyee.

SELECT-OPTIONS:
  s_nome FOR gv_nome MATCHCODE OBJECT zt58_43_employee NO INTERVALS NO-EXTENSION LOWER CASE,
  s_con FOR gv_con_name DEFAULT 'LCA' NO INTERVALS NO-EXTENSION
  .

TRY.
cl_sql_connection=>get_connection(
  EXPORTING
    con_name = s_con-low
*    sharable = space
  RECEIVING
    con_ref  = DATA(lo_connection)
).

CATCH cx_sql_exception INTO DATA(lr_sql_error).
    cl_demo_output=>display_text( text = lr_sql_error->get_longtext( ) ).
    STOP.

ENDTRY.

    DATA(lr_statement) = lo_connection->create_statement( ).

TRY.

    lr_statement->set_param(
      EXPORTING
        data_ref = REF #( s_nome-low )
*        pos      = 0
*        ind_ref  =
*        inout    = c_param_in
*        is_lob   = space
    ).

    DATA(lv_statement) =
    |SELECT                                       | &&
    |   "CLIENT",                                 | &&
    |   "NODE_KEY",                               | &&
    |   "EMPLOYEE_ID",                            | &&
    |   "FIRST_NAME",                             | &&
    |   "MIDDLE_NAME",                            | &&
    |   "LAST_NAME"                               | &&
    |FROM "SAPHANADB"."SNWD_EMPLOYEES"            | &&
    |WHERE CONTAINS(                              | &&
    |( "FIRST_NAME", "MIDDLE_NAME", "LAST_NAME" ),| &&
    |  ?,                                         | &&
    |  FUZZY( 1 )                                 | &&
    |)                                            |.

    lr_statement->execute_query(
      EXPORTING
        statement             = lv_statement
*        hold_cursor           = space
*        write_syslog_on_error = abap_true
      RECEIVING
        result_set            = DATA(lo_result_set)
    ).

CATCH cx_sql_exception INTO lr_sql_error.
  cl_demo_output=>display_text( text = lr_sql_error->get_text( ) ).
  STOP.

CATCH cx_parameter_invalid INTO DATA(lr_parameter_error).
  cl_demo_output=>display_text( text = lr_parameter_error->get_text( ) ).
  STOP.


ENDTRY.

TRY.

  lo_result_set->set_param_table(
    EXPORTING
      itab_ref             = REF #( lt_employees )
*      corresponding_fields =
*      lob_fields           =
  ).

  lo_result_set->next_package(
*    EXPORTING
*      upto                  = 0
*      write_syslog_on_error = abap_true
    RECEIVING
      rows_ret              = DATA(lo_rows_ret)
).
CATCH cx_sql_exception.
CATCH cx_parameter_invalid_type.
CATCH cx_parameter_invalid.
ENDTRY.

TRY.
  lo_connection->close( ).
CATCH cx_sql_exception INTO lr_sql_error.
ENDTRY.

cl_demo_output=>display_data(
  EXPORTING
    value = lt_employees
*    name  =
).