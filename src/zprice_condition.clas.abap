class ZPRICE_CONDITION definition
  public
  final
  create public .

public section.

  methods CREATE
    importing
      !I_HEADER type ZPRICE_HEADER
      !IT_ITEM type ZPRICE_ITEM
    exceptions
      COND_NO_NOT_FOUND
      VALID_TO_NOT_FOUND
      VALID_FROM_NOT_FOUND
      ERROR_WHERE_CLAUSE .
protected section.
private section.

  data GV_TABLENAME type DFIES-TABNAME .
  data GT_TABLE_FIELDS type CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE .

  methods CHECK_PRICE_EXISTS .
  methods CHANGE
    importing
      !I_HEADER_OLD type ZPRICE_HEADER
      !I_HEADER_NEW type ZPRICE_HEADER
    exporting
      !E_BAPIRET type BAPIRET2_T
    exceptions
      DELETE_ERROR
      CREATE_ERROR
      PRICE_NOT_FOUND .
  methods SET_NEW_PRICE_COND
    importing
      !I_HEADER type ZPRICE_HEADER
      !IT_ITEM type ZPRICE_ITEM .
ENDCLASS.



CLASS ZPRICE_CONDITION IMPLEMENTATION.


  METHOD change.
*--------------------------------------------------------------------*
* 1º Elimina registro na tabela de condição de preço
* 2º Cria o registro na tabela de condição de preço com data diferente
*--------------------------------------------------------------------*

    DATA: lt_bapicondct  TYPE TABLE OF bapicondct,
          lt_bapicondhd  TYPE TABLE OF bapicondhd,
          lt_bapicondit  TYPE TABLE OF bapicondit,
          lt_bapicondqs  TYPE TABLE OF bapicondqs,
          lt_bapicondvs  TYPE TABLE OF bapicondvs,
          lt_bapiret2    TYPE TABLE OF bapiret2,
          lt_bapiknumhs  TYPE TABLE OF bapiknumhs,
          lt_mem_initial TYPE TABLE OF cnd_mem_initial.

* Get header
    SELECT SINGLE *
      FROM konh
      INTO @DATA(ls_konh)
      WHERE knumh = @i_header_old-cond_no.
    IF sy-subrc <> 0.
      RAISE price_not_found.
    ENDIF.

    APPEND INITIAL LINE TO lt_bapicondct ASSIGNING FIELD-SYMBOL(<bapicondct>).
    MOVE-CORRESPONDING i_header_old TO <bapicondct>.
    <bapicondct>-operation = '003'.

    APPEND INITIAL LINE TO lt_bapicondhd ASSIGNING FIELD-SYMBOL(<bapicondhd>).
    <bapicondhd>-operation  = '003'.
    <bapicondhd>-cond_no    = ls_konh-knumh.
    <bapicondhd>-created_by = ls_konh-ernam.
    <bapicondhd>-creat_date = ls_konh-erdat.
    <bapicondhd>-cond_usage = ls_konh-kvewe.
    <bapicondhd>-table_no   = ls_konh-kotabnr.
    <bapicondhd>-applicatio = ls_konh-kappl.
    <bapicondhd>-cond_type  = ls_konh-kschl.
    <bapicondhd>-cond_type  = ls_konh-kschl.
    <bapicondhd>-varkey     = i_header_old-varkey.
    <bapicondhd>-valid_from = ls_konh-datab.
    <bapicondhd>-valid_to   = ls_konh-datbi.
    <bapicondhd>-searchterm = ls_konh-kosrt.
    <bapicondhd>-respons    = ls_konh-kzust.
    <bapicondhd>-promot_no  = ls_konh-knuma_pi.
    <bapicondhd>-sales_deal = ls_konh-knuma_ag.
    <bapicondhd>-salesquote = ls_konh-knuma_sq.
    <bapicondhd>-std_agrmnt = ls_konh-knuma_sd.
    <bapicondhd>-promotion  = ls_konh-aktnr.
    <bapicondhd>-rebagreemt = ls_konh-knuma_bo.
    <bapicondhd>-lic_no     = ls_konh-licno.
    <bapicondhd>-lic_date   = ls_konh-licdt.

* Get Items
    SELECT *
      FROM konp
      INTO TABLE @DATA(lt_konp)
      WHERE knumh = @i_header_old-cond_no.
    LOOP AT lt_konp ASSIGNING FIELD-SYMBOL(<konp>).

      APPEND INITIAL LINE TO lt_bapicondit ASSIGNING FIELD-SYMBOL(<bapicondit>).
      <bapicondit>-operation  = '003'.
      <bapicondit>-cond_no    = <konp>-knumh.
      <bapicondit>-cond_count = <konp>-kopos.
      <bapicondit>-applicatio = <konp>-kappl.
      <bapicondit>-cond_type  = <konp>-kschl.
      <bapicondit>-scaletype  = <konp>-stfkz.
      <bapicondit>-calctypcon = <konp>-krech.
      <bapicondit>-cond_value = <konp>-kbetr.
      <bapicondit>-condcurr   = <konp>-kwaeh.
      <bapicondit>-cond_p_unt = <konp>-kpein.
      <bapicondit>-cond_unit  = <konp>-kmein.
      <bapicondit>-cond_unit  = <konp>-kmein.

    ENDLOOP.

* Delete old records
    CALL FUNCTION 'BAPI_PRICES_CONDITIONS'
      EXPORTING
        pi_physical_deletion = 'X'
      TABLES
        ti_bapicondct        = lt_bapicondct
        ti_bapicondhd        = lt_bapicondhd
        ti_bapicondit        = lt_bapicondit
        ti_bapicondqs        = lt_bapicondqs
        ti_bapicondvs        = lt_bapicondvs
        to_bapiret2          = lt_bapiret2
        to_bapiknumhs        = lt_bapiknumhs
        to_mem_initial       = lt_mem_initial
      EXCEPTIONS
        update_error         = 1
        OTHERS               = 2.
    IF sy-subrc <> 0 OR
       line_exists( lt_bapiret2[ type = 'E' ] ).
      e_bapiret = lt_bapiret2.
      RAISE delete_error.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.

* Crate new records
    CLEAR: lt_bapicondqs,
           lt_bapicondvs,
           lt_bapiret2,
           lt_bapiknumhs,
           lt_mem_initial.

    MOVE-CORRESPONDING i_header_new TO <bapicondct>.
    <bapicondct>-operation = '004'.

    MOVE-CORRESPONDING i_header_new TO <bapicondhd>.
    <bapicondhd>-operation = '004'.

    LOOP AT lt_bapicondit ASSIGNING <bapicondit>.

      <bapicondit>-operation = '004'.

    ENDLOOP.

    CALL FUNCTION 'BAPI_PRICES_CONDITIONS'
      TABLES
        ti_bapicondct  = lt_bapicondct
        ti_bapicondhd  = lt_bapicondhd
        ti_bapicondit  = lt_bapicondit
        ti_bapicondqs  = lt_bapicondqs
        ti_bapicondvs  = lt_bapicondvs
        to_bapiret2    = lt_bapiret2
        to_bapiknumhs  = lt_bapiknumhs
        to_mem_initial = lt_mem_initial
      EXCEPTIONS
        update_error   = 1
        OTHERS         = 2.
    IF sy-subrc <> 0 OR
       line_exists( lt_bapiret2[ type = 'E' ] ).
      e_bapiret = lt_bapiret2.
      RAISE create_error.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.

  ENDMETHOD.


  METHOD check_price_exists.



  ENDMETHOD.


  METHOD create.

    TYPES: BEGIN OF ty_s_clause,
             line(72) TYPE c,
           END OF ty_s_clause.

    DATA: struct_type      TYPE REF TO cl_abap_structdescr, "Structure
          table_type       TYPE REF TO cl_abap_tabledescr,  "Table type
          dataref          TYPE REF TO data,                "Dynamic data
          gt_where_clauses TYPE STANDARD TABLE OF ty_s_clause WITH DEFAULT KEY,
          gt_condtab       TYPE TABLE OF hrcond.

    FIELD-SYMBOLS: <t_price_condition> TYPE STANDARD TABLE,
                   <s_price_condition> TYPE any.

* Obtêm nome tabela condição de preço
    gv_tablename = i_header-cond_usage && i_header-table_no.

* Obtêm campos da tabela
    struct_type ?= cl_abap_typedescr=>describe_by_name( gv_tablename ).
    gt_table_fields = struct_type->get_components( ).
    struct_type = cl_abap_structdescr=>create( gt_table_fields ).
    table_type  = cl_abap_tabledescr=>create( p_line_type = struct_type ).

    CREATE DATA dataref TYPE HANDLE table_type.
    ASSIGN dataref->* TO <t_price_condition>.   "Dynamic table

    CREATE DATA dataref TYPE HANDLE struct_type.
    ASSIGN dataref->* TO <s_price_condition>. "Dynamic Structure

    CONCATENATE sy-mandt i_header-applicatio i_header-cond_type i_header-varkey
    INTO DATA(lv_varkey) RESPECTING BLANKS.

    <s_price_condition> = lv_varkey.

* Cria clausula where
    LOOP AT gt_table_fields ASSIGNING FIELD-SYMBOL(<fields>).

      IF <fields>-name = 'MANDT' OR
         <fields>-name = 'KAPPL' OR
         <fields>-name = 'KSCHL'.
        CONTINUE.
      ENDIF.

      ASSIGN COMPONENT <fields>-name OF STRUCTURE <s_price_condition> TO FIELD-SYMBOL(<field_value>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CASE <fields>-name.
        WHEN 'DATBI'.
          <field_value> = i_header-valid_to.
        WHEN 'DATAB'.
          <field_value> = i_header-valid_from.
          CONTINUE.
        WHEN 'KNUMH'.
          <field_value> = i_header-cond_no.
          CONTINUE.
        WHEN OTHERS.
      ENDCASE.

      APPEND INITIAL LINE TO gt_condtab ASSIGNING FIELD-SYMBOL(<condtab>).
      <condtab>-field = <fields>-name.

      IF <fields>-name = 'DATBI'.
        <condtab>-opera = 'GE'.
        <condtab>-low   = sy-datum.
        CONTINUE.
      ELSE.
        <condtab>-opera = 'EQ'.
      ENDIF.

      <condtab>-low   = <field_value>.

    ENDLOOP.

    CALL FUNCTION 'RH_DYNAMIC_WHERE_BUILD'
      EXPORTING
        dbtable         = gv_tablename
      TABLES
        condtab         = gt_condtab
        where_clause    = gt_where_clauses
      EXCEPTIONS
        empty_condtab   = 1
        no_db_field     = 2
        unknown_db      = 3
        wrong_condition = 4
        OTHERS          = 5.
    IF sy-subrc <> 0.
      RAISE error_where_clause.
    ENDIF.

* Verifica se condição de preço existe
    SELECT *
      FROM (gv_tablename)
      INTO CORRESPONDING FIELDS OF TABLE <t_price_condition>
      WHERE (gt_where_clauses).
    IF sy-subrc = 0.

      READ TABLE <t_price_condition> ASSIGNING FIELD-SYMBOL(<price_condition>) INDEX 1.
      ASSIGN COMPONENT 'KNUMH' OF STRUCTURE <price_condition> TO FIELD-SYMBOL(<knumh_old>).
      IF sy-subrc <> 0.
        RAISE cond_no_not_found.
      ENDIF.

      ASSIGN COMPONENT 'DATAB' OF STRUCTURE <price_condition> TO FIELD-SYMBOL(<datab_old>).
      IF sy-subrc <> 0.
        RAISE valid_from_not_found.
      ENDIF.

      ASSIGN COMPONENT 'DATBI' OF STRUCTURE <price_condition> TO FIELD-SYMBOL(<datbi_old>).
      IF sy-subrc <> 0.
        RAISE valid_to_not_found.
      ENDIF.


      DATA(lv_header_old)  = i_header.
      DATA(lv_header_new)  = i_header.

      lv_header_new-cond_no    = lv_header_old-cond_no    = <knumh_old>.
      lv_header_new-valid_from = lv_header_old-valid_from = <datab_old>.
      lv_header_old-valid_to   = <datbi_old>.
      lv_header_new-valid_to   = sy-datum - 1.

* Modifica a condição antiga com a data do dia menos 1
      change(
        EXPORTING
          i_header_old       = lv_header_old
          i_header_new       = lv_header_new
        IMPORTING
          e_bapiret          = DATA(lt_bapiret)
        EXCEPTIONS
          price_not_found    = 1                " Condição de preço não encontrado
          delete_error       = 2                " Erro ao eliminar condição de preço antigo
          create_error       = 3                " Erro ao criar condição de preço com nova data
          OTHERS             = 4 ).
      IF sy-subrc <> 0.
        READ TABLE lt_bapiret ASSIGNING FIELD-SYMBOL(<bapiret>) WITH KEY type = 'E'.
        IF sy-subrc = 0.
          MESSAGE ID <bapiret>-id TYPE <bapiret>-type NUMBER <bapiret>-number
            WITH <bapiret>-message_v1 <bapiret>-message_v2 <bapiret>-message_v3 <bapiret>-message_v4.
        ENDIF.
        RETURN.
      ENDIF.

    ENDIF.

* Cria condição de preço valendo a partir de agora
    set_new_price_cond( EXPORTING i_header = i_header         " Condition price header
                                  it_item  = it_item  ).      " Bapistructure of KONP with english field names

  ENDMETHOD.


  METHOD set_new_price_cond.

    TYPES: ty_copy_record TYPE STANDARD TABLE OF komv WITH EMPTY KEY..

    DATA: lt_copy_records TYPE ty_copy_record,
          key_fields      TYPE komg,
          ls_komk         TYPE komk,
          ls_komp         TYPE komp,
          lv_vakey        TYPE vakey_long.

    READ TABLE it_item ASSIGNING FIELD-SYMBOL(<i_item>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

*- Fill Key fields
    lv_vakey = i_header-varkey.
    CALL FUNCTION 'SD_CONDITION_KOMG_FILL'
      EXPORTING
        p_kotabnr = i_header-table_no
        p_kvewe   = i_header-cond_usage
        p_vakey   = lv_vakey
      IMPORTING
        p_komg    = key_fields.

*- Fill KOMK
    MOVE-CORRESPONDING key_fields TO ls_komk.
    ls_komk-mandt = sy-mandt.

*- Fill KOMP
    MOVE-CORRESPONDING key_fields TO ls_komp.
    ls_komp-kposn = '000001'.

*- Fill KOMV
    lt_copy_records = VALUE #( BASE lt_copy_records ( kappl = <i_item>-applicatio
                                                      kschl = <i_item>-cond_type
                                                      kbetr = <i_item>-cond_value
                                                      krech = <i_item>-calctypcon
                                                      kpein = <i_item>-cond_p_unt
                                                      kmein = <i_item>-cond_unit
                                                      waers = <i_item>-condcurr
                                                      mandt = sy-mandt ) ).

    CALL FUNCTION 'RV_CONDITION_COPY'
      EXPORTING
        application              = i_header-applicatio
        condition_table          = i_header-table_no
        condition_type           = i_header-cond_type
        date_from                = i_header-valid_from
        date_to                  = i_header-valid_to
        enqueue                  = 'X'
        i_komk                   = ls_komk
        i_komp                   = ls_komp
        key_fields               = key_fields
        maintain_mode            = 'A' "Creation
        no_authority_check       = 'X'
        keep_old_records         = 'X'
        overlap_confirmed        = 'X'
      TABLES
        copy_records             = lt_copy_records
      EXCEPTIONS
        enqueue_on_record        = 01
        invalid_application      = 02
        invalid_condition_number = 03
        invalid_condition_type   = 04
        no_authority_ekorg       = 05
        no_authority_kschl       = 06
        no_authority_vkorg       = 07
        no_selection             = 08
        table_not_valid          = 09.
    IF sy-subrc = 0.

      CALL FUNCTION 'RV_CONDITION_SAVE'.

      CALL FUNCTION 'RV_CONDITION_RESET'.

      COMMIT WORK AND WAIT.

    ELSE.

      CALL FUNCTION 'RV_CONDITION_RESET'.

      ROLLBACK WORK.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
