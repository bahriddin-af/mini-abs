<%@ include file="common/taglibs.jspf" %>
<c:set var="pageTitle" value="Kirish"/>
<!DOCTYPE html>
<html lang="uz">
<head>
<%@ include file="common/head.jspf" %>
</head>
<body>
<%@ include file="common/icons.jspf" %>
<div class="login">
  <form class="card login-card" method="post" action="${ctx}/login">
    <input type="hidden" name="_csrf" value="${sessionScope.csrf}">
    <div class="logo"><svg class="i"><use href="#i-bank"/></svg></div>
    <div><h1>Mini-ABS tizimiga kirish</h1><p>Bank operatori uchun ish joyi</p></div>
    <div class="field"><label for="lgUser">Login</label><input id="lgUser" name="login" value="${fn:escapeXml(login)}" autocomplete="username" required autofocus></div>
    <div class="field"><label for="lgPass">Parol</label><input id="lgPass" name="password" type="password" autocomplete="current-password" required></div>
    <c:if test="${not empty error}">
      <div class="alert err"><svg class="i"><use href="#i-alert"/></svg><span><c:out value="${error}"/></span></div>
    </c:if>
    <button class="btn btn-primary" type="submit" style="height:44px">Kirish</button>
    <div class="login-foot">MFO 00014 · Toshkent filiali · v1.0</div>
  </form>
</div>
</body>
</html>
