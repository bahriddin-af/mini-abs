package uz.miniabs.dao;

import uz.miniabs.db.Db;
import uz.miniabs.db.Jdbc;
import uz.miniabs.model.PageResult;
import uz.miniabs.model.Transaction;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class TransferDao {

    /** pkg_transfer.transfer_money natijasi */
    public static class Result {
        private final String docNo;
        private final BigDecimal newBalance;

        public Result(String docNo, BigDecimal newBalance) {
            this.docNo = docNo;
            this.newBalance = newBalance;
        }

        public String getDocNo() { return docNo; }
        public BigDecimal getNewBalance() { return newBalance; }
    }

    public Result transfer(String user, String from, String to, BigDecimal amount, String purpose, String description) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_transfer.transfer_money(?, ?, ?, ?, ?, ?, ?)}")) {
                Jdbc.str(cs, 1, from);
                Jdbc.str(cs, 2, to);
                Jdbc.num(cs, 3, amount);
                Jdbc.str(cs, 4, purpose);
                Jdbc.str(cs, 5, description);
                cs.registerOutParameter(6, Types.VARCHAR);
                cs.registerOutParameter(7, Types.NUMERIC);
                cs.execute();
                return new Result(cs.getString(6), cs.getBigDecimal(7));
            }
        });
    }

    public PageResult<Transaction> journal(String user, String search, String account, LocalDate from, LocalDate to,
                                           String purpose, String tab, String sort, int page, int size) {
        PageResult<Transaction> result = Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_transfer.get_journal(?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                cs.registerOutParameter(1, Types.REF_CURSOR);
                Jdbc.str(cs, 2, search);
                Jdbc.str(cs, 3, account);
                Jdbc.date(cs, 4, from);
                Jdbc.date(cs, 5, to);
                Jdbc.str(cs, 6, purpose);
                Jdbc.str(cs, 7, tab);
                Jdbc.str(cs, 8, sort);
                cs.setInt(9, page);
                cs.setInt(10, size);
                cs.execute();

                List<Transaction> items = new ArrayList<>();
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
            return journal(user, search, account, from, to, purpose, tab, sort, 1, size);
        }
        return result;
    }

    /** ALL, S, R va turnover (bajarilganlar summasi) */
    public Map<String, BigDecimal> tabCounts(String user, String search, String account,
                                             LocalDate from, LocalDate to, String purpose) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_transfer.get_tab_counts(?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {
                Jdbc.str(cs, 1, search);
                Jdbc.str(cs, 2, account);
                Jdbc.date(cs, 3, from);
                Jdbc.date(cs, 4, to);
                Jdbc.str(cs, 5, purpose);
                for (int i = 6; i <= 9; i++) {
                    cs.registerOutParameter(i, Types.NUMERIC);
                }
                cs.execute();
                Map<String, BigDecimal> m = new LinkedHashMap<>();
                m.put("ALL", cs.getBigDecimal(6));
                m.put("S", cs.getBigDecimal(7));
                m.put("R", cs.getBigDecimal(8));
                m.put("turnover", cs.getBigDecimal(9));
                return m;
            }
        });
    }

    /** Ko'chirma: opening, credit, debit, closing */
    public Map<String, BigDecimal> statementSummary(String user, String account, LocalDate from, LocalDate to) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{call pkg_transfer.get_statement_summary(?, ?, ?, ?, ?, ?, ?)}")) {
                cs.setString(1, account);
                Jdbc.date(cs, 2, from);
                Jdbc.date(cs, 3, to);
                for (int i = 4; i <= 7; i++) {
                    cs.registerOutParameter(i, Types.NUMERIC);
                }
                cs.execute();
                Map<String, BigDecimal> m = new LinkedHashMap<>();
                m.put("opening", cs.getBigDecimal(4));
                m.put("credit", cs.getBigDecimal(5));
                m.put("debit", cs.getBigDecimal(6));
                m.put("closing", cs.getBigDecimal(7));
                return m;
            }
        });
    }

    /** O'tkazma sahifasidagi oxirgi operatsiyalar */
    public List<Transaction> recent(String user, String account) {
        return Db.tx(user, c -> {
            try (CallableStatement cs = c.prepareCall("{? = call pkg_transfer.get_recent(?, ?)}")) {
                cs.registerOutParameter(1, Types.REF_CURSOR);
                cs.setString(2, account);
                cs.setInt(3, 6);
                cs.execute();
                List<Transaction> list = new ArrayList<>();
                try (ResultSet rs = Jdbc.cursor(cs, 1)) {
                    while (rs.next()) {
                        Transaction t = new Transaction();
                        t.setDocNo(rs.getString("doc_no"));
                        t.setTranDate(Jdbc.dateTime(rs, "tran_date"));
                        t.setAmount(rs.getBigDecimal("amount"));
                        t.setStatus(rs.getString("status"));
                        t.setDirection(rs.getString("direction"));
                        t.setToAcc(rs.getString("counter_acc"));
                        t.setToName(rs.getString("counter_name"));
                        t.setToType(rs.getString("counter_type"));
                        list.add(t);
                    }
                }
                return list;
            }
        });
    }

    /** Kvitansiya uchun bitta hujjat */
    public Transaction findByDoc(String user, String docNo) {
        List<Transaction> items = journal(user, docNo, null, null, null, null, "ALL", null, 1, 1).getItems();
        return items.isEmpty() || !items.get(0).getDocNo().equals(docNo) ? null : items.get(0);
    }

    /** To'lov maqsadlari ma'lumotnomasi (ilova ishga tushganda bir marta o'qiladi) */
    public Map<String, String> purposes() {
        return Db.tx("system", c -> {
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT purpose_code, name FROM payment_purposes ORDER BY purpose_code");
                 ResultSet rs = ps.executeQuery()) {
                Map<String, String> m = new LinkedHashMap<>();
                while (rs.next()) {
                    m.put(rs.getString(1), rs.getString(2));
                }
                return m;
            }
        });
    }

    private static Transaction map(ResultSet rs) throws SQLException {
        Transaction t = new Transaction();
        t.setDocNo(rs.getString("doc_no"));
        t.setTranDate(Jdbc.dateTime(rs, "tran_date"));
        t.setFromAcc(rs.getString("from_acc"));
        t.setFromName(rs.getString("from_name"));
        t.setFromType(rs.getString("from_type"));
        t.setToAcc(rs.getString("to_acc"));
        t.setToName(rs.getString("to_name"));
        t.setToType(rs.getString("to_type"));
        t.setAmount(rs.getBigDecimal("amount"));
        t.setPurposeCode(rs.getString("purpose_code"));
        t.setPurposeName(rs.getString("purpose_name"));
        t.setDescription(rs.getString("description"));
        t.setStatus(rs.getString("status"));
        t.setErrorCode(rs.getString("error_code"));
        t.setErrorMsg(rs.getString("error_msg"));
        t.setCreatedBy(rs.getString("created_by"));
        t.setDirection(rs.getString("direction"));
        return t;
    }
}
