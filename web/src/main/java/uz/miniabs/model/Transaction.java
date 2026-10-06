package uz.miniabs.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Operatsiyalar jurnalidagi bitta qator */
public class Transaction {

    private String docNo;
    private LocalDateTime tranDate;
    private String fromAcc;
    private String fromName;
    private String fromType;
    private String toAcc;
    private String toName;
    private String toType;
    private BigDecimal amount;
    private String purposeCode;
    private String purposeName;
    private String description;
    private String status;        // S = bajarildi, R = rad etildi
    private String errorCode;
    private String errorMsg;
    private String createdBy;
    private String direction;     // IN / OUT (hisob bo'yicha filtrda)

    public String getDocNo() { return docNo; }
    public void setDocNo(String docNo) { this.docNo = docNo; }
    public LocalDateTime getTranDate() { return tranDate; }
    public void setTranDate(LocalDateTime tranDate) { this.tranDate = tranDate; }
    public String getFromAcc() { return fromAcc; }
    public void setFromAcc(String fromAcc) { this.fromAcc = fromAcc; }
    public String getFromName() { return fromName; }
    public void setFromName(String fromName) { this.fromName = fromName; }
    public String getFromType() { return fromType; }
    public void setFromType(String fromType) { this.fromType = fromType; }
    public String getToAcc() { return toAcc; }
    public void setToAcc(String toAcc) { this.toAcc = toAcc; }
    public String getToName() { return toName; }
    public void setToName(String toName) { this.toName = toName; }
    public String getToType() { return toType; }
    public void setToType(String toType) { this.toType = toType; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getPurposeCode() { return purposeCode; }
    public void setPurposeCode(String purposeCode) { this.purposeCode = purposeCode; }
    public String getPurposeName() { return purposeName; }
    public void setPurposeName(String purposeName) { this.purposeName = purposeName; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getErrorCode() { return errorCode; }
    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }
    public String getErrorMsg() { return errorMsg; }
    public void setErrorMsg(String errorMsg) { this.errorMsg = errorMsg; }
    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
    public String getDirection() { return direction; }
    public void setDirection(String direction) { this.direction = direction; }

    public boolean isSuccess() { return "S".equals(status); }
}
