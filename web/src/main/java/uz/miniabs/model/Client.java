package uz.miniabs.model;

import java.time.LocalDateTime;

public class Client {

    private long id;
    private String type;          // J = jismoniy, Y = yuridik
    private String fullName;
    private String taxCode;
    private String phone;
    private String address;
    private String status;        // A = faol, B = bloklangan
    private LocalDateTime createdAt;
    private int accountCount;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getTaxCode() { return taxCode; }
    public void setTaxCode(String taxCode) { this.taxCode = taxCode; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public int getAccountCount() { return accountCount; }
    public void setAccountCount(int accountCount) { this.accountCount = accountCount; }

    public boolean isCompany() { return "Y".equals(type); }
    public boolean isActive() { return "A".equals(status); }
}
