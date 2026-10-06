package uz.miniabs.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import uz.miniabs.dao.AuthDao;
import uz.miniabs.db.DbException;
import uz.miniabs.model.User;

import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends BaseServlet {

    private final AuthDao authDao = new AuthDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (user(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/clients");
            return;
        }
        render(req, resp, "login");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String login = param(req, "login");
        String password = req.getParameter("password");
        if (login == null || password == null || password.isEmpty()) {
            req.setAttribute("error", "Login va parolni kiriting");
            req.setAttribute("login", login);
            render(req, resp, "login");
            return;
        }
        try {
            User user = authDao.login(login, password);
            req.changeSessionId();   // session fixation hujumidan himoya
            req.getSession().setAttribute(AuthFilter.USER, user);
            flash(req, "Xush kelibsiz, " + user.getFullName());
            resp.sendRedirect(req.getContextPath() + "/clients");
        } catch (DbException e) {
            req.setAttribute("error", e.getMessage());
            req.setAttribute("login", login);
            render(req, resp, "login");
        }
    }
}
