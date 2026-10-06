-- =====================================================================
-- Namunaviy ma'lumotlar: 3 operator, 48 mijoz, ~65 hisob, ~84 o'tkazma.
-- Mijoz, hisob va o'tkazmalar package'lar orqali yaratiladi, ya'ni
-- haqiqiy foydalanishdagi barcha tekshiruvlardan o'tadi.
-- Sanalar o'tmishga surilgani uchun shu vaqtda audit va himoya trigger'lari o'chiriladi.
-- =====================================================================
ALTER TRIGGER trg_clients_audit DISABLE;
ALTER TRIGGER trg_accounts_audit DISABLE;
ALTER TRIGGER trg_transactions_protect DISABLE;

DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(100);
  sur   t_list := t_list('Abdullayev', 'Karimov', 'Tursunov', 'Rahimov', 'Yusupov', 'Saidov', 'Ergashev',
                         'Xolmatov', 'Nazarov', 'Qodirov', 'Mirzayev', 'Sobirov', 'Aliyev', 'Hasanov', 'Umarov');
  male  t_list := t_list('Jasur', 'Bekzod', 'Sardor', 'Otabek', 'Javohir', 'Dilshod', 'Aziz', 'Sherzod',
                         'Rustam', 'Timur', 'Bobur', 'Ulug''bek');
  fem   t_list := t_list('Nilufar', 'Malika', 'Dilnoza', 'Gulnora', 'Madina', 'Kamola', 'Shahnoza',
                         'Zarina', 'Mohira', 'Sevara');
  fath  t_list := t_list('Karim', 'Rustam', 'Alisher', 'Olim', 'Akmal', 'Bahodir', 'Anvar', 'Shavkat', 'Erkin', 'Murod');
  orgs  t_list := t_list('"Samarqand Tekstil" MChJ', '"Orient Logistics" AJ', '"Toshkent Agro Invest" MChJ',
                         '"Navoiy Qurilish Servis" MChJ', '"Farg''ona Meva Eksport" MChJ', '"Buxoro Gilam" XK',
                         '"Silk Road Soft" MChJ', '"Andijon Avto Detal" MChJ');
  regs  t_list := t_list('Toshkent sh., Yunusobod t.', 'Toshkent sh., Chilonzor t.', 'Samarqand sh.',
                         'Buxoro sh.', 'Farg''ona sh.', 'Namangan sh.', 'Andijon sh.', 'Navoiy sh.');
  codes t_list := t_list('90', '91', '93', '94', '97', '99');
  ops   t_list := t_list('b.abdusalomov', 'k.saidova');

  TYPE t_accs IS TABLE OF VARCHAR2(20);
  v_uzs     t_accs := t_accs();
  v_org_cnt PLS_INTEGER := 0;
  v_id      NUMBER;
  v_acc     VARCHAR2(20);
  v_doc     VARCHAR2(12);
  v_bal     NUMBER;
  v_type    CHAR(1);
  v_name    VARCHAR2(200);
  v_tax     VARCHAR2(14);
  v_reg     DATE;
  v_date    DATE;
  v_from    VARCHAR2(20);
  v_to      VARCHAR2(20);
  v_amt     NUMBER;
  v_pur     VARCHAR2(5);
  v_female  BOOLEAN;

  FUNCTION pick(p IN t_list) RETURN VARCHAR2 IS
  BEGIN
    RETURN p(TRUNC(DBMS_RANDOM.VALUE(1, p.COUNT + 1)));
  END;

  FUNCTION digits(n IN PLS_INTEGER) RETURN VARCHAR2 IS
    v VARCHAR2(20);
  BEGIN
    FOR i IN 1 .. n LOOP
      v := v || TRUNC(DBMS_RANDOM.VALUE(0, 10));
    END LOOP;
    RETURN v;
  END;
BEGIN
  DBMS_RANDOM.SEED(20261006);
  DBMS_SESSION.SET_IDENTIFIER('admin');

  pkg_auth.create_user('admin',         'Admin2026!',   'Tizim administratori',  'ADMIN');
  pkg_auth.create_user('b.abdusalomov', 'Operator2026', 'Bahriddin Abdusalomov', 'OPERATOR');
  pkg_auth.create_user('k.saidova',     'Operator2026', 'Kamola Saidova',        'OPERATOR');

  -- ---------- Mijozlar va hisoblar ----------
  FOR i IN 1 .. 48 LOOP
    IF MOD(i, 6) = 3 AND v_org_cnt < orgs.COUNT THEN
      v_org_cnt := v_org_cnt + 1;
      v_type := 'Y';
      v_name := orgs(v_org_cnt);
      v_tax  := '30' || digits(7);
    ELSE
      v_type   := 'J';
      v_female := DBMS_RANDOM.VALUE < 0.42;
      IF v_female THEN
        v_name := pick(sur) || 'a ' || pick(fem) || ' ' || pick(fath) || 'ovna';
        v_tax  := '4' || digits(13);
      ELSE
        v_name := pick(sur) || ' ' || pick(male) || ' ' || pick(fath) || 'ovich';
        v_tax  := '3' || digits(13);
      END IF;
    END IF;

    DBMS_SESSION.SET_IDENTIFIER(pick(ops));
    pkg_client.create_client(v_type, v_name, v_tax, '+998' || pick(codes) || digits(7), pick(regs), v_id);

    v_reg := DATE '2025-01-10' + TRUNC(DBMS_RANDOM.VALUE(0, TRUNC(SYSDATE) - DATE '2025-01-10' - 14));
    UPDATE clients SET created_at = v_reg WHERE client_id = v_id;

    pkg_account.open_account(v_id, '000', v_acc);
    UPDATE accounts
       SET opened_at = v_reg + TRUNC(DBMS_RANDOM.VALUE(0, 5)),
           balance   = CASE v_type
                         WHEN 'Y' THEN TRUNC(DBMS_RANDOM.VALUE(50, 900)) * 1000000
                         ELSE TRUNC(DBMS_RANDOM.VALUE(2, 30)) * 1000000 + TRUNC(DBMS_RANDOM.VALUE(0, 1000)) * 1000
                       END
     WHERE account_no = v_acc;
    v_uzs.EXTEND;
    v_uzs(v_uzs.COUNT) := v_acc;

    IF v_type = 'Y' OR DBMS_RANDOM.VALUE < 0.3 THEN
      pkg_account.open_account(v_id, '840', v_acc);
      UPDATE accounts
         SET opened_at = LEAST(v_reg + TRUNC(DBMS_RANDOM.VALUE(5, 60)), TRUNC(SYSDATE) - 1),
             balance   = TRUNC(DBMS_RANDOM.VALUE(100, CASE v_type WHEN 'Y' THEN 90000 ELSE 5000 END))
       WHERE account_no = v_acc;
    END IF;
  END LOOP;

  -- Hisoblarni saqlaymiz: rad etilgan o'tkazmalar autonomous tranzaksiyada yoziladi
  -- va faqat commit qilingan hisoblarni ko'radi
  COMMIT;

  -- ---------- O'tkazmalar: oxirgi 12 kun, ish vaqtida ----------
  FOR i IN 1 .. 84 LOOP
    v_from := v_uzs(TRUNC(DBMS_RANDOM.VALUE(1, v_uzs.COUNT + 1)));
    LOOP
      v_to := v_uzs(TRUNC(DBMS_RANDOM.VALUE(1, v_uzs.COUNT + 1)));
      EXIT WHEN v_to <> v_from;
    END LOOP;

    v_pur := CASE TRUNC(DBMS_RANDOM.VALUE(0, 5))
               WHEN 0 THEN '00101' WHEN 1 THEN '00302' WHEN 2 THEN '00502' ELSE '00668' END;
    v_amt := TRUNC(DBMS_RANDOM.VALUE(1, 40)) * CASE v_pur WHEN '00101' THEN 500000 ELSE 100000 END;
    IF MOD(i, 13) = 0 THEN
      v_amt := 5000000000;   -- ataylab katta summa: rad etilgan operatsiya namunasi
    END IF;

    v_date := TRUNC(SYSDATE) - 12 + FLOOR((i - 1) / 7) + 9 / 24
              + MOD(i - 1, 7) * 75 / 1440 + TRUNC(DBMS_RANDOM.VALUE(0, 60)) / 1440;

    DBMS_SESSION.SET_IDENTIFIER(pick(ops));
    BEGIN
      pkg_transfer.transfer_money(v_from, v_to, v_amt, v_pur, NULL, v_doc, v_bal);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;  -- rad etilgan o'tkazma pkg_transfer ichida jurnalga yozilgan, davom etamiz
    END;

    -- Har bir chaqiruv aynan bitta yozuv qo'shadi (bajarilgan yoki rad etilgan)
    UPDATE transactions SET tran_date = v_date
     WHERE tran_id = (SELECT MAX(tran_id) FROM transactions);
  END LOOP;

  COMMIT;
END;
/

ALTER TRIGGER trg_clients_audit ENABLE;
ALTER TRIGGER trg_accounts_audit ENABLE;
ALTER TRIGGER trg_transactions_protect ENABLE;

-- ---------- Audit jurnalida tarix paydo bo'lishi uchun bir nechta amallar ----------
DECLARE
  v_n PLS_INTEGER := 0;
BEGIN
  DBMS_SESSION.SET_IDENTIFIER('k.saidova');
  FOR r IN (SELECT client_id FROM clients WHERE client_type = 'J' AND MOD(client_id, 16) = 5) LOOP
    pkg_client.set_status(r.client_id, 'B');
    FOR a IN (SELECT account_no FROM accounts WHERE client_id = r.client_id) LOOP
      pkg_account.set_status(a.account_no, 'B', 'Sud qarori');
    END LOOP;
    v_n := v_n + 1;
  END LOOP;

  FOR a IN (SELECT account_no FROM accounts
             WHERE status = 'A' AND currency_code = '000' AND MOD(client_id, 19) = 7) LOOP
    pkg_account.set_status(a.account_no, 'B', 'Soliq organi talabi');
  END LOOP;

  DBMS_SESSION.SET_IDENTIFIER('b.abdusalomov');
  UPDATE clients SET phone = '+998901234567', updated_at = SYSDATE, updated_by = 'b.abdusalomov'
   WHERE client_id = 1001;
  COMMIT;
  DBMS_SESSION.CLEAR_IDENTIFIER;
END;
/

PROMPT
PROMPT Natija:
SELECT (SELECT COUNT(*) FROM clients)                           AS mijozlar,
       (SELECT COUNT(*) FROM accounts)                          AS hisoblar,
       (SELECT COUNT(*) FROM transactions WHERE status = 'S')   AS bajarilgan,
       (SELECT COUNT(*) FROM transactions WHERE status = 'R')   AS rad_etilgan,
       (SELECT COUNT(*) FROM audit_log)                         AS audit_yozuvlari
  FROM dual;
