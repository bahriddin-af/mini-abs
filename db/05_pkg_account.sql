-- =====================================================================
-- pkg_account: hisob ochish, bloklash va hisoblar ro'yxati
--
-- Hisob raqam tuzilishi (20 xona):
--   balans hisobi (5) + valyuta (3) + kalit (1) + mijoz kodi (8) + tartib raqami (3)
--   masalan: 20206 000 7 00001001 001
-- Kalit raqam bu yerda soddalashtirilgan nazorat yig'indisi (og'irliklar 7-1-3).
-- Haqiqiy ABS'da Markaziy bank algoritmi ishlatiladi.
-- =====================================================================
CREATE OR REPLACE PACKAGE pkg_account AS

  FUNCTION generate_account_no(p_client_id IN NUMBER, p_currency_code IN VARCHAR2) RETURN VARCHAR2;

  PROCEDURE open_account(p_client_id     IN  NUMBER,
                         p_currency_code IN  VARCHAR2,
                         o_account_no    OUT VARCHAR2);

  -- p_status: A (faollashtirish) yoki B (bloklash, sabab majburiy)
  PROCEDURE set_status(p_account_no IN VARCHAR2,
                       p_status     IN VARCHAR2,
                       p_reason     IN VARCHAR2 DEFAULT NULL);

  -- p_tab: ALL | UZS | USD | B
  -- p_sort: no | client | balance | date (oxiriga _asc yoki _desc)
  FUNCTION get_accounts(p_search      IN VARCHAR2,
                        p_client_id   IN NUMBER,
                        p_balance_acc IN VARCHAR2,
                        p_min_balance IN NUMBER,
                        p_max_balance IN NUMBER,
                        p_opened_from IN DATE,
                        p_tab         IN VARCHAR2,
                        p_sort        IN VARCHAR2,
                        p_page        IN NUMBER,
                        p_page_size   IN NUMBER) RETURN SYS_REFCURSOR;

  PROCEDURE get_tab_counts(p_search      IN  VARCHAR2,
                           p_client_id   IN  NUMBER,
                           p_balance_acc IN  VARCHAR2,
                           p_min_balance IN  NUMBER,
                           p_max_balance IN  NUMBER,
                           p_opened_from IN  DATE,
                           o_all         OUT NUMBER,
                           o_uzs         OUT NUMBER,
                           o_usd         OUT NUMBER,
                           o_blocked     OUT NUMBER);

  -- Sahifa tepasidagi kartochkalar uchun
  PROCEDURE get_summary(o_total     OUT NUMBER,
                        o_uzs_total OUT NUMBER,
                        o_usd_total OUT NUMBER,
                        o_blocked   OUT NUMBER);

  -- O'tkazma formasi uchun: hisob egasining nomi (topilmasa NULL)
  FUNCTION get_owner_name(p_account_no IN VARCHAR2) RETURN VARCHAR2;

  -- O'tkazma formasidagi ro'yxat: berilgan valyutadagi barcha hisoblar
  FUNCTION get_accounts_by_currency(p_currency_code IN VARCHAR2) RETURN SYS_REFCURSOR;

END pkg_account;
/

CREATE OR REPLACE PACKAGE BODY pkg_account AS

  FUNCTION calc_key(p_body IN VARCHAR2) RETURN CHAR IS
    v_digits VARCHAR2(30) := pkg_util.c_mfo || p_body;
    v_sum    PLS_INTEGER := 0;
    v_w      PLS_INTEGER;
  BEGIN
    FOR i IN 1 .. LENGTH(v_digits) LOOP
      v_w   := CASE MOD(i, 3) WHEN 1 THEN 7 WHEN 2 THEN 1 ELSE 3 END;
      v_sum := v_sum + TO_NUMBER(SUBSTR(v_digits, i, 1)) * v_w;
    END LOOP;
    RETURN TO_CHAR(MOD(v_sum * 3, 10));
  END calc_key;

  FUNCTION generate_account_no(p_client_id IN NUMBER, p_currency_code IN VARCHAR2) RETURN VARCHAR2 IS
    v_type clients.client_type%TYPE;
    v_seq  PLS_INTEGER;
    v_bal  CHAR(5);
    v_body VARCHAR2(20);
  BEGIN
    SELECT client_type INTO v_type FROM clients WHERE client_id = p_client_id;

    SELECT NVL(MAX(TO_NUMBER(SUBSTR(account_no, 18, 3))), 0) + 1
      INTO v_seq
      FROM accounts
     WHERE client_id = p_client_id;

    v_bal  := CASE v_type WHEN 'J' THEN '20206' ELSE '20208' END;
    v_body := v_bal || p_currency_code || '0' || LPAD(p_client_id, 8, '0') || LPAD(v_seq, 3, '0');
    RETURN SUBSTR(v_body, 1, 8) || calc_key(v_body) || SUBSTR(v_body, 10);
  END generate_account_no;

  PROCEDURE open_account(p_client_id     IN  NUMBER,
                         p_currency_code IN  VARCHAR2,
                         o_account_no    OUT VARCHAR2) IS
    v_status clients.status%TYPE;
    v_cnt    PLS_INTEGER;
  BEGIN
    -- Mijoz qatorini bloklaymiz: bir vaqtda ikki operator hisob ochsa,
    -- tartib raqami takrorlanib qolmasligi uchun
    BEGIN
      SELECT status INTO v_status FROM clients WHERE client_id = p_client_id FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pkg_util.raise_error(pkg_util.e_client_not_found, 'Mijoz topilmadi: ' || p_client_id);
    END;

    IF v_status <> 'A' THEN
      pkg_util.raise_error(pkg_util.e_client_blocked, 'Bloklangan mijozga hisob ochib bo''lmaydi');
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM currencies WHERE currency_code = p_currency_code;
    IF v_cnt = 0 THEN
      pkg_util.raise_error(pkg_util.e_invalid_currency, 'Valyuta kodi noto''g''ri: ' || p_currency_code);
    END IF;

    o_account_no := generate_account_no(p_client_id, p_currency_code);

    INSERT INTO accounts (account_no, client_id, balance_acc, currency_code, opened_by)
    VALUES (o_account_no, p_client_id, SUBSTR(o_account_no, 1, 5), p_currency_code, pkg_util.app_user);
  END open_account;

  PROCEDURE set_status(p_account_no IN VARCHAR2,
                       p_status     IN VARCHAR2,
                       p_reason     IN VARCHAR2 DEFAULT NULL) IS
    v_status accounts.status%TYPE;
  BEGIN
    BEGIN
      SELECT status INTO v_status FROM accounts WHERE account_no = p_account_no FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pkg_util.raise_error(pkg_util.e_account_not_found, 'Hisob topilmadi: ' || p_account_no);
    END;

    IF v_status = p_status THEN
      pkg_util.raise_error(pkg_util.e_status_unchanged, 'Hisob allaqachon shu holatda');
    END IF;

    IF p_status = 'B' AND TRIM(p_reason) IS NULL THEN
      pkg_util.raise_error(pkg_util.e_reason_required, 'Bloklash sababini ko''rsating');
    END IF;

    UPDATE accounts
       SET status       = p_status,
           block_reason = CASE WHEN p_status = 'B' THEN TRIM(p_reason) END
     WHERE account_no = p_account_no;
  END set_status;

  FUNCTION get_accounts(p_search      IN VARCHAR2,
                        p_client_id   IN NUMBER,
                        p_balance_acc IN VARCHAR2,
                        p_min_balance IN NUMBER,
                        p_max_balance IN NUMBER,
                        p_opened_from IN DATE,
                        p_tab         IN VARCHAR2,
                        p_sort        IN VARCHAR2,
                        p_page        IN NUMBER,
                        p_page_size   IN NUMBER) RETURN SYS_REFCURSOR IS
    v_cur    SYS_REFCURSOR;
    v_size   PLS_INTEGER := LEAST(GREATEST(NVL(p_page_size, 10), 1), 100);
    v_offset PLS_INTEGER := (GREATEST(NVL(p_page, 1), 1) - 1) * v_size;
    v_q      VARCHAR2(200) := UPPER(TRIM(p_search));
    v_tab    VARCHAR2(3) := NVL(p_tab, 'ALL');
    v_sort   VARCHAR2(20) := NVL(LOWER(p_sort), 'date_desc');
  BEGIN
    OPEN v_cur FOR
      SELECT a.account_no, a.client_id, c.full_name AS client_name, c.client_type,
             cur.iso_code AS currency, a.balance, a.status, a.block_reason, a.opened_at,
             COUNT(*) OVER () AS total_rows
        FROM accounts a
        JOIN clients c      ON c.client_id = a.client_id
        JOIN currencies cur ON cur.currency_code = a.currency_code
       WHERE (v_q IS NULL OR a.account_no LIKE '%' || v_q || '%' OR UPPER(c.full_name) LIKE '%' || v_q || '%')
         AND (p_client_id   IS NULL OR a.client_id = p_client_id)
         AND (p_balance_acc IS NULL OR a.balance_acc = p_balance_acc)
         AND (p_min_balance IS NULL OR a.balance >= p_min_balance)
         AND (p_max_balance IS NULL OR a.balance <= p_max_balance)
         AND (p_opened_from IS NULL OR a.opened_at >= p_opened_from)
         AND (v_tab = 'ALL'
              OR (v_tab IN ('UZS', 'USD') AND cur.iso_code = v_tab)
              OR (v_tab = 'B' AND a.status = 'B'))
       ORDER BY
         CASE WHEN v_sort = 'no_asc'       THEN a.account_no END ASC,
         CASE WHEN v_sort = 'no_desc'      THEN a.account_no END DESC,
         CASE WHEN v_sort = 'client_asc'   THEN c.full_name  END ASC,
         CASE WHEN v_sort = 'client_desc'  THEN c.full_name  END DESC,
         CASE WHEN v_sort = 'balance_asc'  THEN a.balance    END ASC,
         CASE WHEN v_sort = 'balance_desc' THEN a.balance    END DESC,
         CASE WHEN v_sort = 'date_asc'     THEN a.opened_at  END ASC,
         a.opened_at DESC, a.account_no
      OFFSET v_offset ROWS FETCH NEXT v_size ROWS ONLY;
    RETURN v_cur;
  END get_accounts;

  PROCEDURE get_tab_counts(p_search      IN  VARCHAR2,
                           p_client_id   IN  NUMBER,
                           p_balance_acc IN  VARCHAR2,
                           p_min_balance IN  NUMBER,
                           p_max_balance IN  NUMBER,
                           p_opened_from IN  DATE,
                           o_all         OUT NUMBER,
                           o_uzs         OUT NUMBER,
                           o_usd         OUT NUMBER,
                           o_blocked     OUT NUMBER) IS
    v_q VARCHAR2(200) := UPPER(TRIM(p_search));
  BEGIN
    SELECT COUNT(*),
           COUNT(CASE WHEN a.currency_code = '000' THEN 1 END),
           COUNT(CASE WHEN a.currency_code = '840' THEN 1 END),
           COUNT(CASE WHEN a.status = 'B' THEN 1 END)
      INTO o_all, o_uzs, o_usd, o_blocked
      FROM accounts a
      JOIN clients c ON c.client_id = a.client_id
     WHERE (v_q IS NULL OR a.account_no LIKE '%' || v_q || '%' OR UPPER(c.full_name) LIKE '%' || v_q || '%')
       AND (p_client_id   IS NULL OR a.client_id = p_client_id)
       AND (p_balance_acc IS NULL OR a.balance_acc = p_balance_acc)
       AND (p_min_balance IS NULL OR a.balance >= p_min_balance)
       AND (p_max_balance IS NULL OR a.balance <= p_max_balance)
       AND (p_opened_from IS NULL OR a.opened_at >= p_opened_from);
  END get_tab_counts;

  PROCEDURE get_summary(o_total     OUT NUMBER,
                        o_uzs_total OUT NUMBER,
                        o_usd_total OUT NUMBER,
                        o_blocked   OUT NUMBER) IS
  BEGIN
    SELECT COUNT(*),
           NVL(SUM(CASE WHEN currency_code = '000' THEN balance END), 0),
           NVL(SUM(CASE WHEN currency_code = '840' THEN balance END), 0),
           COUNT(CASE WHEN status = 'B' THEN 1 END)
      INTO o_total, o_uzs_total, o_usd_total, o_blocked
      FROM accounts;
  END get_summary;

  FUNCTION get_owner_name(p_account_no IN VARCHAR2) RETURN VARCHAR2 IS
    v_name clients.full_name%TYPE;
  BEGIN
    SELECT c.full_name INTO v_name
      FROM accounts a JOIN clients c ON c.client_id = a.client_id
     WHERE a.account_no = p_account_no;
    RETURN v_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_owner_name;

  FUNCTION get_accounts_by_currency(p_currency_code IN VARCHAR2) RETURN SYS_REFCURSOR IS
    v_cur SYS_REFCURSOR;
  BEGIN
    OPEN v_cur FOR
      SELECT a.account_no, c.full_name AS client_name, a.balance, a.status
        FROM accounts a JOIN clients c ON c.client_id = a.client_id
       WHERE a.currency_code = p_currency_code
       ORDER BY c.full_name, a.account_no;
    RETURN v_cur;
  END get_accounts_by_currency;

END pkg_account;
/
