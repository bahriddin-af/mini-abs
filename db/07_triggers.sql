-- =====================================================================
-- Audit trigger'lari: mijoz va hisoblardagi har bir o'zgarish audit_log'ga yoziladi.
-- Hisob qoldig'i (balance) bu yerda yozilmaydi: uning tarixi transactions jadvalida.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_clients_audit
  AFTER INSERT OR UPDATE OR DELETE ON clients
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    pkg_util.audit('CLIENTS', :NEW.client_id, 'INSERT', NULL, NULL, :NEW.full_name);
  ELSIF DELETING THEN
    pkg_util.audit('CLIENTS', :OLD.client_id, 'DELETE', NULL, :OLD.full_name, NULL);
  ELSE
    IF NVL(:OLD.full_name, '~') <> NVL(:NEW.full_name, '~') THEN
      pkg_util.audit('CLIENTS', :NEW.client_id, 'UPDATE', 'FULL_NAME', :OLD.full_name, :NEW.full_name);
    END IF;
    IF NVL(:OLD.tax_code, '~') <> NVL(:NEW.tax_code, '~') THEN
      pkg_util.audit('CLIENTS', :NEW.client_id, 'UPDATE', 'TAX_CODE', :OLD.tax_code, :NEW.tax_code);
    END IF;
    IF NVL(:OLD.phone, '~') <> NVL(:NEW.phone, '~') THEN
      pkg_util.audit('CLIENTS', :NEW.client_id, 'UPDATE', 'PHONE', :OLD.phone, :NEW.phone);
    END IF;
    IF NVL(:OLD.address, '~') <> NVL(:NEW.address, '~') THEN
      pkg_util.audit('CLIENTS', :NEW.client_id, 'UPDATE', 'ADDRESS', :OLD.address, :NEW.address);
    END IF;
    IF :OLD.status <> :NEW.status THEN
      pkg_util.audit('CLIENTS', :NEW.client_id, 'UPDATE', 'STATUS', :OLD.status, :NEW.status);
    END IF;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_accounts_audit
  AFTER INSERT OR UPDATE OF status, block_reason OR DELETE ON accounts
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    pkg_util.audit('ACCOUNTS', :NEW.account_no, 'INSERT', NULL, NULL,
                   'CLIENT_ID=' || :NEW.client_id || ', CURRENCY=' || :NEW.currency_code);
  ELSIF DELETING THEN
    pkg_util.audit('ACCOUNTS', :OLD.account_no, 'DELETE', NULL, 'BALANCE=' || :OLD.balance, NULL);
  ELSIF :OLD.status <> :NEW.status THEN
    pkg_util.audit('ACCOUNTS', :NEW.account_no, 'UPDATE', 'STATUS',
                   :OLD.status, :NEW.status || NVL2(:NEW.block_reason, ' (' || :NEW.block_reason || ')', NULL));
  END IF;
END;
/

-- Bajarilgan o'tkazmani o'zgartirish yoki o'chirish taqiqlanadi (moliyaviy hujjat)
CREATE OR REPLACE TRIGGER trg_transactions_protect
  BEFORE UPDATE OR DELETE ON transactions
  FOR EACH ROW
BEGIN
  IF :OLD.status = 'S' THEN
    RAISE_APPLICATION_ERROR(-20030, 'Bajarilgan to''lov hujjatini o''zgartirib bo''lmaydi: ' || :OLD.doc_no);
  END IF;
END;
/
