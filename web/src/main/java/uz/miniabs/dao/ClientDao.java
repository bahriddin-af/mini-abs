package uz.miniabs.dao;

import uz.miniabs.db.Db;
import uz.miniabs.db.Jdbc;
import uz.miniabs.model.Client;
import uz.miniabs.model.PageResult;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ClientDao {

    public PageResult<Client> list(String user, String search, String type, String status,
                                   LocalDate from, LocalDate to, String tab, String sort,
                                   int page, int size) {
        PageResult<Client> result = Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_client.get_clients(?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                cs.registerOutParameter(1, Types.REF_CURSOR);
                Jdbc.str(cs, 2, search);
                Jdbc.str(cs, 3, type);
                Jdbc.str(cs, 4, status);
                Jdbc.date(cs, 5, from);
                Jdbc.date(cs, 6, to);
                Jdbc.str(cs, 7, tab);
                Jdbc.str(cs, 8, sort);
                cs.setInt(9, page);
                cs.setInt(10, size);
                cs.execute();

                List<Client> items = new ArrayList<>();
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
        // Filtr o'zgarib, sahifa raqami natijadan oshib ketsa, birinchi sahifani ko'rsatamiz
        if (result.getItems().isEmpty() && page > 1) {
            return list(user, search, type, status, from, to, tab, sort, 1, size);
        }
        return result;
    }

    /** Tablardagi sonlar: ALL, J, Y, B */
    public Map<String, Integer> tabCounts(String user, String search, String type, String status,
                                          LocalDate from, LocalDate to) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_client.get_tab_counts(?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                Jdbc.str(cs, 1, search);
                Jdbc.str(cs, 2, type);
                Jdbc.str(cs, 3, status);
                Jdbc.date(cs, 4, from);
                Jdbc.date(cs, 5, to);
                for (int i = 6; i <= 9; i++) {
                    cs.registerOutParameter(i, Types.NUMERIC);
                }
                cs.execute();
                Map<String, Integer> m = new LinkedHashMap<>();
                m.put("ALL", cs.getInt(6));
                m.put("J", cs.getInt(7));
                m.put("Y", cs.getInt(8));
                m.put("B", cs.getInt(9));
                return m;
            }
        });
    }

    public long create(String user, String type, String fullName, String taxCode, String phone, String address) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_client.create_client(?, ?, ?, ?, ?, ?)}")) {
                Jdbc.str(cs, 1, type);
                Jdbc.str(cs, 2, fullName);
                Jdbc.str(cs, 3, taxCode);
                Jdbc.str(cs, 4, phone);
                Jdbc.str(cs, 5, address);
                cs.registerOutParameter(6, Types.NUMERIC);
                cs.execute();
                return cs.getLong(6);
            }
        });
    }

    public void update(String user, long id, String fullName, String taxCode, String phone, String address) {
        Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_client.update_client(?, ?, ?, ?, ?)}")) {
                cs.setLong(1, id);
                Jdbc.str(cs, 2, fullName);
                Jdbc.str(cs, 3, taxCode);
                Jdbc.str(cs, 4, phone);
                Jdbc.str(cs, 5, address);
                cs.execute();
                return null;
            }
        });
    }

    public void setStatus(String user, long id, String status) {
        Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_client.set_status(?, ?)}")) {
                cs.setLong(1, id);
                cs.setString(2, status);
                cs.execute();
                return null;
            }
        });
    }

    /** Hisob ochish oynasi uchun faol mijozlar (nom bo'yicha) */
    public List<Client> activeClients(String user) {
        return list(user, null, null, "A", null, null, "ALL", "name_asc", 1, 100).getItems();
    }

    public Client find(String user, long id) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_client.get_client(?)}")) {
                cs.registerOutParameter(1, Types.REF_CURSOR);
                cs.setLong(2, id);
                cs.execute();
                try (ResultSet rs = Jdbc.cursor(cs, 1)) {
                    return rs.next() ? mapBasic(rs) : null;
                }
            }
        });
    }

    private static Client mapBasic(ResultSet rs) throws SQLException {
        Client cl = new Client();
        cl.setId(rs.getLong("client_id"));
        cl.setType(rs.getString("client_type"));
        cl.setFullName(rs.getString("full_name"));
        cl.setTaxCode(rs.getString("tax_code"));
        cl.setPhone(rs.getString("phone"));
        cl.setAddress(rs.getString("address"));
        cl.setStatus(rs.getString("status"));
        cl.setCreatedAt(Jdbc.dateTime(rs, "created_at"));
        return cl;
    }

    private static Client map(ResultSet rs) throws SQLException {
        Client cl = mapBasic(rs);
        cl.setAccountCount(rs.getInt("account_count"));
        return cl;
    }
}
