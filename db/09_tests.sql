-- =====================================================================
-- Package'lar testi: har bir biznes-qoida to'g'ri xato kodini qaytaradimi?
--   sqlplus miniabs/MiniAbs2026@//localhost:1521/FREEPDB1 @09_tests.sql
-- Oxirida ROLLBACK qilinadi. Faqat rad etilgan o'tkazmalar jurnalda qoladi,
-- chunki ular autonomous tranzaksiyada yoziladi (shunday bo'lishi kerak).
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

DECLARE
  v_ok      PLS_INTEGER := 0;
  v_fail    PLS_INTEGER := 0;
  v_a       VARCHAR2(20);
  v_b       VARCHAR2(20);
  v_usd     VARCHAR2(20);
  v_blocked VARCHAR2(20);
  v_doc     VARCHAR2(12);
  v_bal     NUMBER;
  v_before  NUMBER;
  v_id      NUMBER;
  v_acc     VARCHAR2(20);
  v_uid     NUMBER;
  v_name    VARCHAR2(100);
  v_role    VARCHAR2(10);

  PROCEDURE result(p_name IN VARCHAR2, p_passed IN BOOLEAN, p_info IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    IF p_passed THEN v_ok := v_ok + 1; ELSE v_fail := v_fail + 1; END IF;
    DBMS_OUTPUT.PUT_LINE(CASE WHEN p_passed THEN '[OK]   ' ELSE '[XATO] ' END || p_name ||
                         CASE WHEN p_info IS NOT NULL THEN '  -> ' || p_info END);
  END;

  -- Kutilgan xato kodi bilan tugashini tekshiradi
  PROCEDURE expect_transfer(p_name IN VARCHAR2, p_from IN VARCHAR2, p_to IN VARCHAR2,
                            p_amount IN NUMBER, p_code IN PLS_INTEGER) IS
    d VARCHAR2(12);
    b NUMBER;
  BEGIN
    pkg_transfer.transfer_money(p_from, p_to, p_amount, '00668', 'test', d, b);
    result(p_name, FALSE, 'xato kutilgandi, lekin o''tkazma bajarildi');
  EXCEPTION
    WHEN OTHERS THEN
      result(p_name, SQLCODE = p_code, SQLERRM);
  END;
BEGIN
  DBMS_SESSION.SET_IDENTIFIER('test');

  SELECT account_no INTO v_a FROM accounts
   WHERE status = 'A' AND currency_code = '000' AND balance > 5000000 ORDER BY account_no FETCH FIRST 1 ROW ONLY;
  SELECT account_no INTO v_b FROM accounts
   WHERE status = 'A' AND currency_code = '000' AND account_no <> v_a ORDER BY account_no DESC FETCH FIRST 1 ROW ONLY;
  SELECT account_no INTO v_usd FROM accounts
   WHERE status = 'A' AND currency_code = '840' FETCH FIRST 1 ROW ONLY;
  SELECT account_no INTO v_blocked FROM accounts
   WHERE status = 'B' AND currency_code = '000' FETCH FIRST 1 ROW ONLY;

  DBMS_OUTPUT.PUT_LINE('--- pkg_transfer ---');
  SELECT balance INTO v_before FROM accounts WHERE account_no = v_a;
  pkg_transfer.transfer_money(v_a, v_b, 1000000, '00668', 'test', v_doc, v_bal);
  result('Muvaffaqiyatli o''tkazma', v_bal = v_before - 1000000, v_doc || ', yangi qoldiq ' || v_bal);

  expect_transfer('Mablag'' yetarli emas',     v_a, v_b, 999999999999, -20001);
  expect_transfer('Qabul qiluvchi topilmadi',  v_a, '20206000000000000000', 1000, -20002);
  expect_transfer('O''ziga o''tkazma',         v_a, v_a, 1000, -20003);
  expect_transfer('Manfiy summa',              v_a, v_b, -5, -20004);
  expect_transfer('Bloklangan hisob',          v_a, v_blocked, 1000, -20005);
  expect_transfer('Valyuta mos emas',          v_a, v_usd, 1000, -20006);

  DBMS_OUTPUT.PUT_LINE('--- pkg_client ---');
  pkg_client.create_client('J', 'Test Testov Testovich', '31234567890123', '+998 90 000 00 00', 'Toshkent', v_id);
  result('Mijoz yaratish', v_id IS NOT NULL, 'ID ' || v_id);
  BEGIN
    pkg_client.create_client('J', 'Takror Mijoz', '31234567890123', '+998900000001', NULL, v_id);
    result('Takroriy PINFL', FALSE);
  EXCEPTION WHEN OTHERS THEN result('Takroriy PINFL', SQLCODE = -20010, SQLERRM);
  END;
  BEGIN
    pkg_client.create_client('J', 'Noto''g''ri PINFL', '123', '+998900000002', NULL, v_id);
    result('Noto''g''ri PINFL', FALSE);
  EXCEPTION WHEN OTHERS THEN result('Noto''g''ri PINFL', SQLCODE = -20011, SQLERRM);
  END;
  BEGIN
    pkg_client.create_client('J', 'Telefon Xato', '31234567890999', '12345', NULL, v_id);
    result('Noto''g''ri telefon', FALSE);
  EXCEPTION WHEN OTHERS THEN result('Noto''g''ri telefon', SQLCODE = -20012, SQLERRM);
  END;

  DBMS_OUTPUT.PUT_LINE('--- pkg_account ---');
  SELECT MAX(client_id) INTO v_id FROM clients WHERE status = 'A';
  pkg_account.open_account(v_id, '000', v_acc);
  result('Hisob ochish', LENGTH(v_acc) = 20, v_acc);
  BEGIN
    pkg_account.set_status(v_acc, 'B');
    result('Sababsiz bloklash', FALSE);
  EXCEPTION WHEN OTHERS THEN result('Sababsiz bloklash', SQLCODE = -20024, SQLERRM);
  END;
  pkg_account.set_status(v_acc, 'B', 'Test');
  result('Sabab bilan bloklash', TRUE);

  DBMS_OUTPUT.PUT_LINE('--- pkg_auth ---');
  pkg_auth.login('b.abdusalomov', 'Operator2026', v_uid, v_name, v_role);
  result('To''g''ri parol', v_role = 'OPERATOR', v_name);
  BEGIN
    pkg_auth.login('b.abdusalomov', 'xato', v_uid, v_name, v_role);
    result('Noto''g''ri parol', FALSE);
  EXCEPTION WHEN OTHERS THEN result('Noto''g''ri parol', SQLCODE = -20101, SQLERRM);
  END;

  DBMS_OUTPUT.PUT_LINE('--- trigger ---');
  BEGIN
    DELETE FROM transactions WHERE status = 'S' AND ROWNUM = 1;
    result('Bajarilgan hujjatni o''chirish taqiqi', FALSE);
  EXCEPTION WHEN OTHERS THEN result('Bajarilgan hujjatni o''chirish taqiqi', SQLCODE = -20030, SQLERRM);
  END;

  ROLLBACK;
  -- Noto'g'ri parol hisoblagichini qaytaramiz (u autonomous tranzaksiyada saqlangan)
  UPDATE app_users SET failed_attempts = 0 WHERE login = 'b.abdusalomov';
  COMMIT;
  DBMS_SESSION.CLEAR_IDENTIFIER;

  DBMS_OUTPUT.PUT_LINE('---');
  DBMS_OUTPUT.PUT_LINE('Jami: ' || v_ok || ' ta muvaffaqiyatli, ' || v_fail || ' ta xato');
END;
/
