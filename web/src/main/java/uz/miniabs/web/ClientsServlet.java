package uz.miniabs.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.dao.ClientDao;
import uz.miniabs.db.DbException;
import uz.miniabs.model.Client;
import uz.miniabs.model.PageResult;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@WebServlet("/clients")
public class ClientsServlet extends BaseServlet {

    private static final String[][] TABS = {
        {"ALL", "Barchasi"}, {"J", "Jismoniy"}, {"Y", "Yuridik"}, {"B", "Bloklangan"}
    };

    private final ClientDao clientDao = new ClientDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        ListQuery q = new ListQuery(req, "/clients", "q", "type", "st", "from", "to", "tab", "sort", "page", "size");
        String tab = q.tab("ALL", Set.of("ALL", "J", "Y", "B"));
        String user = login(req);

        PageResult<Client> result = clientDao.list(user, q.str("q"), q.str("type"), q.str("st"),
                q.date("from"), q.date("to"), tab, q.str("sort"), q.getPage(), q.getSize());
        Map<String, Integer> counts = clientDao.tabCounts(user, q.str("q"), q.str("type"), q.str("st"),
                q.date("from"), q.date("to"));

        req.setAttribute("q", q);
        req.setAttribute("result", result);
        req.setAttribute("tabs", tabs(q, tab, counts, TABS));
        req.setAttribute("filterCount", q.countOf("type", "st", "from", "to"));
        render(req, resp, "clients");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String user = login(req);
        String action = param(req, "action");
        try {
            if ("status".equals(action)) {
                long id = Long.parseLong(req.getParameter("id"));
                String status = param(req, "status");
                clientDao.setStatus(user, id, status);
                flash(req, "A".equals(status) ? "Mijoz faollashtirildi" : "Mijoz bloklandi");
                redirectBack(req, resp, "/clients");
                return;
            }

            String id = param(req, "id");
            if (id == null) {
                long newId = clientDao.create(user, param(req, "type"), param(req, "fullName"),
                        param(req, "taxCode"), param(req, "phone"), param(req, "address"));
                flash(req, "Yangi mijoz qo'shildi: ID " + newId);
            } else {
                clientDao.update(user, Long.parseLong(id), param(req, "fullName"),
                        param(req, "taxCode"), param(req, "phone"), param(req, "address"));
                flash(req, "Mijoz ma'lumotlari saqlandi");
            }
            redirectBack(req, resp, "/clients");
        } catch (DbException e) {
            // Forma ochiq qoladi, kiritilgan qiymatlar saqlanadi va xato ko'rsatiladi
            Map<String, String> form = new LinkedHashMap<>();
            for (String k : new String[]{"id", "type", "fullName", "taxCode", "phone", "address", "back"}) {
                form.put(k, req.getParameter(k) == null ? "" : req.getParameter(k));
            }
            req.setAttribute("form", form);
            req.setAttribute("formError", e);
            doGet(req, resp);
        }
    }
}
