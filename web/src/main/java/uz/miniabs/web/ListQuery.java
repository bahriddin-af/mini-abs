package uz.miniabs.web;

import jakarta.servlet.http.HttpServletRequest;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/**
 * Ro'yxat sahifasining GET parametrlari (qidiruv, filtrlar, tab, saralash, sahifa).
 * JSP'da havolalar yasash uchun: ${q.with('tab', 'J')}, ${q.sortUrl('name')}.
 */
public class ListQuery {

    private static final Set<Integer> PAGE_SIZES = Set.of(10, 20, 50);

    private final String path;
    private final Map<String, String> params = new LinkedHashMap<>();

    public ListQuery(HttpServletRequest req, String path, String... keys) {
        this.path = req.getContextPath() + path;
        for (String k : keys) {
            String v = req.getParameter(k);
            if (v != null && !v.isBlank()) {
                params.put(k, v.trim());
            }
        }
    }

    public String get(String key) {
        return params.getOrDefault(key, "");
    }

    public String str(String key) {
        return params.get(key);
    }

    public boolean has(String key) {
        return params.containsKey(key);
    }

    public Long longVal(String key) {
        try {
            return params.containsKey(key) ? Long.valueOf(params.get(key)) : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public BigDecimal decimal(String key) {
        try {
            return params.containsKey(key) ? new BigDecimal(params.get(key).replace(" ", "").replace(',', '.')) : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public LocalDate date(String key) {
        try {
            return params.containsKey(key) ? LocalDate.parse(params.get(key)) : null;
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    public int getPage() {
        Long p = longVal("page");
        return p == null || p < 1 ? 1 : p.intValue();
    }

    public int getSize() {
        Long s = longVal("size");
        return s != null && PAGE_SIZES.contains(s.intValue()) ? s.intValue() : 10;
    }

    public String tab(String def, Set<String> allowed) {
        String t = params.get("tab");
        return t != null && allowed.contains(t) ? t : def;
    }

    /** Joriy URL, bitta parametr o'zgartirilgan holda. Sahifadan boshqa narsa o'zgarsa, sahifa 1 ga qaytadi. */
    public String with(String key, Object value) {
        Map<String, String> copy = new LinkedHashMap<>(params);
        if (!"page".equals(key)) {
            copy.remove("page");
        }
        String v = value == null ? "" : value.toString();
        if (v.isEmpty()) {
            copy.remove(key);
        } else {
            copy.put(key, v);
        }
        return build(copy);
    }

    public String without(String key) {
        return with(key, null);
    }

    public String getUrl() {
        return build(params);
    }

    /** Ustun sarlavhasini bosganda: col_asc <-> col_desc */
    public String sortUrl(String col) {
        String cur = get("sort");
        return with("sort", (col + "_asc").equals(cur) ? col + "_desc" : col + "_asc");
    }

    public String sortIcon(String col) {
        String cur = get("sort");
        if ((col + "_asc").equals(cur)) {
            return "▲";
        }
        if ((col + "_desc").equals(cur)) {
            return "▼";
        }
        return "↕";
    }

    /** Ko'rsatilgan filtr maydonlaridan nechtasi to'ldirilgan */
    public int countOf(String... keys) {
        int n = 0;
        for (String k : keys) {
            if (params.containsKey(k)) {
                n++;
            }
        }
        return n;
    }

    public boolean isEmpty() {
        return params.isEmpty();
    }

    private String build(Map<String, String> m) {
        StringBuilder sb = new StringBuilder(path);
        char sep = '?';
        for (Map.Entry<String, String> e : m.entrySet()) {
            sb.append(sep).append(e.getKey()).append('=')
              .append(URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8));
            sep = '&';
        }
        return sb.toString();
    }
}
