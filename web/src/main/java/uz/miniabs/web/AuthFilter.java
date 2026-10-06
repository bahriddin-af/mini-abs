package uz.miniabs.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * 1) Tizimga kirmagan foydalanuvchini /login'ga yo'naltiradi.
 * 2) Har bir POST so'rovda CSRF tokenni tekshiradi.
 * 3) Xavfsizlik sarlavhalarini qo'shadi.
 */
@WebFilter("/*")
public class AuthFilter extends HttpFilter {

    public static final String USER = "user";
    public static final String CSRF = "csrf";

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse resp, FilterChain chain)
            throws IOException, ServletException {
        String path = req.getRequestURI().substring(req.getContextPath().length());

        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.setHeader("X-Frame-Options", "DENY");
        resp.setHeader("Referrer-Policy", "same-origin");

        if (path.startsWith("/assets/")) {
            chain.doFilter(req, resp);
            return;
        }

        HttpSession session = req.getSession();
        if (session.getAttribute(CSRF) == null) {
            byte[] b = new byte[24];
            RANDOM.nextBytes(b);
            session.setAttribute(CSRF, Base64.getUrlEncoder().withoutPadding().encodeToString(b));
        }

        if ("POST".equals(req.getMethod())) {
            String sent = req.getParameter("_csrf");
            String expected = (String) session.getAttribute(CSRF);
            if (sent == null || !MessageDigest.isEqual(sent.getBytes(), expected.getBytes())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF token noto'g'ri. Sahifani yangilang.");
                return;
            }
        }

        boolean loggedIn = session.getAttribute(USER) != null;
        if (!loggedIn && !path.equals("/login")) {
            if (path.startsWith("/api/")) {
                resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            } else {
                resp.sendRedirect(req.getContextPath() + "/login");
            }
            return;
        }

        resp.setHeader("Cache-Control", "no-store");
        chain.doFilter(req, resp);
    }
}
