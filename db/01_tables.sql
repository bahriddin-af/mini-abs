-- =====================================================================
-- Mini-ABS: jadvallar, sequence'lar, index'lar va ma'lumotnomalar
-- =====================================================================

-- ---------- Ma'lumotnomalar ----------
CREATE TABLE currencies (
  currency_code CHAR(3)      PRIMARY KEY,          -- '000' = UZS, '840' = USD
  iso_code      CHAR(3)      NOT NULL,
  name          VARCHAR2(50) NOT NULL,
  CONSTRAINT uq_currencies_iso UNIQUE (iso_code)
);

CREATE TABLE payment_purposes (
  purpose_code VARCHAR2(5)   PRIMARY KEY,
  name         VARCHAR2(100) NOT NULL
);

-- ---------- Tizim foydalanuvchilari (operatorlar) ----------
CREATE TABLE app_users (
  user_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  login           VARCHAR2(50)  NOT NULL,
  password_hash   VARCHAR2(64)  NOT NULL,              -- SHA-256 (hex)
  salt            VARCHAR2(32)  NOT NULL,
  full_name       VARCHAR2(100) NOT NULL,
  role            VARCHAR2(10)  DEFAULT 'OPERATOR' NOT NULL,
  is_active       CHAR(1)       DEFAULT 'Y' NOT NULL,
  failed_attempts NUMBER(2)     DEFAULT 0 NOT NULL,
  last_login_at   DATE,
  created_at      DATE          DEFAULT SYSDATE NOT NULL,
  CONSTRAINT uq_users_login   UNIQUE (login),
  CONSTRAINT chk_users_role   CHECK (role IN ('ADMIN', 'OPERATOR')),
  CONSTRAINT chk_users_active CHECK (is_active IN ('Y', 'N'))
);

-- ---------- Mijozlar ----------
CREATE SEQUENCE seq_clients START WITH 1001 NOCACHE;

CREATE TABLE clients (
  client_id   NUMBER        PRIMARY KEY,
  client_type CHAR(1)       NOT NULL,                  -- J = jismoniy, Y = yuridik
  full_name   VARCHAR2(200) NOT NULL,
  tax_code    VARCHAR2(14)  NOT NULL,                  -- PINFL (14) yoki INN (9)
  phone       VARCHAR2(13)  NOT NULL,                  -- +998XXXXXXXXX
  address     VARCHAR2(300),
  status      CHAR(1)       DEFAULT 'A' NOT NULL,      -- A = faol, B = bloklangan
  created_at  DATE          DEFAULT SYSDATE NOT NULL,
  created_by  VARCHAR2(50)  NOT NULL,
  updated_at  DATE,
  updated_by  VARCHAR2(50),
  CONSTRAINT uq_clients_tax     UNIQUE (tax_code),
  CONSTRAINT chk_clients_type   CHECK (client_type IN ('J', 'Y')),
  CONSTRAINT chk_clients_status CHECK (status IN ('A', 'B')),
  CONSTRAINT chk_clients_phone  CHECK (REGEXP_LIKE(phone, '^\+998[0-9]{9}$')),
  CONSTRAINT chk_clients_tax    CHECK (
       (client_type = 'J' AND REGEXP_LIKE(tax_code, '^[0-9]{14}$'))
    OR (client_type = 'Y' AND REGEXP_LIKE(tax_code, '^[0-9]{9}$')))
);
CREATE INDEX ix_clients_name    ON clients (UPPER(full_name));
CREATE INDEX ix_clients_created ON clients (created_at);

-- ---------- Hisob raqamlar ----------
CREATE TABLE accounts (
  account_no    VARCHAR2(20)  PRIMARY KEY,
  client_id     NUMBER        NOT NULL,
  balance_acc   CHAR(5)       NOT NULL,                -- 20206 / 20208
  currency_code CHAR(3)       NOT NULL,
  balance       NUMBER(20,2)  DEFAULT 0 NOT NULL,
  status        CHAR(1)       DEFAULT 'A' NOT NULL,    -- A = faol, B = bloklangan
  block_reason  VARCHAR2(200),
  opened_at     DATE          DEFAULT SYSDATE NOT NULL,
  opened_by     VARCHAR2(50)  NOT NULL,
  CONSTRAINT fk_accounts_client   FOREIGN KEY (client_id)     REFERENCES clients (client_id),
  CONSTRAINT fk_accounts_currency FOREIGN KEY (currency_code) REFERENCES currencies (currency_code),
  CONSTRAINT chk_accounts_no      CHECK (REGEXP_LIKE(account_no, '^[0-9]{20}$')),
  CONSTRAINT chk_accounts_balance CHECK (balance >= 0),
  CONSTRAINT chk_accounts_status  CHECK (status IN ('A', 'B'))
);
CREATE INDEX ix_accounts_client ON accounts (client_id);

-- ---------- O'tkazmalar (bajarilgan va rad etilgan) ----------
CREATE SEQUENCE seq_transactions NOCACHE;

CREATE TABLE transactions (
  tran_id      NUMBER        PRIMARY KEY,
  doc_no       VARCHAR2(12)  NOT NULL,                 -- TR-000001
  tran_date    DATE          DEFAULT SYSDATE NOT NULL,
  from_acc     VARCHAR2(20)  NOT NULL,
  to_acc       VARCHAR2(20)  NOT NULL,                 -- rad etilganda mavjud bo'lmasligi mumkin, shuning uchun FK yo'q
  amount       NUMBER(20,2)  NOT NULL,
  purpose_code VARCHAR2(5)   NOT NULL,
  description  VARCHAR2(250),
  status       CHAR(1)       NOT NULL,                 -- S = bajarildi, R = rad etildi
  error_code   VARCHAR2(10),
  error_msg    VARCHAR2(400),
  created_by   VARCHAR2(50)  NOT NULL,
  CONSTRAINT uq_tran_doc      UNIQUE (doc_no),
  CONSTRAINT fk_tran_from     FOREIGN KEY (from_acc)     REFERENCES accounts (account_no),
  CONSTRAINT fk_tran_purpose  FOREIGN KEY (purpose_code) REFERENCES payment_purposes (purpose_code),
  CONSTRAINT chk_tran_amount  CHECK (amount > 0),
  CONSTRAINT chk_tran_status  CHECK (status IN ('S', 'R')),
  CONSTRAINT chk_tran_error   CHECK ((status = 'S' AND error_code IS NULL) OR (status = 'R' AND error_code IS NOT NULL))
);
CREATE INDEX ix_tran_from ON transactions (from_acc, tran_date);
CREATE INDEX ix_tran_to   ON transactions (to_acc, tran_date);
CREATE INDEX ix_tran_date ON transactions (tran_date);

-- ---------- Audit jurnali (trigger'lar yozadi) ----------
CREATE TABLE audit_log (
  audit_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name  VARCHAR2(30)  NOT NULL,
  record_id   VARCHAR2(30)  NOT NULL,
  action      VARCHAR2(6)   NOT NULL,
  column_name VARCHAR2(30),
  old_value   VARCHAR2(400),
  new_value   VARCHAR2(400),
  changed_by  VARCHAR2(50)  NOT NULL,
  changed_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
  CONSTRAINT chk_audit_action CHECK (action IN ('INSERT', 'UPDATE', 'DELETE'))
);
CREATE INDEX ix_audit_record ON audit_log (table_name, record_id);

-- ---------- Ma'lumotnoma qiymatlari ----------
INSERT INTO currencies VALUES ('000', 'UZS', 'O''zbek so''mi');
INSERT INTO currencies VALUES ('840', 'USD', 'AQSh dollari');

INSERT INTO payment_purposes VALUES ('00668', 'Shaxsiy o''tkazma');
INSERT INTO payment_purposes VALUES ('00101', 'Ish haqi');
INSERT INTO payment_purposes VALUES ('00302', 'Kommunal to''lov');
INSERT INTO payment_purposes VALUES ('00502', 'Qarzni qaytarish');
COMMIT;
