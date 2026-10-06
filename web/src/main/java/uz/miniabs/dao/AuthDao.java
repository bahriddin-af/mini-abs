package uz.miniabs.dao;

import uz.miniabs.db.Db;
import uz.miniabs.model.User;

import java.sql.CallableStatement;
import java.sql.Types;

public class AuthDao {

    /** pkg_auth.login: xato bo'lsa DbException (ORA-20101 / ORA-20102) */
    public User login(String login, String password) {
        return Db.tx(login, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_auth.login(?, ?, ?, ?, ?)}")) {
                cs.setString(1, login);
                cs.setString(2, password);
                cs.registerOutParameter(3, Types.NUMERIC);
                cs.registerOutParameter(4, Types.VARCHAR);
                cs.registerOutParameter(5, Types.VARCHAR);
                cs.execute();
                return new User(cs.getLong(3), login.trim().toLowerCase(), cs.getString(4), cs.getString(5));
            }
        });
    }
}
