<%@ include file="common/taglibs.jspf" %>
<c:set var="pageTitle" value="Operatsiyalar jurnali"/>
<%@ include file="common/header.jspf" %>

<section class="page">
  <div class="page-head">
    <div>
      <div class="crumbs"><svg class="i"><use href="#i-home"/></svg>Operatsiyalar<svg class="i"><use href="#i-chev-right"/></svg><b>${empty statement ? 'Jurnal' : "Ko'chirma"}</b></div>
      <h1>${empty statement ? 'Operatsiyalar jurnali' : 'Hisob ko\'chirmasi'}</h1>
    </div>
  </div>

  <div class="summary">
    <c:choose>
      <c:when test="${not empty statement}">
        <div class="card sum"><div class="ic ic-teal"><svg class="i"><use href="#i-wallet"/></svg></div><div><small>Davr boshidagi qoldiq</small><b>${f:money(statement.opening)}</b></div></div>
        <div class="card sum"><div class="ic ic-green"><svg class="i"><use href="#i-arrow-in"/></svg></div><div><small>Kirim, so'm</small><b>${f:money(statement.credit)}</b></div></div>
        <div class="card sum"><div class="ic ic-red"><svg class="i"><use href="#i-arrow-out"/></svg></div><div><small>Chiqim, so'm</small><b>${f:money(statement.debit)}</b></div></div>
        <div class="card sum"><div class="ic ic-blue"><svg class="i"><use href="#i-bank"/></svg></div><div><small>Davr oxiridagi qoldiq</small><b>${f:money(statement.closing)}</b></div></div>
      </c:when>
      <c:otherwise>
        <div class="card sum"><div class="ic ic-teal"><svg class="i"><use href="#i-doc"/></svg></div><div><small>Operatsiyalar</small><b>${f:money0(counts.ALL)}</b></div></div>
        <div class="card sum"><div class="ic ic-green"><svg class="i"><use href="#i-check-circle"/></svg></div><div><small>Bajarilgan</small><b>${f:money0(counts.S)}</b></div></div>
        <div class="card sum"><div class="ic ic-red"><svg class="i"><use href="#i-x-circle"/></svg></div><div><small>Rad etilgan</small><b>${f:money0(counts.R)}</b></div></div>
        <div class="card sum"><div class="ic ic-blue"><svg class="i"><use href="#i-wallet"/></svg></div><div><small>Aylanma, mln so'm</small><b>${f:millions(counts.turnover)}</b></div></div>
      </c:otherwise>
    </c:choose>
  </div>

  <div class="card">
    <form method="get" action="${ctx}/journal" id="listForm">
      <input type="hidden" name="tab" value="${fn:escapeXml(q.get('tab'))}">
      <input type="hidden" name="sort" value="${fn:escapeXml(q.get('sort'))}">
      <input type="hidden" name="size" value="${fn:escapeXml(q.get('size'))}">
      <div class="toolbar">
        <label class="search"><input name="q" value="${fn:escapeXml(q.get('q'))}" placeholder="Hujjat raqami, hisob yoki mijoz" aria-label="Qidirish" data-autosubmit><svg class="i"><use href="#i-search"/></svg></label>
        <div class="grow"></div>
        <div class="tb-btns">
          <a class="btn btn-gray" href="${fn:escapeXml(q.url)}"><svg class="i"><use href="#i-refresh"/></svg><span>Yangilash</span></a>
          <a class="btn btn-red" href="${ctx}/journal"><svg class="i"><use href="#i-x-circle"/></svg><span>Tozalash</span></a>
          <button type="button" class="btn btn-sage" data-filter-toggle aria-pressed="${filterCount > 0}"><svg class="i"><use href="#i-filter"/></svg><span>Filtr</span><c:if test="${filterCount > 0}"><span class="fcount">${filterCount}</span></c:if></button>
          <a class="btn btn-primary" href="${ctx}/transfer${empty statementAcc ? '' : '?from='.concat(statementAcc)}"><svg class="i"><use href="#i-plus"/></svg><span>Yangi o'tkazma</span></a>
        </div>
      </div>
      <div data-filters ${filterCount > 0 ? '' : 'hidden'}>
        <div class="filters">
          <div class="field"><label for="fAcc">Hisob raqam (ko'chirma)</label><input id="fAcc" name="acc" class="mono" maxlength="20" inputmode="numeric" value="${fn:escapeXml(q.get('acc'))}" placeholder="20 xona"></div>
          <div class="field"><label for="fFrom">Sana (dan)</label><input id="fFrom" type="date" name="from" value="${fn:escapeXml(q.get('from'))}"></div>
          <div class="field"><label for="fTo">Sana (gacha)</label><input id="fTo" type="date" name="to" value="${fn:escapeXml(q.get('to'))}"></div>
          <div class="field"><label for="fPur">To'lov maqsadi</label>
            <select id="fPur" name="pur">
              <option value="">Barchasi</option>
              <c:forEach var="p" items="${applicationScope.purposes}">
                <option value="${p.key}" ${q.get('pur') == p.key ? 'selected' : ''}>${p.key} · ${p.value}</option>
              </c:forEach>
            </select></div>
        </div>
        <div class="filters-foot"><button type="submit" class="btn btn-primary btn-sm"><svg class="i"><use href="#i-check"/></svg>Qo'llash</button></div>
      </div>
    </form>

    <c:if test="${not empty statementAcc}">
      <div class="chips"><span class="fchip">Hisob: <span class="mono">${statementAcc}</span> · <c:out value="${statementOwner}"/><a href="${fn:escapeXml(q.without('acc'))}" aria-label="Olib tashlash"><svg class="i" style="width:12px;height:12px"><use href="#i-x"/></svg></a></span></div>
    </c:if>

    <c:set var="part" value="tabs"/><%@ include file="common/list-parts.jspf" %>

    <div class="table-wrap">
      <table>
        <thead><tr>
          <th><a href="${fn:escapeXml(q.sortUrl('doc'))}">Hujjat №<span class="sort">${q.sortIcon('doc')}</span></a></th>
          <th><a href="${fn:escapeXml(q.sortUrl('date'))}">Sana va vaqt<span class="sort">${q.sortIcon('date')}</span></a></th>
          <th>Jo'natuvchi</th>
          <th>Qabul qiluvchi</th>
          <th class="num"><a href="${fn:escapeXml(q.sortUrl('amount'))}">Summa, so'm<span class="sort">${q.sortIcon('amount')}</span></a></th>
          <th>To'lov maqsadi</th>
          <th>Operator</th>
          <th>Holat</th>
        </tr></thead>
        <tbody>
          <c:forEach var="t" items="${result.items}">
            <tr>
              <td><span class="mono" style="font-weight:600">${t.docNo}</span></td>
              <td>${f:date(t.tranDate)} <span class="muted">${f:time(t.tranDate)}</span></td>
              <td><div class="person"><div class="avatar${t.fromType == 'Y' ? ' org' : ''}">${f:initials(t.fromName)}</div><div><b><c:out value="${t.fromName}"/></b><small class="mono">${t.fromAcc}</small></div></div></td>
              <td><div class="person"><div class="avatar${t.toType == 'Y' ? ' org' : ''}">${empty t.toName ? '?' : f:initials(t.toName)}</div><div><b><c:out value="${empty t.toName ? 'Hisob topilmadi' : t.toName}"/></b><small class="mono"><c:out value="${t.toAcc}"/></small></div></div></td>
              <td class="num"><span class="amount ${t.direction == 'IN' ? 'in' : (t.direction == 'OUT' ? 'out' : '')}">${t.direction == 'IN' ? '+' : (t.direction == 'OUT' ? '−' : '')}${f:money(t.amount)}</span></td>
              <td><span class="tag mono">${t.purposeCode}</span> <c:out value="${empty t.description ? t.purposeName : t.description}"/></td>
              <td><span class="mono"><c:out value="${t.createdBy}"/></span></td>
              <td>
                <c:choose>
                  <c:when test="${t.success}"><span class="badge b-green">Bajarildi</span></c:when>
                  <c:otherwise><span class="badge b-red" title="${fn:escapeXml(t.errorCode)}: ${fn:escapeXml(t.errorMsg)}">Rad etildi</span></c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
          <c:if test="${empty result.items}">
            <tr><td class="empty" colspan="8"><svg class="i"><use href="#i-search"/></svg>Hech narsa topilmadi. Qidiruv yoki filtrlarni o'zgartirib ko'ring.</td></tr>
          </c:if>
        </tbody>
      </table>
    </div>

    <c:set var="part" value="pager"/><%@ include file="common/list-parts.jspf" %>
  </div>
</section>

<%@ include file="common/footer.jspf" %>
