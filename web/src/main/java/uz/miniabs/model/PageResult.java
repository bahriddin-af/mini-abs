package uz.miniabs.model;

import java.util.ArrayList;
import java.util.List;

/** Sahifalangan natija va sahifalash tugmalari uchun hisob-kitoblar */
public class PageResult<T> {

    private final List<T> items;
    private final int total;
    private final int page;
    private final int size;

    public PageResult(List<T> items, int total, int page, int size) {
        this.items = items;
        this.total = total;
        this.page = page;
        this.size = size;
    }

    public List<T> getItems() { return items; }
    public int getTotal() { return total; }
    public int getPage() { return page; }
    public int getSize() { return size; }

    public int getPages() {
        return Math.max(1, (total + size - 1) / size);
    }

    public int getFrom() {
        return total == 0 ? 0 : (page - 1) * size + 1;
    }

    public int getTo() {
        return Math.min(page * size, total);
    }

    /** Sahifa raqamlari; 0 = "…" */
    public List<Integer> getPageList() {
        List<Integer> list = new ArrayList<>();
        int pages = getPages();
        for (int i = 1; i <= pages; i++) {
            if (i == 1 || i == pages || Math.abs(i - page) <= 1) {
                list.add(i);
            } else if (list.get(list.size() - 1) != 0) {
                list.add(0);
            }
        }
        return list;
    }
}
