package uz.miniabs.web;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import uz.miniabs.dao.TransferDao;
import uz.miniabs.db.Db;

/** Ilova ishga tushganda ulanishlar poolini ochadi, to'xtaganda yopadi */
@WebListener
public class AppListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent e) {
        Db.init();
        e.getServletContext().setAttribute("purposes", new TransferDao().purposes());
    }

    @Override
    public void contextDestroyed(ServletContextEvent e) {
        Db.close();
    }
}
