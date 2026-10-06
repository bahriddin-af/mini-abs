-- =====================================================================
-- pkg_util: umumiy konstantalar, xato kodlari, joriy foydalanuvchi, audit
-- =====================================================================
CREATE OR REPLACE PACKAGE pkg_util AS

  c_mfo CONSTANT VARCHAR2(5) := '00014';               -- bank filiali kodi

  -- Xato kodlari (Java tomonda ham shu kodlar bo'yicha xabar ko'rsatiladi)
  e_insufficient_funds  CONSTANT PLS_INTEGER := -20001;
  e_to_acc_not_found    CONSTANT PLS_INTEGER := -20002;
  e_same_account        CONSTANT PLS_INTEGER := -20003;
  e_invalid_amount      CONSTANT PLS_INTEGER := -20004;
  e_account_blocked     CONSTANT PLS_INTEGER := -20005;
  e_currency_mismatch   CONSTANT PLS_INTEGER := -20006;
  e_from_acc_not_found  CONSTANT PLS_INTEGER := -20007;
  e_invalid_purpose     CONSTANT PLS_INTEGER := -20008;

  e_duplicate_tax_code  CONSTANT PLS_INTEGER := -20010;
  e_invalid_tax_code    CONSTANT PLS_INTEGER := -20011;
  e_invalid_phone       CONSTANT PLS_INTEGER := -20012;
  e_client_not_found    CONSTANT PLS_INTEGER := -20013;
  e_invalid_name        CONSTANT PLS_INTEGER := -20014;
  e_invalid_client_type CONSTANT PLS_INTEGER := -20015;

  e_client_blocked      CONSTANT PLS_INTEGER := -20020;
  e_account_not_found   CONSTANT PLS_INTEGER := -20021;
  e_status_unchanged    CONSTANT PLS_INTEGER := -20022;
  e_invalid_currency    CONSTANT PLS_INTEGER := -20023;
  e_reason_required     CONSTANT PLS_INTEGER := -20024;

  e_bad_credentials     CONSTANT PLS_INTEGER := -20101;
  e_user_locked         CONSTANT PLS_INTEGER := -20102;

  -- Ilovadagi foydalanuvchi: Java har bir so'rovda CLIENT_IDENTIFIER'ni o'rnatadi
  FUNCTION app_user RETURN VARCHAR2;

  PROCEDURE raise_error(p_code IN PLS_INTEGER, p_message IN VARCHAR2);

  PROCEDURE audit(p_table  IN VARCHAR2,
                  p_id     IN VARCHAR2,
                  p_action IN VARCHAR2,
                  p_column IN VARCHAR2 DEFAULT NULL,
                  p_old    IN VARCHAR2 DEFAULT NULL,
                  p_new    IN VARCHAR2 DEFAULT NULL);

  -- '+998 90 123 45 67' -> '+998901234567'
  FUNCTION normalize_phone(p_phone IN VARCHAR2) RETURN VARCHAR2;

END pkg_util;
/

CREATE OR REPLACE PACKAGE BODY pkg_util AS

  FUNCTION app_user RETURN VARCHAR2 IS
  BEGIN
    RETURN NVL(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), USER);
  END app_user;

  PROCEDURE raise_error(p_code IN PLS_INTEGER, p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(p_code, p_message);
  END raise_error;

  PROCEDURE audit(p_table  IN VARCHAR2,
                  p_id     IN VARCHAR2,
                  p_action IN VARCHAR2,
                  p_column IN VARCHAR2 DEFAULT NULL,
                  p_old    IN VARCHAR2 DEFAULT NULL,
                  p_new    IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    INSERT INTO audit_log (table_name, record_id, action, column_name, old_value, new_value, changed_by)
    VALUES (p_table, p_id, p_action, p_column,
            SUBSTR(p_old, 1, 400), SUBSTR(p_new, 1, 400), app_user);
  END audit;

  FUNCTION normalize_phone(p_phone IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN REGEXP_REPLACE(p_phone, '[^0-9+]', '');
  END normalize_phone;

END pkg_util;
/
