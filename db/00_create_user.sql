-- =====================================================================
-- Mini-ABS: sxema (foydalanuvchi) yaratish
-- SYSDBA sifatida ishga tushiriladi:
--   sqlplus / as sysdba @00_create_user.sql
-- Serverda PDB nomi va parolni o'zingiznikiga almashtiring.
-- DIQQAT: MINIABS foydalanuvchisi mavjud bo'lsa, u barcha ma'lumotlari
-- bilan o'chirib, qaytadan yaratiladi.
-- =====================================================================
DEFINE pdb_name = FREEPDB1
DEFINE app_password = MiniAbs2026

WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION SET CONTAINER = &pdb_name;

DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_users WHERE username = 'MINIABS';
  IF v_cnt > 0 THEN
    EXECUTE IMMEDIATE 'DROP USER miniabs CASCADE';
  END IF;
END;
/

CREATE USER miniabs IDENTIFIED BY "&app_password"
  DEFAULT TABLESPACE users
  QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO miniabs;

PROMPT MINIABS foydalanuvchisi yaratildi.
EXIT
