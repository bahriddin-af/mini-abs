package uz.miniabs.db;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Ulanishlar pooli va tranzaksiya yordamchisi.
 * Sozlamalar tartibi: muhit o'zgaruvchisi -> JVM -D parametri -> miniabs.properties.
 */
public final class Db {

    private static HikariDataSource dataSource;

    private Db() {
    }

    @FunctionalInterface
    public interface SqlWork<T> {
        T run(Connection c) throws SQLException;
    }

    public static synchronized void init() {
        Properties defaults = new Properties();
        try (InputStream in = Db.class.getResourceAsStream("/miniabs.properties")) {
            if (in != null) {
                defaults.load(in);
            }
        } catch (IOException e) {
            throw new IllegalStateException("miniabs.properties o'qilmadi", e);
        }

        HikariConfig cfg = new HikariConfig();
        cfg.setPoolName("miniabs");
        // Tomcat'da DriverManager ilova klasslarini avtomatik ko'rmaydi, shuning uchun drayverni aniq ko'rsatamiz
        cfg.setDriverClassName("oracle.jdbc.OracleDriver");
        cfg.setJdbcUrl(setting("MINIABS_DB_URL", "db.url", defaults));
        cfg.setUsername(setting("MINIABS_DB_USER", "db.user", defaults));
        cfg.setPassword(setting("MINIABS_DB_PASSWORD", "db.password", defaults));
        cfg.setMaximumPoolSize(Integer.parseInt(setting("MINIABS_DB_POOL_SIZE", "db.pool.size", defaults)));
        cfg.setAutoCommit(false);   // tranzaksiyani o'zimiz boshqaramiz
        dataSource = new HikariDataSource(cfg);
    }

    public static synchronized void close() {
        if (dataSource != null) {
            dataSource.close();
        }
    }

    private static String setting(String env, String key, Properties defaults) {
        String v = System.getenv(env);
        if (v == null || v.isBlank()) {
            v = System.getProperty(key);
        }
        if (v == null || v.isBlank()) {
            v = defaults.getProperty(key);
        }
        if (v == null) {
            throw new IllegalStateException("Sozlama topilmadi: " + env + " / " + key);
        }
        return v;
    }

    /**
     * Ishni bitta tranzaksiyada bajaradi: muvaffaqiyatli bo'lsa COMMIT, xato bo'lsa ROLLBACK.
     * appUser bazada CLIENT_IDENTIFIER sifatida o'rnatiladi va audit trigger'lari uni yozadi.
     */
    public static <T> T tx(String appUser, SqlWork<T> work) {
        try (Connection c = dataSource.getConnection()) {
            c.setClientInfo("OCSID.CLIENTID", appUser == null ? "anonymous" : appUser);
            try {
                T result = work.run(c);
                c.commit();
                return result;
            } catch (SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw DbException.from(e);
        }
    }
}
