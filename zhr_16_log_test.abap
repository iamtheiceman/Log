**&---------------------------------------------------------------------*
**& Report  ZHR_16_LOG_TEST
**&
**&---------------------------------------------------------------------*
**&
**&
**&---------------------------------------------------------------------*
REPORT zhr_16_LOG_test.

NODES peras.
TABLES pernr ##NEEDED.

INFOTYPES: 0002.

TYPES: BEGIN OF gty_empl,
         pernr TYPE pernr,
         fio   TYPE emnam,
       END OF gty_empl.

DATA: gt_outtab TYPE TABLE OF gty_empl,
      go_log    TYPE REF TO cl_hrpadru_log.

INITIALIZATION.
  go_log = NEW cl_hrpadru_log( ).

START-OF-SELECTION.
  GET peras.
  PERFORM get_data.

END-OF-SELECTION.
  PERFORM display_log.
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data.
  rp_provide_from_last p0002 space sy-datum sy-datum.
  IF pnp-sw-found > 0.
    APPEND INITIAL LINE TO gt_outtab ASSIGNING FIELD-SYMBOL(<ls_outtab>).
    IF <ls_outtab> IS ASSIGNED.
      <ls_outtab>-pernr = p0002-pernr.

*     Заполняем ФИО для отображения в узлах рядом с табельным номером
      pernr-ename = |{ p0002-nachn } { p0002-vorna } { p0002-midnm }|.

      IF p0002-inits IS NOT INITIAL.
        <ls_outtab>-fio = |{ p0002-nachn } { p0002-inits }|.

*       successful
        CALL METHOD go_log->add_employee_node
          EXPORTING
            im_pernr        = pernr
            im_add_messages = abap_true.
      ELSE.
        <ls_outtab>-fio = p0002-nachn.

        go_log->add_message_to_log_and_table(
          EXPORTING
            im_pernr           = pernr
            im_msg_id          = 'ZHR_16_TEST'
            im_msg_type        = 'W'
            im_msg_number      = '000'
            im_msg_msgv1       = CONV #( pernr-pernr )
        ).

        CALL METHOD go_log->add_employee_node
          EXPORTING
            im_pernr = pernr.

      ENDIF.

    ENDIF. " <ls_outtab> IS ASSIGNED.
  ENDIF. " pnp-sw-found > 0.
ENDFORM. " get_data.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LOG
*&---------------------------------------------------------------------*
FORM display_log.
  DATA: ls_smp_dyntxt TYPE smp_dyntxt,
        lv_button1    TYPE bal_s_push.

  ls_smp_dyntxt-icon_id   = icon_display.
  ls_smp_dyntxt-icon_text = 'Распечатать'(000).
  ls_smp_dyntxt-quickinfo = 'Распечатать'(000).

  lv_button1-active   = abap_true.
  lv_button1-def      = ls_smp_dyntxt.
  lv_button1-position = space.

  CALL METHOD go_log->display_log2
    EXPORTING
      im_add_statistics = abap_true
      im_tree_ontop     = 'N'
      im_main_form      = 'PRINT' " Call-back формы(FORM) печати справки
      im_button1        = lv_button1.

ENDFORM. " display_log.
*&---------------------------------------------------------------------*
*&      Form  PRINT
*&---------------------------------------------------------------------*
FORM print CHANGING ls_display_profile TYPE bal_s_cbuc.
  CONSTANTS: c_line_name TYPE zwww_values-var_name VALUE 'TABLE',
             c_form_name TYPE wwwdatatab-objid VALUE 'ZHR_16_TEST'.

  DATA: lt_values TYPE  zwww_values_t.

  CHECK sy-ucomm = '%EXT_PUSH1'. " Кнопка "Распечатать"

  CLEAR: lt_values.
  CALL FUNCTION 'ZWWW_PREPARE_TABLE'
    EXPORTING
      line_name    = c_line_name
    TABLES
      it_any_table = gt_outtab
      it_values    = lt_values.

  CALL FUNCTION 'ZWWW_OPENFORM'
    EXPORTING
      form_name   = c_form_name
      protect     = space
    TABLES
      it_values   = lt_values
    EXCEPTIONS
      printcancel = 1
      OTHERS      = 2.
  IF sy-subrc <> 0.
    MESSAGE ID 'ZHR_16_TEST' TYPE 'E' NUMBER 001.
  ENDIF. " CALL FUNCTION 'ZWWW_OPENFORM'

  CLEAR lt_values.
ENDFORM. " print.