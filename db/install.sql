-- =====================================================================
-- Mini-ABS: to'liq o'rnatish (MINIABS foydalanuvchisi ostida)
--   sqlplus miniabs/MiniAbs2026@//localhost:1521/FREEPDB1 @install.sql
-- Avval SYSDBA bilan 00_create_user.sql ishga tushirilgan bo'lishi kerak.
-- =====================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT == 1/8 Jadvallar
@@01_tables.sql
PROMPT == 2/8 pkg_util
@@02_pkg_util.sql
PROMPT == 3/8 pkg_auth
@@03_pkg_auth.sql
PROMPT == 4/8 pkg_client
@@04_pkg_client.sql
PROMPT == 5/8 pkg_account
@@05_pkg_account.sql
PROMPT == 6/8 pkg_transfer
@@06_pkg_transfer.sql
PROMPT == 7/8 Trigger'lar
@@07_triggers.sql

PROMPT == Kompilyatsiya xatolari
COLUMN name FORMAT A25
COLUMN text FORMAT A120
SELECT name, type, line, text FROM user_errors ORDER BY name, type, sequence;
BEGIN
  FOR r IN (SELECT COUNT(*) cnt FROM user_objects WHERE status = 'INVALID') LOOP
    IF r.cnt > 0 THEN
      RAISE_APPLICATION_ERROR(-20999, r.cnt || ' ta obyekt kompilyatsiya xatosi bilan. Yuqoridagi ro''yxatni ko''ring.');
    END IF;
  END LOOP;
END;
/

PROMPT == 8/8 Namunaviy ma'lumotlar
@@08_seed.sql

PROMPT
PROMPT O'rnatish muvaffaqiyatli yakunlandi.
EXIT
