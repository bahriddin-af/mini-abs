<%@ include file="common/taglibs.jspf" %>
<c:set var="pageTitle" value="Pul o'tkazish"/>
<%@ include file="common/header.jspf" %>

<section class="page">
  <div class="page-head">
    <div>
      <div class="crumbs"><svg class="i"><use href="#i-home"/></svg>Operatsiyalar<svg class="i"><use href="#i-chev-right"/></svg><b>Pul o'tkazish</b></div>
      <h1>Pul o'tkazish</h1>
    </div>
  </div>

  <div class="transfer">
    <form class="card" method="post" action="${ctx}/transfer" id="trForm">
      <input type="hidden" name="_csrf" value="${sessionScope.csrf}">
      <div class="card-head"><div><h2>To'lov hujjati</h2><small>Hisobdan hisobga ichki o'tkazma (UZS)</small></div><span class="tag">Yangi hujjat</span></div>
      <div class="card-body">
        <div class="field"><label for="trFrom">Jo'natuvchi hisob <span class="req">*</span></label>
          <select id="trFrom" name="from" class="mono" data-reload-from>
            <c:forEach var="a" items="${accounts}">
              <option value="${a.accountNo}" ${selected.accountNo == a.accountNo ? 'selected' : ''}>${a.accountNo} · <c:out value="${a.clientName}"/>${a.active ? '' : ' (bloklangan)'}</option>
            </c:forEach>
          </select></div>
        <div class="balance">
          <div><small>Mavjud qoldiq</small><b>${f:money(selected.balance)} so'm</b></div>
          <span class="badge ${selected.active ? 'b-green' : 'b-red'}">${selected.active ? 'Faol' : 'Bloklangan'}</span>
        </div>
        <div class="field"><label for="trTo">Qabul qiluvchi hisob <span class="req">*</span></label>
          <input id="trTo" name="to" class="mono" maxlength="20" inputmode="numeric" placeholder="20 xonali hisob raqam" value="${fn:escapeXml(form.to)}" required pattern="[0-9]{20}" autocomplete="off">
          <div class="owner" id="trOwner">20 xonali hisob raqamini kiriting</div></div>
        <div class="grid-2">
          <div class="field"><label for="trAmt">Summa, so'm <span class="req">*</span></label><input id="trAmt" name="amount" class="amount-input" inputmode="decimal" value="${fn:escapeXml(form.amount)}" placeholder="0" required autocomplete="off"></div>
          <div class="field"><label for="trPurpose">To'lov maqsadi</label>
            <select id="trPurpose" name="purpose">
              <c:forEach var="p" items="${applicationScope.purposes}">
                <option value="${p.key}" ${form.purpose == p.key or (empty form.purpose and p.key == '00668') ? 'selected' : ''}>${p.key} · ${p.value}</option>
              </c:forEach>
            </select></div>
        </div>
        <div class="field"><label for="trNote">Izoh</label><input id="trNote" name="description" maxlength="250" value="${fn:escapeXml(form.description)}" placeholder="Masalan: qarz qaytarildi"></div>
        <c:if test="${not empty error}">
          <div class="alert err"><svg class="i"><use href="#i-alert"/></svg><span><c:out value="${error}"/></span></div>
        </c:if>
      </div>
      <div class="form-foot"><a class="btn btn-outline" href="${ctx}/transfer?from=${selected.accountNo}">Tozalash</a><button type="submit" class="btn btn-primary"><svg class="i"><use href="#i-swap"/></svg>O'tkazish</button></div>
    </form>

    <div class="card">
      <div class="card-head"><div><h2>Shu hisob bo'yicha oxirgi operatsiyalar</h2><small class="mono">${selected.accountNo}</small></div>
        <a class="btn btn-ghost btn-sm" href="${ctx}/journal?acc=${selected.accountNo}">Ko'chirma</a></div>
      <div class="mini-list">
        <c:forEach var="t" items="${recent}">
          <div>
            <div class="person"><div class="avatar${t.toType == 'Y' ? ' org' : ''}">${f:initials(t.toName)}</div><div><b><c:out value="${t.toName}"/></b><small>${t.docNo} · ${f:dateTime(t.tranDate)}</small></div></div>
            <span class="amount ${t.success ? (t.direction == 'IN' ? 'in' : 'out') : ''}" style="${t.success ? '' : 'color:var(--faint);text-decoration:line-through'}" title="${t.success ? '' : 'Rad etilgan'}">${t.direction == 'IN' ? '+' : '−'}${f:money(t.amount)}</span>
          </div>
        </c:forEach>
        <c:if test="${empty recent}"><div class="muted" style="justify-content:center;padding:32px 20px">Bu hisob bo'yicha operatsiyalar yo'q</div></c:if>
      </div>
    </div>
  </div>
</section>

<c:if test="${not empty receipt}">
  <div class="overlay" id="receiptModal" data-autoopen>
    <div class="modal sm" role="dialog" aria-modal="true" aria-labelledby="rcTitle">
      <div class="receipt"><div class="ok"><svg class="i"><use href="#i-check"/></svg></div><h2 id="rcTitle">O'tkazma bajarildi</h2><div class="sum-big">${f:money(receipt.amount)} so'm</div></div>
      <dl class="kv">
        <div><dt>Hujjat raqami</dt><dd class="mono">${receipt.docNo}</dd></div>
        <div><dt>Sana</dt><dd>${f:dateTime(receipt.tranDate)}</dd></div>
        <div><dt>Jo'natuvchi</dt><dd><c:out value="${receipt.fromName}"/></dd></div>
        <div><dt>Qabul qiluvchi</dt><dd><c:out value="${receipt.toName}"/></dd></div>
        <div><dt>Maqsad</dt><dd>${receipt.purposeCode} · <c:out value="${empty receipt.description ? receipt.purposeName : receipt.description}"/></dd></div>
        <div><dt>Yangi qoldiq</dt><dd>${f:money(selected.balance)} so'm</dd></div>
      </dl>
      <div class="modal-foot"><a class="btn btn-outline" href="${ctx}/journal?q=${receipt.docNo}">Jurnalda ko'rish</a><button type="button" class="btn btn-primary" data-close>Yangi o'tkazma</button></div>
    </div>
  </div>
</c:if>

<%@ include file="common/footer.jspf" %>
