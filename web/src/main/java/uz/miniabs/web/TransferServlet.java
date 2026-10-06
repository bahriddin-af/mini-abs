package uz.miniabs.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.dao.AccountDao;
import uz.miniabs.dao.TransferDao;
import uz.miniabs.db.DbException;
import uz.miniabs.model.Account;
import uz.miniabs.model.Transaction;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/transfer")
public class TransferServlet extends BaseServlet {

    private final AccountDao accountDao = new AccountDao();
    private final TransferDao transferDao = new TransferDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String user = login(req);
        List<Account> accounts = accountDao.byCurrency(user, "000");

        String from = param(req, "from");
        Account selected = accounts.stream().filter(a -> a.getAccountNo().equals(from)).findFirst()
                .orElse(accounts.stream().filter(a -> a.isActive() && a.getBalance().signum() > 0).findFirst()
                        .orElse(accounts.isEmpty() ? null : accounts.get(0)));

        String doc = param(req, "doc");
        if (doc != null) {
            Transaction receipt = transferDao.findByDoc(user, doc);
            if (receipt != null && receipt.isSuccess()) {
                req.setAttribute("receipt", receipt);
            }
        }

        req.setAttribute("accounts", accounts);
        req.setAttribute("selected", selected);
        req.setAttribute("recent", selected == null ? List.of() : transferDao.recent(user, selected.getAccountNo()));
        render(req, resp, "transfer");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String from = param(req, "from");
        try {
            BigDecimal amount = parseAmount(req.getParameter("amount"));
            TransferDao.Result r = transferDao.transfer(login(req), from, param(req, "to"), amount,
                    param(req, "purpose"), param(req, "description"));
            // Post/Redirect/Get: sahifani yangilaganda o'tkazma qayta yuborilmaydi
            resp.sendRedirect(req.getContextPath() + "/transfer?from=" + enc(from) + "&doc=" + enc(r.getDocNo()));
        } catch (DbException | NumberFormatException e) {
            Map<String, String> form = new LinkedHashMap<>();
            for (String k : new String[]{"to", "amount", "purpose", "description"}) {
                form.put(k, req.getParameter(k) == null ? "" : req.getParameter(k));
            }
            req.setAttribute("form", form);
            req.setAttribute("error", e instanceof DbException d
                    ? d.getOraCode() + ": " + d.getMessage()
                    : "Summa noto'g'ri kiritilgan");
            doGet(req, resp);
        }
    }

    private static BigDecimal parseAmount(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new NumberFormatException();
        }
        return new BigDecimal(raw.replaceAll("[\\s\\u00a0]", "").replace(',', '.'));
    }

    private static String enc(String v) {
        return URLEncoder.encode(v == null ? "" : v, StandardCharsets.UTF_8);
    }
}
