-- =====================================================================
-- pkg_client: mijozlarni yaratish, tahrirlash, bloklash va qidirish
-- =====================================================================
CREATE OR REPLACE PACKAGE pkg_client AS

  PROCEDURE create_client(p_type      IN  VARCHAR2,
                          p_full_name IN  VARCHAR2,
                          p_tax_code  IN  VARCHAR2,
                          p_phone     IN  VARCHAR2,
                          p_address   IN  VARCHAR2,
                          o_client_id OUT NUMBER);

  PROCEDURE update_client(p_client_id IN NUMBER,
                          p_full_name IN VARCHAR2,
                          p_tax_code  IN VARCHAR2,
                          p_phone     IN VARCHAR2,
                          p_address   IN VARCHAR2);

  PROCEDURE set_status(p_client_id IN NUMBER, p_status IN VARCHAR2);

  -- Sahifalangan ro'yxat. p_tab: ALL | J | Y | B
  -- p_sort: id | name | date (oxiriga _asc yoki _desc qo'shiladi)
  -- Har bir qatorda total_rows ustuni bor (jami yozuvlar soni)
  FUNCTION get_clients(p_search    IN VARCHAR2,
                       p_type      IN VARCHAR2,
                       p_status    IN VARCHAR2,
                       p_date_from IN DATE,
                       p_date_to   IN DATE,
                       p_tab       IN VARCHAR2,
                       p_sort      IN VARCHAR2,
                       p_page      IN NUMBER,
                       p_page_size IN NUMBER) RETURN SYS_REFCURSOR;

  -- Tablardagi sonlar (tabdan tashqari barcha filtrlar hisobga olinadi)
  PROCEDURE get_tab_counts(p_search    IN  VARCHAR2,
                           p_type      IN  VARCHAR2,
                           p_status    IN  VARCHAR2,
                           p_date_from IN  DATE,
                           p_date_to   IN  DATE,
                           o_all       OUT NUMBER,
                           o_person    OUT NUMBER,
                           o_company   OUT NUMBER,
                           o_blocked   OUT NUMBER);

  FUNCTION get_client(p_client_id IN NUMBER) RETURN SYS_REFCURSOR;

END pkg_client;
/

CREATE OR REPLACE PACKAGE BODY pkg_client AS

  -- Kiritilgan ma'lumotlarni tekshirish (create va update uchun umumiy)
  PROCEDURE validate(p_type      IN VARCHAR2,
                     p_full_name IN VARCHAR2,
                     p_tax_code  IN VARCHAR2,
                     p_phone     IN VARCHAR2) IS
  BEGIN
    IF p_type NOT IN ('J', 'Y') OR p_type IS NULL THEN
      pkg_util.raise_error(pkg_util.e_invalid_client_type, 'Mijoz turi noto''g''ri');
    END IF;

    IF LENGTH(TRIM(p_full_name)) < 3 OR p_full_name IS NULL THEN
      pkg_util.raise_error(pkg_util.e_invalid_name, 'Mijoz nomi kamida 3 ta belgidan iborat bo''lishi kerak');
    END IF;

    IF p_type = 'J' AND NOT REGEXP_LIKE(p_tax_code, '^[0-9]{14}$') THEN
      pkg_util.raise_error(pkg_util.e_invalid_tax_code, 'PINFL 14 ta raqamdan iborat bo''lishi kerak');
    ELSIF p_type = 'Y' AND NOT REGEXP_LIKE(p_tax_code, '^[0-9]{9}$') THEN
      pkg_util.raise_error(pkg_util.e_invalid_tax_code, 'INN 9 ta raqamdan iborat bo''lishi kerak');
    END IF;

    IF NOT REGEXP_LIKE(pkg_util.normalize_phone(p_phone), '^\+998[0-9]{9}$') THEN
      pkg_util.raise_error(pkg_util.e_invalid_phone, 'Telefon formati: +998 90 123 45 67');
    END IF;
  END validate;

  PROCEDURE create_client(p_type      IN  VARCHAR2,
                          p_full_name IN  VARCHAR2,
                          p_tax_code  IN  VARCHAR2,
                          p_phone     IN  VARCHAR2,
                          p_address   IN  VARCHAR2,
                          o_client_id OUT NUMBER) IS
  BEGIN
    validate(p_type, p_full_name, p_tax_code, p_phone);

    INSERT INTO clients (client_id, client_type, full_name, tax_code, phone, address, created_by)
    VALUES (seq_clients.NEXTVAL, p_type, TRIM(p_full_name), p_tax_code,
            pkg_util.normalize_phone(p_phone), TRIM(p_address), pkg_util.app_user)
    RETURNING client_id INTO o_client_id;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      pkg_util.raise_error(pkg_util.e_duplicate_tax_code,
        CASE p_type WHEN 'J' THEN 'Bu PINFL' ELSE 'Bu INN' END || ' bilan mijoz allaqachon mavjud');
  END create_client;

  PROCEDURE update_client(p_client_id IN NUMBER,
                          p_full_name IN VARCHAR2,
                          p_tax_code  IN VARCHAR2,
                          p_phone     IN VARCHAR2,
                          p_address   IN VARCHAR2) IS
    v_type clients.client_type%TYPE;
  BEGIN
    BEGIN
      SELECT client_type INTO v_type FROM clients WHERE client_id = p_client_id FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pkg_util.raise_error(pkg_util.e_client_not_found, 'Mijoz topilmadi: ' || p_client_id);
    END;

    validate(v_type, p_full_name, p_tax_code, p_phone);

    UPDATE clients
       SET full_name  = TRIM(p_full_name),
           tax_code   = p_tax_code,
           phone      = pkg_util.normalize_phone(p_phone),
           address    = TRIM(p_address),
           updated_at = SYSDATE,
           updated_by = pkg_util.app_user
     WHERE client_id = p_client_id;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      pkg_util.raise_error(pkg_util.e_duplicate_tax_code, 'Bu soliq raqami bilan boshqa mijoz mavjud');
  END update_client;

  PROCEDURE set_status(p_client_id IN NUMBER, p_status IN VARCHAR2) IS
    v_status clients.status%TYPE;
  BEGIN
    BEGIN
      SELECT status INTO v_status FROM clients WHERE client_id = p_client_id FOR UPDATE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pkg_util.raise_error(pkg_util.e_client_not_found, 'Mijoz topilmadi: ' || p_client_id);
    END;

    IF v_status = p_status THEN
      pkg_util.raise_error(pkg_util.e_status_unchanged, 'Mijoz allaqachon shu holatda');
    END IF;

    UPDATE clients
       SET status = p_status, updated_at = SYSDATE, updated_by = pkg_util.app_user
     WHERE client_id = p_client_id;
  END set_status;

  FUNCTION get_clients(p_search    IN VARCHAR2,
                       p_type      IN VARCHAR2,
                       p_status    IN VARCHAR2,
                       p_date_from IN DATE,
                       p_date_to   IN DATE,
                       p_tab       IN VARCHAR2,
                       p_sort      IN VARCHAR2,
                       p_page      IN NUMBER,
                       p_page_size IN NUMBER) RETURN SYS_REFCURSOR IS
    v_cur    SYS_REFCURSOR;
    v_size   PLS_INTEGER := LEAST(GREATEST(NVL(p_page_size, 10), 1), 100);
    v_offset PLS_INTEGER := (GREATEST(NVL(p_page, 1), 1) - 1) * v_size;
    v_q      VARCHAR2(200) := UPPER(TRIM(p_search));
    v_tab    VARCHAR2(3) := NVL(p_tab, 'ALL');
    v_sort   VARCHAR2(20) := NVL(LOWER(p_sort), 'date_desc');
  BEGIN
    OPEN v_cur FOR
      SELECT c.client_id, c.client_type, c.full_name, c.tax_code, c.phone, c.address,
             c.status, c.created_at,
             (SELECT COUNT(*) FROM accounts a WHERE a.client_id = c.client_id) AS account_count,
             COUNT(*) OVER () AS total_rows
        FROM clients c
       WHERE (v_q IS NULL
              OR UPPER(c.full_name) LIKE '%' || v_q || '%'
              OR c.tax_code LIKE v_q || '%'
              OR c.phone LIKE '%' || REPLACE(v_q, ' ') || '%')
         AND (p_type      IS NULL OR c.client_type = p_type)
         AND (p_status    IS NULL OR c.status = p_status)
         AND (p_date_from IS NULL OR c.created_at >= p_date_from)
         AND (p_date_to   IS NULL OR c.created_at <  p_date_to + 1)
         AND (v_tab = 'ALL'
              OR (v_tab IN ('J', 'Y') AND c.client_type = v_tab)
              OR (v_tab = 'B' AND c.status = 'B'))
       ORDER BY
         CASE WHEN v_sort = 'id_asc'    THEN c.client_id  END ASC,
         CASE WHEN v_sort = 'id_desc'   THEN c.client_id  END DESC,
         CASE WHEN v_sort = 'name_asc'  THEN c.full_name  END ASC,
         CASE WHEN v_sort = 'name_desc' THEN c.full_name  END DESC,
         CASE WHEN v_sort = 'date_asc'  THEN c.created_at END ASC,
         c.created_at DESC, c.client_id DESC
      OFFSET v_offset ROWS FETCH NEXT v_size ROWS ONLY;
    RETURN v_cur;
  END get_clients;

  PROCEDURE get_tab_counts(p_search    IN  VARCHAR2,
                           p_type      IN  VARCHAR2,
                           p_status    IN  VARCHAR2,
                           p_date_from IN  DATE,
                           p_date_to   IN  DATE,
                           o_all       OUT NUMBER,
                           o_person    OUT NUMBER,
                           o_company   OUT NUMBER,
                           o_blocked   OUT NUMBER) IS
    v_q VARCHAR2(200) := UPPER(TRIM(p_search));
  BEGIN
    SELECT COUNT(*),
           COUNT(CASE WHEN c.client_type = 'J' THEN 1 END),
           COUNT(CASE WHEN c.client_type = 'Y' THEN 1 END),
           COUNT(CASE WHEN c.status = 'B' THEN 1 END)
      INTO o_all, o_person, o_company, o_blocked
      FROM clients c
     WHERE (v_q IS NULL
            OR UPPER(c.full_name) LIKE '%' || v_q || '%'
            OR c.tax_code LIKE v_q || '%'
            OR c.phone LIKE '%' || REPLACE(v_q, ' ') || '%')
       AND (p_type      IS NULL OR c.client_type = p_type)
       AND (p_status    IS NULL OR c.status = p_status)
       AND (p_date_from IS NULL OR c.created_at >= p_date_from)
       AND (p_date_to   IS NULL OR c.created_at <  p_date_to + 1);
  END get_tab_counts;

  FUNCTION get_client(p_client_id IN NUMBER) RETURN SYS_REFCURSOR IS
    v_cur SYS_REFCURSOR;
  BEGIN
    OPEN v_cur FOR
      SELECT client_id, client_type, full_name, tax_code, phone, address, status, created_at
        FROM clients
       WHERE client_id = p_client_id;
    RETURN v_cur;
  END get_client;

END pkg_client;
/
