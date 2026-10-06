package uz.miniabs.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.dao.AccountDao;
import uz.miniabs.dao.TransferDao;
import uz.miniabs.model.PageResult;
import uz.miniabs.model.Transaction;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Map;
import java.util.Set;

@WebServlet("/journal")
public class JournalServlet extends BaseServlet {

    private static final String[][] TABS = {
        {"ALL", "Barchasi"}, {"S", "Bajarilgan"}, {"R", "Rad etilgan"}
    };

    private final TransferDao transferDao = new TransferDao();
    private final AccountDao accountDao = new AccountDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        ListQuery q = new ListQuery(req, "/journal", "q", "acc", "from", "to", "pur", "tab", "sort", "page", "size");
        String tab = q.tab("ALL", Set.of("ALL", "S", "R"));
        String user = login(req);
        String acc = q.get("acc").matches("\\d{20}") ? q.get("acc") : null;

        PageResult<Transaction> result = transferDao.journal(user, q.str("q"), acc, q.date("from"), q.date("to"),
                q.str("pur"), tab, q.str("sort"), q.getPage(), q.getSize());
        Map<String, BigDecimal> counts = transferDao.tabCounts(user, q.str("q"), acc, q.date("from"), q.date("to"), q.str("pur"));

        // Hisob tanlangan bo'lsa, sahifa ko'chirma rejimida ishlaydi
        if (acc != null) {
            String owner = accountDao.ownerName(user, acc);
            if (owner != null) {
                req.setAttribute("statementAcc", acc);
                req.setAttribute("statementOwner", owner);
                req.setAttribute("statement", transferDao.statementSummary(user, acc, q.date("from"), q.date("to")));
            }
        }
        req.setAttribute("q", q);
        req.setAttribute("result", result);
        req.setAttribute("counts", counts);
        req.setAttribute("tabs", tabs(q, tab, counts, TABS));
        req.setAttribute("filterCount", q.countOf("acc", "from", "to", "pur"));
        render(req, resp, "journal");
    }
}
