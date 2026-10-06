package uz.miniabs.dao;

import uz.miniabs.db.Db;
import uz.miniabs.db.Jdbc;
import uz.miniabs.model.Account;
import uz.miniabs.model.PageResult;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AccountDao {

    public PageResult<Account> list(String user, String search, Long clientId, String balanceAcc,
                                    BigDecimal min, BigDecimal max, LocalDate openedFrom,
                                    String tab, String sort, int page, int size) {
        PageResult<Account> result = Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_account.get_accounts(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                cs.registerOutParameter(1, Types.REF_CURSOR);
                Jdbc.str(cs, 2, search);
                Jdbc.num(cs, 3, clientId);
                Jdbc.str(cs, 4, balanceAcc);
                Jdbc.num(cs, 5, min);
                Jdbc.num(cs, 6, max);
                Jdbc.date(cs, 7, openedFrom);
                Jdbc.str(cs, 8, tab);
                Jdbc.str(cs, 9, sort);
                cs.setInt(10, page);
                cs.setInt(11, size);
                cs.execute();

                List<Account> items = new ArrayList<>();
                int total = 0;
                try (ResultSet rs = Jdbc.cursor(cs, 1)) {
                    while (rs.next()) {
                        items.add(map(rs));
                        total = rs.getInt("total_rows");
                    }
                }
                return new PageResult<>(items, total, page, size);
            }
        });
        if (result.getItems().isEmpty() && page > 1) {
            return list(user, search, clientId, balanceAcc, min, max, openedFrom, tab, sort, 1, size);
        }
        return result;
    }

    /** Tablardagi sonlar: ALL, UZS, USD, B */
    public Map<String, Integer> tabCounts(String user, String search, Long clientId, String balanceAcc,
                                          BigDecimal min, BigDecimal max, LocalDate openedFrom) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_account.get_tab_counts(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                Jdbc.str(cs, 1, search);
                Jdbc.num(cs, 2, clientId);
                Jdbc.str(cs, 3, balanceAcc);
                Jdbc.num(cs, 4, min);
                Jdbc.num(cs, 5, max);
                Jdbc.date(cs, 6, openedFrom);
                for (int i = 7; i <= 10; i++) {
                    cs.registerOutParameter(i, Types.NUMERIC);
                }
                cs.execute();
                Map<String, Integer> m = new LinkedHashMap<>();
                m.put("ALL", cs.getInt(7));
                m.put("UZS", cs.getInt(8));
                m.put("USD", cs.getInt(9));
                m.put("B", cs.getInt(10));
                return m;
            }
        });
    }

    /** Kartochkalar: total, uzs, usd, blocked */
    public Map<String, BigDecimal> summary(String user) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_account.get_summary(?, ?, ?, ?)}")) {
                for (int i = 1; i <= 4; i++) {
                    cs.registerOutParameter(i, Types.NUMERIC);
                }
                cs.execute();
                Map<String, BigDecimal> m = new LinkedHashMap<>();
                m.put("total", cs.getBigDecimal(1));
                m.put("uzs", cs.getBigDecimal(2));
                m.put("usd", cs.getBigDecimal(3));
                m.put("blocked", cs.getBigDecimal(4));
                return m;
            }
        });
    }

    public String open(String user, long clientId, String currencyCode) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_account.open_account(?, ?, ?)}")) {
                cs.setLong(1, clientId);
                cs.setString(2, currencyCode);
                cs.registerOutParameter(3, Types.VARCHAR);
                cs.execute();
                return cs.getString(3);
            }
        });
    }

    public void setStatus(String user, String accountNo, String status, String reason) {
        Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_account.set_status(?, ?, ?)}")) {
                cs.setString(1, accountNo);
                cs.setString(2, status);
                Jdbc.str(cs, 3, reason);
                cs.execute();
                return null;
            }
        });
    }

    public String ownerName(String user, String accountNo) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_account.get_owner_name(?)}")) {
                cs.registerOutParameter(1, Types.VARCHAR);
                cs.setString(2, accountNo);
                cs.execute();
                return cs.getString(1);
            }
        });
    }

    /** O'tkazma formasidagi ro'yxat */
    public List<Account> byCurrency(String user, String currencyCode) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_account.get_accounts_by_currency(?)}")) {
                cs.registerOutParameter(1, Types.REF_CURSOR);
                cs.setString(2, currencyCode);
                cs.execute();
                List<Account> list = new ArrayList<>();
                try (ResultSet rs = Jdbc.cursor(cs, 1)) {
                    while (rs.next()) {
                        Account a = new Account();
                        a.setAccountNo(rs.getString("account_no"));
                        a.setClientName(rs.getString("client_name"));
                        a.setBalance(rs.getBigDecimal("balance"));
                        a.setStatus(rs.getString("status"));
                        list.add(a);
                    }
                }
                return list;
            }
        });
    }

    private static Account map(ResultSet rs) throws SQLException {
        Account a = new Account();
        a.setAccountNo(rs.getString("account_no"));
        a.setClientId(rs.getLong("client_id"));
        a.setClientName(rs.getString("client_name"));
        a.setClientType(rs.getString("client_type"));
        a.setCurrency(rs.getString("currency"));
        a.setBalance(rs.getBigDecimal("balance"));
        a.setStatus(rs.getString("status"));
        a.setBlockReason(rs.getString("block_reason"));
        a.setOpenedAt(Jdbc.dateTime(rs, "opened_at"));
        return a;
    }
}
