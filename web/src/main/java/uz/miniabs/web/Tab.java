package uz.miniabs.web;

/** Status tabi: Barchasi 48, Jismoniy 40, ... */
public class Tab {

    private final String key;
    private final String label;
    private final long count;
    private final String url;
    private final boolean active;

    public Tab(String key, String label, Number count, String url, boolean active) {
        this.key = key;
        this.label = label;
        this.count = count == null ? 0 : count.longValue();
        this.url = url;
        this.active = active;
    }

    public String getKey() { return key; }
    public String getLabel() { return label; }
    public long getCount() { return count; }
    public String getUrl() { return url; }
    public boolean isActive() { return active; }
}
