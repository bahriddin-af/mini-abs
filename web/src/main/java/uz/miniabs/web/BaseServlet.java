package uz.miniabs.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.model.User;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public abstract class BaseServlet extends HttpServlet {

    protected User user(HttpServletRequest req) {
        return (User) req.getSession().getAttribute(AuthFilter.USER);
    }

    protected String login(HttpServletRequest req) {
        User u = user(req);
        return u == null ? null : u.getLogin();
    }

    protected void render(HttpServletRequest req, HttpServletResponse resp, String page)
            throws ServletException, IOException {
        req.setAttribute("page", page);
        req.getRequestDispatcher("/WEB-INF/jsp/" + page + ".jsp").forward(req, resp);
    }

    /** Keyingi sahifada bir marta ko'rsatiladigan xabar (toast) */
    protected void flash(HttpServletRequest req, String message) {
        req.getSession().setAttribute("flash", message);
    }

    /**
     * Formadagi "back" maydoni: ro'yxatning filtrlari bilan birga qaytish manzili.
     * Faqat shu ilova ichidagi manzillarga ruxsat beriladi (open redirect'dan himoya).
     */
    protected void redirectBack(HttpServletRequest req, HttpServletResponse resp, String fallback) throws IOException {
        String back = req.getParameter("back");
        String ctx = req.getContextPath();
        if (back != null && back.startsWith(ctx + "/") && !back.startsWith("//") && !back.contains("\n")) {
            resp.sendRedirect(back);
        } else {
            resp.sendRedirect(ctx + fallback);
        }
    }

    protected String param(HttpServletRequest req, String name) {
        String v = req.getParameter(name);
        return v == null || v.isBlank() ? null : v.trim();
    }

    protected List<Tab> tabs(ListQuery q, String active, Map<String, ? extends Number> counts, String[][] defs) {
        List<Tab> list = new ArrayList<>();
        for (String[] d : defs) {
            list.add(new Tab(d[0], d[1], counts.get(d[0]), q.with("tab", "ALL".equals(d[0]) ? null : d[0]), d[0].equals(active)));
        }
        return list;
    }
}
