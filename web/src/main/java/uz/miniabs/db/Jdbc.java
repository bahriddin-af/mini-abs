package uz.miniabs.db;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** CallableStatement bilan ishlashdagi takrorlanuvchi kodlar (NULL qiymatlar va sanalar) */
public final class Jdbc {

    private Jdbc() {
    }

    public static void str(CallableStatement cs, int i, String v) throws SQLException {
        if (v == null || v.isBlank()) {
            cs.setNull(i, Types.VARCHAR);
        } else {
            cs.setString(i, v.trim());
        }
    }

    public static void num(CallableStatement cs, int i, Number v) throws SQLException {
        if (v == null) {
            cs.setNull(i, Types.NUMERIC);
        } else if (v instanceof BigDecimal b) {
            cs.setBigDecimal(i, b);
        } else {
            cs.setLong(i, v.longValue());
        }
    }

    public static void date(CallableStatement cs, int i, LocalDate v) throws SQLException {
        if (v == null) {
            cs.setNull(i, Types.DATE);
        } else {
            cs.setDate(i, java.sql.Date.valueOf(v));
        }
    }

    public static LocalDateTime dateTime(ResultSet rs, String col) throws SQLException {
        Timestamp t = rs.getTimestamp(col);
        return t == null ? null : t.toLocalDateTime();
    }

    public static ResultSet cursor(CallableStatement cs, int i) throws SQLException {
        return cs.getObject(i, ResultSet.class);
    }
}
