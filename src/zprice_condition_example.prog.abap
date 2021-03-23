*&---------------------------------------------------------------------*
*& Report ZPRICE_CONDITION_EXAMPLE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zprice_condition_example.

DATA: go_price_condition TYPE REF TO zprice_condition,
      ls_price_header    TYPE zprice_header,
      lt_price_item      TYPE zprice_item.

ls_price_header-applicatio = 'V'.
ls_price_header-cond_no    = space.
ls_price_header-cond_type  = 'Z001'.
ls_price_header-cond_usage = 'A'.
ls_price_header-table_no   = '502'.
ls_price_header-valid_from = sy-datum.
ls_price_header-valid_to   = '99991231'.
ls_price_header-varkey     = '1000Z21000000906000000000001000008'. "VKORG+PLTYP+KUNNR+MATNR

lt_price_item = VALUE #( BASE lt_price_item ( applicatio = ls_price_header-applicatio
                                              cond_type  = ls_price_header-cond_type
                                              scaletype  = 'A'
                                              calctypcon = 'C'
                                              cond_value = '107'
                                              condcurr   = 'BRL'
                                              cond_p_unt = '1'
                                              cond_unit  = 'BB' ) ).

CREATE OBJECT go_price_condition.

go_price_condition->create(
  EXPORTING
    i_header             = ls_price_header  " Condition price header
    it_item              = lt_price_item    " Bapistructure of KONP with english field names
  EXCEPTIONS
    cond_no_not_found    = 1                " Erro ao ler ID da condição de preço
    valid_to_not_found   = 2                " Erro ao ler campo Valido até
    valid_from_not_found = 3                " Erro ao ler campo Valido desde
    error_where_clause   = 4                " Erro ao montar clausula where
    OTHERS               = 5 ).
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.

BREAK-POINT.
