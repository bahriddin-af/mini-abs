package uz.miniabs.db;

import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * PL/SQL'dan kelgan xato. ORA-20000..20999 biznes-xatolar foydalanuvchiga
 * aynan bazadagi matn bilan ko'rsatiladi, qolganlari umumiy xabar bilan.
 */
public class DbException extends RuntimeException {

    private static final Logger LOG = Logger.getLogger(DbException.class.getName());

    private final int code;

    public DbException(int code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public static DbException from(SQLException e) {
        int code = e.getErrorCode();
        if (code >= 20000 && code <= 20999) {
            return new DbException(code, businessMessage(e.getMessage(), code), e);
        }
        LOG.log(Level.SEVERE, "Ma'lumotlar bazasi xatosi", e);
        return new DbException(code, "Ma'lumotlar bazasi bilan bog'lanishda xato. Keyinroq urinib ko'ring.", e);
    }

    /** "ORA-20001: Mablag' yetarli emas\nORA-06512: ..." -> "Mablag' yetarli emas" */
    private static String businessMessage(String raw, int code) {
        String first = raw == null ? "" : raw.split("\n", 2)[0];
        String prefix = "ORA-" + code + ": ";
        return first.startsWith(prefix) ? first.substring(prefix.length()) : first;
    }

    public int getCode() {
        return code;
    }

    /** UI'da ko'rsatiladigan kod, masalan "ORA-20001" */
    public String getOraCode() {
        return "ORA-" + code;
    }

    public boolean isBusiness() {
        return code >= 20000 && code <= 20999;
    }
}
