package uz.miniabs.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.dao.AccountDao;

import java.io.IOException;

/** O'tkazma formasida hisob raqam kiritilganda egasining nomini ko'rsatish: GET /api/account-owner?no=... */
@WebServlet("/api/account-owner")
public class AccountOwnerApi extends BaseServlet {

    private final AccountDao accountDao = new AccountDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String no = param(req, "no");
        String name = no != null && no.matches("\\d{20}") ? accountDao.ownerName(login(req), no) : null;
        resp.setContentType("application/json");
        resp.getWriter().write(name == null ? "{\"name\":null}" : "{\"name\":\"" + json(name) + "\"}");
    }

    private static String json(String s) {
        StringBuilder sb = new StringBuilder();
        for (char ch : s.toCharArray()) {
            switch (ch) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '<' -> sb.append("\\u003c");
                default -> {
                    if (ch < 0x20) {
                        sb.append(String.format("\\u%04x", (int) ch));
                    } else {
                        sb.append(ch);
                    }
                }
            }
        }
        return sb.toString();
    }
}
