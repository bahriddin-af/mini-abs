package uz.miniabs.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.dao.AccountDao;
import uz.miniabs.dao.ClientDao;
import uz.miniabs.db.DbException;
import uz.miniabs.model.Account;
import uz.miniabs.model.Client;
import uz.miniabs.model.PageResult;

import java.io.IOException;
import java.util.Map;
import java.util.Set;

@WebServlet("/accounts")
public class AccountsServlet extends BaseServlet {

    private static final String[][] TABS = {
        {"ALL", "Barchasi"}, {"UZS", "UZS"}, {"USD", "USD"}, {"B", "Bloklangan"}
    };

    private final AccountDao accountDao = new AccountDao();
    private final ClientDao clientDao = new ClientDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        ListQuery q = new ListQuery(req, "/accounts", "q", "client", "bs", "min", "max", "from", "tab", "sort", "page", "size");
        String tab = q.tab("ALL", Set.of("ALL", "UZS", "USD", "B"));
        String user = login(req);
        Long clientId = q.longVal("client");

        PageResult<Account> result = accountDao.list(user, q.str("q"), clientId, q.str("bs"),
                q.decimal("min"), q.decimal("max"), q.date("from"), tab, q.str("sort"), q.getPage(), q.getSize());
        Map<String, Integer> counts = accountDao.tabCounts(user, q.str("q"), clientId, q.str("bs"),
                q.decimal("min"), q.decimal("max"), q.date("from"));

        if (clientId != null) {
            Client c = clientDao.find(user, clientId);
            req.setAttribute("filterClient", c);
        }
        req.setAttribute("q", q);
        req.setAttribute("result", result);
        req.setAttribute("tabs", tabs(q, tab, counts, TABS));
        req.setAttribute("summary", accountDao.summary(user));
        req.setAttribute("activeClients", clientDao.activeClients(user));
        req.setAttribute("filterCount", q.countOf("bs", "min", "max", "from"));
        render(req, resp, "accounts");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String user = login(req);
        try {
            if ("open".equals(param(req, "action"))) {
                String no = accountDao.open(user, Long.parseLong(req.getParameter("clientId")), param(req, "currency"));
                flash(req, "Hisob ochildi: " + no);
            } else {
                String status = param(req, "status");
                accountDao.setStatus(user, param(req, "accountNo"), status, param(req, "reason"));
                flash(req, "B".equals(status) ? "Hisob bloklandi" : "Hisob blokdan chiqarildi");
            }
        } catch (DbException e) {
            req.getSession().setAttribute("flashError", e.getOraCode() + ": " + e.getMessage());
        }
        redirectBack(req, resp, "/accounts");
    }
}
