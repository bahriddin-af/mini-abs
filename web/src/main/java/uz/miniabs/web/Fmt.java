package uz.miniabs.web;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/** JSP'dagi EL funksiyalari (WEB-INF/miniabs.tld): ${f:money(a.balance)} */
public final class Fmt {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd.MM.yyyy");
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm");
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm");

    private Fmt() {
    }

    private static DecimalFormat format(String pattern) {
        DecimalFormatSymbols s = new DecimalFormatSymbols(Locale.ROOT);
        s.setGroupingSeparator(' ');
        s.setDecimalSeparator(',');
        return new DecimalFormat(pattern, s);
    }

    /** 1234567.5 -> "1 234 567,50" */
    public static String money(Object v) {
        return v == null ? "" : format("#,##0.00").format(toDecimal(v));
    }

    /** 1234567.5 -> "1 234 568" */
    public static String money0(Object v) {
        return v == null ? "" : format("#,##0").format(toDecimal(v));
    }

    /** 1234567 -> "1,2" (mln) */
    public static String millions(Object v) {
        return v == null ? "" : format("#,##0.0").format(toDecimal(v).movePointLeft(6));
    }

    private static BigDecimal toDecimal(Object v) {
        return v instanceof BigDecimal b ? b : new BigDecimal(v.toString());
    }

    /** +998901234567 -> +998 90 123 45 67 */
    public static String phone(String p) {
        if (p == null || !p.matches("\\+998\\d{9}")) {
            return p;
        }
        return p.substring(0, 4) + " " + p.substring(4, 6) + " " + p.substring(6, 9) + " "
             + p.substring(9, 11) + " " + p.substring(11);
    }

    /** "Abdullayev Jasur Karimovich" -> "AJ", "\"Silk Road Soft\" MChJ" -> "SR" */
    public static String initials(String name) {
        if (name == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (String w : name.replaceAll("[\"']", "").trim().split("\\s+")) {
            if (w.isEmpty() || w.matches("MChJ|AJ|XK")) {
                continue;
            }
            sb.append(Character.toUpperCase(w.charAt(0)));
            if (sb.length() == 2) {
                break;
            }
        }
        return sb.toString();
    }

    public static String date(LocalDateTime d) {
        return d == null ? "" : d.format(DATE);
    }

    public static String dateTime(LocalDateTime d) {
        return d == null ? "" : d.format(DATE_TIME);
    }

    public static String time(LocalDateTime d) {
        return d == null ? "" : d.format(TIME);
    }
}
