<%@ page isErrorPage="true" %>
<%@ include file="common/taglibs.jspf" %>
<c:set var="pageTitle" value="Xato"/>
<!DOCTYPE html>
<html lang="uz">
<head>
<%@ include file="common/head.jspf" %>
</head>
<body>
<div class="err-page">
  <div class="card login-card" style="align-items:center">
    <h1>${empty requestScope['jakarta.servlet.error.status_code'] ? 500 : requestScope['jakarta.servlet.error.status_code']}</h1>
    <p>Kutilmagan xato yuz berdi. Sahifani yangilang yoki birozdan keyin urinib ko'ring.</p>
    <a class="btn btn-primary" href="${ctx}/clients">Bosh sahifaga qaytish</a>
  </div>
</div>
</body>
</html>
