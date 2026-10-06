-- =====================================================================
-- pkg_transfer: hisobdan hisobga o'tkazma, operatsiyalar jurnali, ko'chirma
-- =====================================================================
CREATE OR REPLACE PACKAGE pkg_transfer AS

  -- Pul o'tkazish. COMMIT qilmaydi: tranzaksiyani chaqiruvchi (Java) boshqaradi.
  -- Biznes-qoida buzilsa, rad etilgan operatsiya jurnalga yoziladi va ORA-200xx qaytadi.
  PROCEDURE transfer_money(p_from_acc     IN  VARCHAR2,
                           p_to_acc       IN  VARCHAR2,
                           p_amount       IN  NUMBER,
                           p_purpose_code IN  VARCHAR2,
                           p_description  IN  VARCHAR2,
                           o_doc_no       OUT VARCHAR2,
                           o_new_balance  OUT NUMBER);

  -- Operatsiyalar jurnali. p_tab: ALL | S | R
  -- p_account berilsa, direction ustuni IN/OUT bo'ladi (ko'chirma rejimi)
  FUNCTION get_journal(p_search       IN VARCHAR2,
                       p_account      IN VARCHAR2,
                       p_date_from    IN DATE,
                       p_date_to      IN DATE,
                       p_purpose_code IN VARCHAR2,
                       p_tab          IN VARCHAR2,
                       p_sort         IN VARCHAR2,
                       p_page         IN NUMBER,
                       p_page_size    IN NUMBER) RETURN SYS_REFCURSOR;

  PROCEDURE get_tab_counts(p_search       IN  VARCHAR2,
                           p_account      IN  VARCHAR2,
                           p_date_from    IN  DATE,
                           p_date_to      IN  DATE,
                           p_purpose_code IN  VARCHAR2,
                           o_all          OUT NUMBER,
                           o_success      OUT NUMBER,
                           o_rejected     OUT NUMBER,
                           o_turnover     OUT NUMBER);

  -- Ko'chirma: davr boshidagi qoldiq, kirim, chiqim va davr oxiridagi qoldiq
  PROCEDURE get_statement_summary(p_account   IN  VARCHAR2,
                                  p_date_from IN  DATE,
                                  p_date_to   IN  DATE,
                                  o_opening   OUT NUMBER,
                                  o_credit    OUT NUMBER,
                                  o_debit     OUT NUMBER,
                                  o_closing   OUT NUMBER);

  -- Ko'chirma qatorlari: har bir operatsiyadan keyingi qoldiq (analitik SUM OVER)
  FUNCTION get_statement(p_account   IN VARCHAR2,
                         p_date_from IN DATE,
                         p_date_to   IN DATE) RETURN SYS_REFCURSOR;

  -- O'tkazma sahifasidagi "oxirgi operatsiyalar" ro'yxati
  FUNCTION get_recent(p_account IN VARCHAR2, p_limit IN NUMBER DEFAULT 6) RETURN SYS_REFCURSOR;

END pkg_transfer;
/

CREATE OR REPLACE PACKAGE BODY pkg_transfer AS

  FUNCTION next_doc(o_id OUT NUMBER) RETURN VARCHAR2 IS
  BEGIN
    o_id := seq_transactions.NEXTVAL;
    RETURN 'TR-' || LPAD(o_id, 6, '0');
  END next_doc;

  -- Rad etilgan o'tkazmani alohida tranzaksiyada saqlaymiz:
  -- asosiy tranzaksiya ROLLBACK bo'lsa ham bu yozuv jurnalda qoladi
  PROCEDURE log_rejected(p_from_acc     IN VARCHAR2,
                         p_to_acc       IN VARCHAR2,
                         p_amount       IN NUMBER,
                         p_purpose_code IN VARCHAR2,
                         p_description  IN VARCHAR2,
                         p_error_code   IN PLS_INTEGER,
                         p_error_msg    IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_id  NUMBER;
    v_doc VARCHAR2(12) := next_doc(v_id);
  BEGIN
    INSERT INTO transactions (tran_id, doc_no, from_acc, to_acc, amount, purpose_code,
                              description, status, error_code, error_msg, created_by)
    VALUES (v_id, v_doc, p_from_acc, SUBSTR(p_to_acc, 1, 20), p_amount, p_purpose_code,
            p_description, 'R', 'ORA' || p_error_code, p_error_msg, pkg_util.app_user);
    COMMIT;
  END log_rejected;

  -- Hisobni bloklab o'qiydi; topilmasa account_no = NULL bo'lgan yozuv qaytadi
  FUNCTION lock_account(p_account_no IN VARCHAR2) RETURN accounts%ROWTYPE IS
    r accounts%ROWTYPE;
  BEGIN
    SELECT * INTO r FROM accounts WHERE account_no = p_account_no FOR UPDATE;
    RETURN r;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN r;
  END lock_account;

  PROCEDURE transfer_money(p_from_acc     IN  VARCHAR2,
                           p_to_acc       IN  VARCHAR2,
                           p_amount       IN  NUMBER,
                           p_purpose_code IN  VARCHAR2,
                           p_description  IN  VARCHAR2,
                           o_doc_no       OUT VARCHAR2,
                           o_new_balance  OUT NUMBER) IS
    v_from accounts%ROWTYPE;
    v_to   accounts%ROWTYPE;
    v_id   NUMBER;
    v_cnt  PLS_INTEGER;

    PROCEDURE reject(p_code IN PLS_INTEGER, p_msg IN VARCHAR2) IS
    BEGIN
      log_rejected(p_from_acc, p_to_acc, p_amount, p_purpose_code, p_description, p_code, p_msg);
      pkg_util.raise_error(p_code, p_msg);
    END reject;
  BEGIN
    -- 1. Oddiy tekshiruvlar (jurnalga yozilmaydi)
    IF p_amount IS NULL OR p_amount <= 0 THEN
      pkg_util.raise_error(pkg_util.e_invalid_amount, 'Summa 0 dan katta bo''lishi kerak');
    END IF;
    IF p_from_acc = p_to_acc THEN
      pkg_util.raise_error(pkg_util.e_same_account, 'Hisobning o''zidan o''ziga o''tkazib bo''lmaydi');
    END IF;
    SELECT COUNT(*) INTO v_cnt FROM payment_purposes WHERE purpose_code = p_purpose_code;
    IF v_cnt = 0 THEN
      pkg_util.raise_error(pkg_util.e_invalid_purpose, 'To''lov maqsadi kodi noto''g''ri');
    END IF;

    -- 2. Ikkala hisobni bloklaymiz. Doim kichik raqamli hisobdan boshlaymiz:
    --    A->B va B->A o'tkazmalari bir vaqtda kelsa ham deadlock bo'lmaydi
    IF p_from_acc < p_to_acc THEN
      v_from := lock_account(p_from_acc);
      v_to   := lock_account(p_to_acc);
    ELSE
      v_to   := lock_account(p_to_acc);
      v_from := lock_account(p_from_acc);
    END IF;

    -- 3. Biznes-qoidalar (buzilsa, rad etilgan operatsiya jurnalga yoziladi)
    IF v_from.account_no IS NULL THEN
      pkg_util.raise_error(pkg_util.e_from_acc_not_found, 'Jo''natuvchi hisob topilmadi');
    END IF;
    IF v_to.account_no IS NULL THEN
      reject(pkg_util.e_to_acc_not_found, 'Qabul qiluvchi hisob topilmadi');
    END IF;
    IF v_from.status <> 'A' THEN
      reject(pkg_util.e_account_blocked, 'Jo''natuvchi hisob bloklangan');
    END IF;
    IF v_to.status <> 'A' THEN
      reject(pkg_util.e_account_blocked, 'Qabul qiluvchi hisob bloklangan');
    END IF;
    IF v_from.currency_code <> v_to.currency_code THEN
      reject(pkg_util.e_currency_mismatch, 'Hisoblar valyutasi bir xil bo''lishi kerak');
    END IF;
    IF v_from.balance < p_amount THEN
      reject(pkg_util.e_insufficient_funds,
             'Mablag'' yetarli emas. Mavjud qoldiq: ' ||
             TRIM(TO_CHAR(v_from.balance, '999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS='', ''')));
    END IF;

    -- 4. Pulni ko'chiramiz va hujjatni yozamiz
    UPDATE accounts SET balance = balance - p_amount
     WHERE account_no = p_from_acc
     RETURNING balance INTO o_new_balance;

    UPDATE accounts SET balance = balance + p_amount
     WHERE account_no = p_to_acc;

    o_doc_no := next_doc(v_id);
    INSERT INTO transactions (tran_id, doc_no, from_acc, to_acc, amount, purpose_code,
                              description, status, created_by)
    VALUES (v_id, o_doc_no, p_from_acc, p_to_acc, p_amount, p_purpose_code,
            TRIM(p_description), 'S', pkg_util.app_user);
  END transfer_money;

  FUNCTION get_journal(p_search       IN VARCHAR2,
                       p_account      IN VARCHAR2,
                       p_date_from    IN DATE,
                       p_date_to      IN DATE,
                       p_purpose_code IN VARCHAR2,
                       p_tab          IN VARCHAR2,
                       p_sort         IN VARCHAR2,
                       p_page         IN NUMBER,
                       p_page_size    IN NUMBER) RETURN SYS_REFCURSOR IS
    v_cur    SYS_REFCURSOR;
    v_size   PLS_INTEGER := LEAST(GREATEST(NVL(p_page_size, 10), 1), 100);
    v_offset PLS_INTEGER := (GREATEST(NVL(p_page, 1), 1) - 1) * v_size;
    v_q      VARCHAR2(200) := UPPER(TRIM(p_search));
    v_tab    VARCHAR2(3) := NVL(p_tab, 'ALL');
    v_sort   VARCHAR2(20) := NVL(LOWER(p_sort), 'date_desc');
  BEGIN
    OPEN v_cur FOR
      SELECT t.tran_id, t.doc_no, t.tran_date,
             t.from_acc, cf.full_name AS from_name, cf.client_type AS from_type,
             t.to_acc,   ct.full_name AS to_name,   ct.client_type AS to_type,
             t.amount, t.purpose_code, p.name AS purpose_name, t.description,
             t.status, t.error_code, t.error_msg, t.created_by,
             CASE WHEN p_account IS NULL THEN NULL
                  WHEN t.to_acc = p_account THEN 'IN' ELSE 'OUT' END AS direction,
             COUNT(*) OVER () AS total_rows
        FROM transactions t
        JOIN accounts af         ON af.account_no = t.from_acc
        JOIN clients cf          ON cf.client_id = af.client_id
        LEFT JOIN accounts at2   ON at2.account_no = t.to_acc
        LEFT JOIN clients ct     ON ct.client_id = at2.client_id
        JOIN payment_purposes p  ON p.purpose_code = t.purpose_code
       WHERE (v_q IS NULL
              OR UPPER(t.doc_no) LIKE '%' || v_q || '%'
              OR t.from_acc LIKE '%' || v_q || '%'
              OR t.to_acc LIKE '%' || v_q || '%'
              OR UPPER(cf.full_name) LIKE '%' || v_q || '%'
              OR UPPER(ct.full_name) LIKE '%' || v_q || '%')
         AND (p_account      IS NULL OR t.from_acc = p_account OR t.to_acc = p_account)
         AND (p_date_from    IS NULL OR t.tran_date >= p_date_from)
         AND (p_date_to      IS NULL OR t.tran_date <  p_date_to + 1)
         AND (p_purpose_code IS NULL OR t.purpose_code = p_purpose_code)
         AND (v_tab = 'ALL' OR t.status = v_tab)
       ORDER BY
         CASE WHEN v_sort = 'doc_asc'     THEN t.doc_no    END ASC,
         CASE WHEN v_sort = 'doc_desc'    THEN t.doc_no    END DESC,
         CASE WHEN v_sort = 'amount_asc'  THEN t.amount    END ASC,
         CASE WHEN v_sort = 'amount_desc' THEN t.amount    END DESC,
         CASE WHEN v_sort = 'date_asc'    THEN t.tran_date END ASC,
         t.tran_date DESC, t.tran_id DESC
      OFFSET v_offset ROWS FETCH NEXT v_size ROWS ONLY;
    RETURN v_cur;
  END get_journal;

  PROCEDURE get_tab_counts(p_search       IN  VARCHAR2,
                           p_account      IN  VARCHAR2,
                           p_date_from    IN  DATE,
                           p_date_to      IN  DATE,
                           p_purpose_code IN  VARCHAR2,
                           o_all          OUT NUMBER,
                           o_success      OUT NUMBER,
                           o_rejected     OUT NUMBER,
                           o_turnover     OUT NUMBER) IS
    v_q VARCHAR2(200) := UPPER(TRIM(p_search));
  BEGIN
    SELECT COUNT(*),
           COUNT(CASE WHEN t.status = 'S' THEN 1 END),
           COUNT(CASE WHEN t.status = 'R' THEN 1 END),
           NVL(SUM(CASE WHEN t.status = 'S' THEN t.amount END), 0)
      INTO o_all, o_success, o_rejected, o_turnover
      FROM transactions t
      JOIN accounts af       ON af.account_no = t.from_acc
      JOIN clients cf        ON cf.client_id = af.client_id
      LEFT JOIN accounts at2 ON at2.account_no = t.to_acc
      LEFT JOIN clients ct   ON ct.client_id = at2.client_id
     WHERE (v_q IS NULL
            OR UPPER(t.doc_no) LIKE '%' || v_q || '%'
            OR t.from_acc LIKE '%' || v_q || '%'
            OR t.to_acc LIKE '%' || v_q || '%'
            OR UPPER(cf.full_name) LIKE '%' || v_q || '%'
            OR UPPER(ct.full_name) LIKE '%' || v_q || '%')
       AND (p_account      IS NULL OR t.from_acc = p_account OR t.to_acc = p_account)
       AND (p_date_from    IS NULL OR t.tran_date >= p_date_from)
       AND (p_date_to      IS NULL OR t.tran_date <  p_date_to + 1)
       AND (p_purpose_code IS NULL OR t.purpose_code = p_purpose_code);
  END get_tab_counts;

  PROCEDURE get_statement_summary(p_account   IN  VARCHAR2,
                                  p_date_from IN  DATE,
                                  p_date_to   IN  DATE,
                                  o_opening   OUT NUMBER,
                                  o_credit    OUT NUMBER,
                                  o_debit     OUT NUMBER,
                                  o_closing   OUT NUMBER) IS
    v_balance  accounts.balance%TYPE;
    v_after    NUMBER;   -- davr boshidan bugungacha bo'lgan sof o'zgarish
    v_from     DATE := NVL(p_date_from, DATE '1900-01-01');
    v_to       DATE := NVL(p_date_to, TRUNC(SYSDATE)) + 1;
  BEGIN
    BEGIN
      SELECT balance INTO v_balance FROM accounts WHERE account_no = p_account;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pkg_util.raise_error(pkg_util.e_account_not_found, 'Hisob topilmadi: ' || p_account);
    END;

    SELECT NVL(SUM(CASE WHEN to_acc = p_account THEN amount ELSE -amount END), 0),
           NVL(SUM(CASE WHEN to_acc   = p_account AND tran_date < v_to THEN amount END), 0),
           NVL(SUM(CASE WHEN from_acc = p_account AND tran_date < v_to THEN amount END), 0)
      INTO v_after, o_credit, o_debit
      FROM transactions
     WHERE status = 'S'
       AND (from_acc = p_account OR to_acc = p_account)
       AND tran_date >= v_from;

    -- Hozirgi qoldiqdan orqaga qarab davr boshidagi qoldiqni topamiz
    o_opening := v_balance - v_after;
    o_closing := o_opening + o_credit - o_debit;
  END get_statement_summary;

  FUNCTION get_statement(p_account   IN VARCHAR2,
                         p_date_from IN DATE,
                         p_date_to   IN DATE) RETURN SYS_REFCURSOR IS
    v_cur     SYS_REFCURSOR;
    v_opening NUMBER;
    v_credit  NUMBER;
    v_debit   NUMBER;
    v_closing NUMBER;
  BEGIN
    get_statement_summary(p_account, p_date_from, p_date_to, v_opening, v_credit, v_debit, v_closing);

    OPEN v_cur FOR
      SELECT t.tran_date, t.doc_no,
             CASE WHEN t.to_acc = p_account THEN t.from_acc ELSE t.to_acc END AS counter_acc,
             c.full_name AS counter_name,
             NVL(t.description, p.name) AS description,
             CASE WHEN t.to_acc   = p_account THEN t.amount END AS credit,
             CASE WHEN t.from_acc = p_account THEN t.amount END AS debit,
             v_opening + SUM(CASE WHEN t.to_acc = p_account THEN t.amount ELSE -t.amount END)
                         OVER (ORDER BY t.tran_date, t.tran_id ROWS UNBOUNDED PRECEDING) AS balance_after
        FROM transactions t
        JOIN payment_purposes p ON p.purpose_code = t.purpose_code
        JOIN accounts a ON a.account_no = CASE WHEN t.to_acc = p_account THEN t.from_acc ELSE t.to_acc END
        JOIN clients c  ON c.client_id = a.client_id
       WHERE t.status = 'S'
         AND (t.from_acc = p_account OR t.to_acc = p_account)
         AND (p_date_from IS NULL OR t.tran_date >= p_date_from)
         AND (p_date_to   IS NULL OR t.tran_date <  p_date_to + 1)
       ORDER BY t.tran_date, t.tran_id;
    RETURN v_cur;
  END get_statement;

  FUNCTION get_recent(p_account IN VARCHAR2, p_limit IN NUMBER DEFAULT 6) RETURN SYS_REFCURSOR IS
    v_cur SYS_REFCURSOR;
  BEGIN
    OPEN v_cur FOR
      SELECT t.doc_no, t.tran_date, t.amount, t.status,
             CASE WHEN t.to_acc = p_account THEN 'IN' ELSE 'OUT' END AS direction,
             CASE WHEN t.to_acc = p_account THEN t.from_acc ELSE t.to_acc END AS counter_acc,
             NVL(c.full_name, t.to_acc) AS counter_name,
             c.client_type AS counter_type
        FROM transactions t
        LEFT JOIN accounts a ON a.account_no = CASE WHEN t.to_acc = p_account THEN t.from_acc ELSE t.to_acc END
        LEFT JOIN clients c  ON c.client_id = a.client_id
       WHERE t.from_acc = p_account OR t.to_acc = p_account
       ORDER BY t.tran_date DESC, t.tran_id DESC
       FETCH FIRST NVL(p_limit, 6) ROWS ONLY;
    RETURN v_cur;
  END get_recent;

END pkg_transfer;
/
