package uz.miniabs.model;

import java.io.Serializable;

/** Sessiyada saqlanadigan tizimga kirgan operator */
public class User implements Serializable {

    private static final long serialVersionUID = 1L;

    private final long id;
    private final String login;
    private final String fullName;
    private final String role;

    public User(long id, String login, String fullName, String role) {
        this.id = id;
        this.login = login;
        this.fullName = fullName;
        this.role = role;
    }

    public long getId() { return id; }
    public String getLogin() { return login; }
    public String getFullName() { return fullName; }
    public String getRole() { return role; }
    public boolean isAdmin() { return "ADMIN".equals(role); }
}
