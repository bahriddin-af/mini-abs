-- =====================================================================
-- pkg_auth: operatorlarni yaratish va tizimga kirish
-- Parol ochiq holda saqlanmaydi: SHA-256(salt || parol)
-- =====================================================================
CREATE OR REPLACE PACKAGE pkg_auth AS

  c_max_attempts CONSTANT PLS_INTEGER := 5;   -- shuncha xato urinishdan keyin bloklanadi

  PROCEDURE create_user(p_login     IN VARCHAR2,
                        p_password  IN VARCHAR2,
                        p_full_name IN VARCHAR2,
                        p_role      IN VARCHAR2 DEFAULT 'OPERATOR');

  -- Muvaffaqiyatli bo'lsa foydalanuvchi ma'lumotlarini qaytaradi,
  -- aks holda ORA-20101 / ORA-20102
  PROCEDURE login(p_login     IN  VARCHAR2,
                  p_password  IN  VARCHAR2,
                  o_user_id   OUT NUMBER,
                  o_full_name OUT VARCHAR2,
                  o_role      OUT VARCHAR2);

END pkg_auth;
/

CREATE OR REPLACE PACKAGE BODY pkg_auth AS

  FUNCTION hash_password(p_password IN VARCHAR2, p_salt IN VARCHAR2) RETURN VARCHAR2 IS
    v_hash VARCHAR2(64);
  BEGIN
    SELECT RAWTOHEX(STANDARD_HASH(p_salt || p_password, 'SHA256')) INTO v_hash FROM dual;
    RETURN v_hash;
  END hash_password;

  -- Xato urinishni alohida tranzaksiyada saqlaymiz: login xato bilan tugaganda
  -- asosiy tranzaksiya rollback bo'ladi, lekin hisoblagich saqlanib qolishi kerak
  PROCEDURE register_failure(p_user_id IN NUMBER) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    UPDATE app_users
       SET failed_attempts = failed_attempts + 1,
           is_active       = CASE WHEN failed_attempts + 1 >= c_max_attempts THEN 'N' ELSE is_active END
     WHERE user_id = p_user_id;
    COMMIT;
  END register_failure;

  -- Muvaffaqiyatli kirish ham alohida tranzaksiyada saqlanadi: login protsedurasi
  -- chaqiruvchining tranzaksiyasida qator bloklab qolmasligi kerak (aks holda
  -- keyingi xato urinishdagi autonomous UPDATE shu blokni kutib, deadlock bo'ladi)
  PROCEDURE register_success(p_user_id IN NUMBER) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    UPDATE app_users
       SET failed_attempts = 0, last_login_at = SYSDATE
     WHERE user_id = p_user_id;
    COMMIT;
  END register_success;

  PROCEDURE create_user(p_login     IN VARCHAR2,
                        p_password  IN VARCHAR2,
                        p_full_name IN VARCHAR2,
                        p_role      IN VARCHAR2 DEFAULT 'OPERATOR') IS
    v_salt VARCHAR2(32) := RAWTOHEX(SYS_GUID());
    v_hash VARCHAR2(64) := hash_password(p_password, v_salt);   -- private funksiyani SQL ichida chaqirib bo'lmaydi
  BEGIN
    INSERT INTO app_users (login, password_hash, salt, full_name, role)
    VALUES (LOWER(TRIM(p_login)), v_hash, v_salt, p_full_name, p_role);
  END create_user;

  PROCEDURE login(p_login     IN  VARCHAR2,
                  p_password  IN  VARCHAR2,
                  o_user_id   OUT NUMBER,
                  o_full_name OUT VARCHAR2,
                  o_role      OUT VARCHAR2) IS
    r app_users%ROWTYPE;
  BEGIN
    BEGIN
      SELECT * INTO r FROM app_users WHERE login = LOWER(TRIM(p_login));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pkg_util.raise_error(pkg_util.e_bad_credentials, 'Login yoki parol noto''g''ri');
    END;

    IF r.is_active = 'N' THEN
      pkg_util.raise_error(pkg_util.e_user_locked,
        'Foydalanuvchi bloklangan. Administratorga murojaat qiling');
    END IF;

    IF hash_password(p_password, r.salt) <> r.password_hash THEN
      register_failure(r.user_id);
      pkg_util.raise_error(pkg_util.e_bad_credentials, 'Login yoki parol noto''g''ri');
    END IF;

    register_success(r.user_id);

    o_user_id   := r.user_id;
    o_full_name := r.full_name;
    o_role      := r.role;
  END login;

END pkg_auth;
/
