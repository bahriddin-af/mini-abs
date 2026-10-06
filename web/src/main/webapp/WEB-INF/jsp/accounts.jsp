<%@ include file="common/taglibs.jspf" %>
<c:set var="pageTitle" value="Hisob raqamlar"/>
<%@ include file="common/header.jspf" %>

<section class="page">
  <div class="page-head">
    <div>
      <div class="crumbs"><svg class="i"><use href="#i-home"/></svg>Hisob raqamlar<svg class="i"><use href="#i-chev-right"/></svg><b>Barcha hisoblar</b></div>
      <h1>Hisob raqamlar</h1>
    </div>
  </div>

  <div class="summary">
    <div class="card sum"><div class="ic ic-teal"><svg class="i"><use href="#i-wallet"/></svg></div><div><small>Jami hisoblar</small><b>${f:money0(summary.total)}</b></div></div>
    <div class="card sum"><div class="ic ic-blue"><svg class="i"><use href="#i-bank"/></svg></div><div><small>UZS qoldiq, mln so'm</small><b>${f:millions(summary.uzs)}</b></div></div>
    <div class="card sum"><div class="ic ic-green"><svg class="i"><use href="#i-wallet"/></svg></div><div><small>USD qoldiq, $</small><b>${f:money0(summary.usd)}</b></div></div>
    <div class="card sum"><div class="ic ic-red"><svg class="i"><use href="#i-lock"/></svg></div><div><small>Bloklangan</small><b>${f:money0(summary.blocked)}</b></div></div>
  </div>

  <div class="card">
    <form method="get" action="${ctx}/accounts" id="listForm">
      <input type="hidden" name="tab" value="${fn:escapeXml(q.get('tab'))}">
      <input type="hidden" name="sort" value="${fn:escapeXml(q.get('sort'))}">
      <input type="hidden" name="size" value="${fn:escapeXml(q.get('size'))}">
      <input type="hidden" name="client" value="${fn:escapeXml(q.get('client'))}">
      <div class="toolbar">
        <label class="search"><input name="q" value="${fn:escapeXml(q.get('q'))}" placeholder="Hisob raqam yoki mijoz nomi" aria-label="Qidirish" data-autosubmit><svg class="i"><use href="#i-search"/></svg></label>
        <div class="grow"></div>
        <div class="tb-btns">
          <a class="btn btn-gray" href="${fn:escapeXml(q.url)}"><svg class="i"><use href="#i-refresh"/></svg><span>Yangilash</span></a>
          <a class="btn btn-red" href="${ctx}/accounts"><svg class="i"><use href="#i-x-circle"/></svg><span>Tozalash</span></a>
          <button type="button" class="btn btn-sage" data-filter-toggle aria-pressed="${filterCount > 0}"><svg class="i"><use href="#i-filter"/></svg><span>Filtr</span><c:if test="${filterCount > 0}"><span class="fcount">${filterCount}</span></c:if></button>
          <button type="button" class="btn btn-primary" data-open="accModal"><svg class="i"><use href="#i-plus"/></svg><span>Hisob ochish</span></button>
        </div>
      </div>
      <div data-filters ${filterCount > 0 ? '' : 'hidden'}>
        <div class="filters">
          <div class="field"><label for="fBs">Balans hisobi</label>
            <select id="fBs" name="bs">
              <option value="">Barchasi</option>
              <option value="20206" ${q.get('bs') == '20206' ? 'selected' : ''}>20206 · Jismoniy shaxslar</option>
              <option value="20208" ${q.get('bs') == '20208' ? 'selected' : ''}>20208 · Yuridik shaxslar</option>
            </select></div>
          <div class="field"><label for="fMin">Qoldiq (dan)</label><input id="fMin" type="number" min="0" name="min" value="${fn:escapeXml(q.get('min'))}" placeholder="0"></div>
          <div class="field"><label for="fMax">Qoldiq (gacha)</label><input id="fMax" type="number" min="0" name="max" value="${fn:escapeXml(q.get('max'))}" placeholder="cheksiz"></div>
          <div class="field"><label for="fFrom">Ochilgan (dan)</label><input id="fFrom" type="date" name="from" value="${fn:escapeXml(q.get('from'))}"></div>
        </div>
        <div class="filters-foot"><button type="submit" class="btn btn-primary btn-sm"><svg class="i"><use href="#i-check"/></svg>Qo'llash</button></div>
      </div>
    </form>

    <c:if test="${not empty filterClient}">
      <div class="chips"><span class="fchip">Mijoz: <c:out value="${filterClient.fullName}"/><a href="${fn:escapeXml(q.without('client'))}" aria-label="Olib tashlash"><svg class="i" style="width:12px;height:12px"><use href="#i-x"/></svg></a></span></div>
    </c:if>

    <c:set var="part" value="tabs"/><%@ include file="common/list-parts.jspf" %>

    <div class="table-wrap">
      <table>
        <thead><tr>
          <th><a href="${fn:escapeXml(q.sortUrl('no'))}">Hisob raqam<span class="sort">${q.sortIcon('no')}</span></a></th>
          <th><a href="${fn:escapeXml(q.sortUrl('client'))}">Mijoz<span class="sort">${q.sortIcon('client')}</span></a></th>
          <th>Valyuta</th>
          <th class="num"><a href="${fn:escapeXml(q.sortUrl('balance'))}">Qoldiq<span class="sort">${q.sortIcon('balance')}</span></a></th>
          <th><a href="${fn:escapeXml(q.sortUrl('date'))}">Ochilgan sana<span class="sort">${q.sortIcon('date')}</span></a></th>
          <th>Holat</th>
          <th class="num">Amallar</th>
        </tr></thead>
        <tbody>
          <c:forEach var="a" items="${result.items}">
            <tr>
              <td><span class="mono" style="font-weight:600">${a.accountNo}</span></td>
              <td><div class="person"><div class="avatar${a.clientType == 'Y' ? ' org' : ''}">${f:initials(a.clientName)}</div><div><b><c:out value="${a.clientName}"/></b><small>ID ${a.clientId}</small></div></div></td>
              <td><span class="tag">${a.currency}</span></td>
              <td class="num"><span class="amount">${f:money(a.balance)}</span></td>
              <td>${f:date(a.openedAt)}</td>
              <td><span class="badge ${a.active ? 'b-green' : 'b-red'}" title="${fn:escapeXml(a.blockReason)}">${a.active ? 'Faol' : 'Bloklangan'}</span></td>
              <td class="num"><div class="actions">
                <a class="btn btn-ghost btn-sm" title="Ko'chirma" href="${ctx}/journal?acc=${a.accountNo}"><svg class="i"><use href="#i-doc"/></svg></a>
                <button type="button" class="btn btn-ghost btn-sm" title="${a.active ? 'Bloklash' : 'Blokdan chiqarish'}" style="color:${a.active ? 'var(--red)' : 'var(--green-ink)'}"
                        data-confirm data-action="${ctx}/accounts" data-danger="${a.active}" data-reason="${a.active}"
                        data-title="${a.active ? 'Hisobni bloklash' : 'Hisobni blokdan chiqarish'}"
                        data-text="${a.accountNo} · ${fn:escapeXml(a.clientName)}"
                        data-ok="${a.active ? 'Bloklash' : 'Blokdan chiqarish'}"
                        data-f-action="status" data-f-account-no="${a.accountNo}" data-f-status="${a.active ? 'B' : 'A'}"><svg class="i"><use href="#i-${a.active ? 'lock' : 'unlock'}"/></svg></button>
              </div></td>
            </tr>
          </c:forEach>
          <c:if test="${empty result.items}">
            <tr><td class="empty" colspan="7"><svg class="i"><use href="#i-search"/></svg>Hech narsa topilmadi. Qidiruv yoki filtrlarni o'zgartirib ko'ring.</td></tr>
          </c:if>
        </tbody>
      </table>
    </div>

    <c:set var="part" value="pager"/><%@ include file="common/list-parts.jspf" %>
  </div>
</section>

<%-- Hisob ochish oynasi --%>
<div class="overlay" id="accModal" hidden>
  <form class="modal" method="post" action="${ctx}/accounts" role="dialog" aria-modal="true" aria-labelledby="amTitle">
    <input type="hidden" name="_csrf" value="${sessionScope.csrf}">
    <input type="hidden" name="action" value="open">
    <input type="hidden" name="back" value="${fn:escapeXml(q.url)}">
    <div class="modal-head"><div><h2 id="amTitle">Hisob ochish</h2><p>Hisob raqam avtomatik yaratiladi</p></div><button type="button" class="icon-btn" data-close aria-label="Yopish"><svg class="i"><use href="#i-x"/></svg></button></div>
    <div class="modal-body">
      <div class="field"><label for="amClient">Mijoz <span class="req">*</span></label>
        <select id="amClient" name="clientId" required>
          <c:forEach var="cl" items="${activeClients}">
            <option value="${cl.id}" ${filterClient.id == cl.id ? 'selected' : ''}>${cl.id} · <c:out value="${cl.fullName}"/></option>
          </c:forEach>
        </select></div>
      <div class="field"><label for="amCur">Valyuta <span class="req">*</span></label>
        <select id="amCur" name="currency"><option value="000">UZS · O'zbek so'mi</option><option value="840">USD · AQSh dollari</option></select></div>
      <div class="field"><label>Hisob raqam tuzilishi</label><div class="acc-preview">20206 000 K 0000XXXX 00N</div>
        <span class="hint">Balans hisobi (5) · valyuta (3) · kalit (1) · mijoz kodi (8) · tartib raqami (3)</span></div>
    </div>
    <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Bekor qilish</button><button type="submit" class="btn btn-primary"><svg class="i"><use href="#i-check"/></svg>Hisob ochish</button></div>
  </form>
</div>

<%@ include file="common/footer.jspf" %>
