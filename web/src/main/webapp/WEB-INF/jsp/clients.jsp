<%@ include file="common/taglibs.jspf" %>
<c:set var="pageTitle" value="Mijozlar ro'yxati"/>
<%@ include file="common/header.jspf" %>

<section class="page">
  <div class="page-head">
    <div>
      <div class="crumbs"><svg class="i"><use href="#i-home"/></svg>Mijozlar<svg class="i"><use href="#i-chev-right"/></svg><b>Ro'yxat</b></div>
      <h1>Mijozlar ro'yxati</h1>
    </div>
  </div>

  <div class="card">
    <form method="get" action="${ctx}/clients" id="listForm">
      <input type="hidden" name="tab" value="${fn:escapeXml(q.get('tab'))}">
      <input type="hidden" name="sort" value="${fn:escapeXml(q.get('sort'))}">
      <input type="hidden" name="size" value="${fn:escapeXml(q.get('size'))}">
      <div class="toolbar">
        <label class="search"><input name="q" value="${fn:escapeXml(q.get('q'))}" placeholder="F.I.Sh., PINFL, INN yoki telefon" aria-label="Qidirish" data-autosubmit><svg class="i"><use href="#i-search"/></svg></label>
        <div class="grow"></div>
        <div class="tb-btns">
          <a class="btn btn-gray" href="${fn:escapeXml(q.url)}"><svg class="i"><use href="#i-refresh"/></svg><span>Yangilash</span></a>
          <a class="btn btn-red" href="${ctx}/clients"><svg class="i"><use href="#i-x-circle"/></svg><span>Tozalash</span></a>
          <button type="button" class="btn btn-sage" data-filter-toggle aria-pressed="${filterCount > 0}"><svg class="i"><use href="#i-filter"/></svg><span>Filtr</span><c:if test="${filterCount > 0}"><span class="fcount">${filterCount}</span></c:if></button>
          <button type="button" class="btn btn-primary" data-new-client><svg class="i"><use href="#i-plus"/></svg><span>Yangi mijoz</span></button>
        </div>
      </div>
      <div data-filters ${filterCount > 0 ? '' : 'hidden'}>
        <div class="filters">
          <div class="field"><label for="fType">Mijoz turi</label>
            <select id="fType" name="type">
              <option value="">Barchasi</option>
              <option value="J" ${q.get('type') == 'J' ? 'selected' : ''}>Jismoniy shaxs</option>
              <option value="Y" ${q.get('type') == 'Y' ? 'selected' : ''}>Yuridik shaxs</option>
            </select></div>
          <div class="field"><label for="fSt">Holat</label>
            <select id="fSt" name="st">
              <option value="">Barchasi</option>
              <option value="A" ${q.get('st') == 'A' ? 'selected' : ''}>Faol</option>
              <option value="B" ${q.get('st') == 'B' ? 'selected' : ''}>Bloklangan</option>
            </select></div>
          <div class="field"><label for="fFrom">Ro'yxatga olingan (dan)</label><input id="fFrom" type="date" name="from" value="${fn:escapeXml(q.get('from'))}"></div>
          <div class="field"><label for="fTo">Ro'yxatga olingan (gacha)</label><input id="fTo" type="date" name="to" value="${fn:escapeXml(q.get('to'))}"></div>
        </div>
        <div class="filters-foot"><button type="submit" class="btn btn-primary btn-sm"><svg class="i"><use href="#i-check"/></svg>Qo'llash</button></div>
      </div>
    </form>

    <c:set var="part" value="tabs"/><%@ include file="common/list-parts.jspf" %>

    <div class="table-wrap">
      <table>
        <thead><tr>
          <th><a href="${fn:escapeXml(q.sortUrl('id'))}">ID<span class="sort">${q.sortIcon('id')}</span></a></th>
          <th><a href="${fn:escapeXml(q.sortUrl('name'))}">Mijoz<span class="sort">${q.sortIcon('name')}</span></a></th>
          <th>PINFL / INN</th>
          <th>Telefon</th>
          <th>Hisoblar</th>
          <th><a href="${fn:escapeXml(q.sortUrl('date'))}">Ro'yxatga olingan<span class="sort">${q.sortIcon('date')}</span></a></th>
          <th>Holat</th>
          <th class="num">Amallar</th>
        </tr></thead>
        <tbody>
          <c:forEach var="cl" items="${result.items}">
            <tr>
              <td><span class="mono">${cl.id}</span></td>
              <td><div class="person"><div class="avatar${cl.company ? ' org' : ''}">${f:initials(cl.fullName)}</div><div><b><c:out value="${cl.fullName}"/></b><small>${cl.company ? 'Yuridik shaxs' : 'Jismoniy shaxs'}</small></div></div></td>
              <td><span class="mono">${cl.taxCode}</span></td>
              <td><span class="mono">${f:phone(cl.phone)}</span></td>
              <td><a class="tag" href="${ctx}/accounts?client=${cl.id}" style="text-decoration:none">${cl.accountCount} ta</a></td>
              <td>${f:date(cl.createdAt)}</td>
              <td><span class="badge ${cl.active ? 'b-green' : 'b-red'}">${cl.active ? 'Faol' : 'Bloklangan'}</span></td>
              <td class="num"><div class="actions">
                <button type="button" class="btn btn-ghost btn-sm" title="Tahrirlash" data-edit-client
                        data-id="${cl.id}" data-type="${cl.type}" data-name="${fn:escapeXml(cl.fullName)}"
                        data-tax="${cl.taxCode}" data-phone="${f:phone(cl.phone)}" data-address="${fn:escapeXml(cl.address)}"><svg class="i"><use href="#i-edit"/></svg></button>
                <a class="btn btn-ghost btn-sm" title="Hisoblarini ko'rish" href="${ctx}/accounts?client=${cl.id}"><svg class="i"><use href="#i-wallet"/></svg></a>
                <button type="button" class="btn btn-ghost btn-sm" title="${cl.active ? 'Bloklash' : 'Faollashtirish'}" style="color:${cl.active ? 'var(--red)' : 'var(--green-ink)'}"
                        data-confirm data-action="${ctx}/clients" data-danger="${cl.active}"
                        data-title="${cl.active ? 'Mijozni bloklash' : 'Mijozni faollashtirish'}"
                        data-text="${fn:escapeXml(cl.fullName)} · ID ${cl.id}"
                        data-ok="${cl.active ? 'Bloklash' : 'Faollashtirish'}"
                        data-f-action="status" data-f-id="${cl.id}" data-f-status="${cl.active ? 'B' : 'A'}"><svg class="i"><use href="#i-${cl.active ? 'lock' : 'unlock'}"/></svg></button>
              </div></td>
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

<%-- Mijoz qo'shish / tahrirlash oynasi --%>
<div class="overlay" id="clientModal" ${empty form ? 'hidden' : 'data-autoopen'}>
  <form class="modal" method="post" action="${ctx}/clients" id="clientForm" role="dialog" aria-modal="true" aria-labelledby="cmTitle">
    <input type="hidden" name="_csrf" value="${sessionScope.csrf}">
    <input type="hidden" name="back" value="${fn:escapeXml(empty form ? q.url : form.back)}">
    <input type="hidden" name="id" value="${fn:escapeXml(form.id)}">
    <div class="modal-head"><div><h2 id="cmTitle">${empty form.id ? 'Yangi mijoz' : 'Mijozni tahrirlash'}</h2><p>Majburiy maydonlar <span style="color:var(--red)">*</span> bilan belgilangan</p></div><button type="button" class="icon-btn" data-close aria-label="Yopish"><svg class="i"><use href="#i-x"/></svg></button></div>
    <div class="modal-body">
      <div class="radio-cards" role="radiogroup" aria-label="Mijoz turi">
        <label><input type="radio" name="type" value="J" ${form.type != 'Y' ? 'checked' : ''}><svg class="i"><use href="#i-user"/></svg>Jismoniy shaxs</label>
        <label><input type="radio" name="type" value="Y" ${form.type == 'Y' ? 'checked' : ''}><svg class="i"><use href="#i-building"/></svg>Yuridik shaxs</label>
      </div>
      <div class="grid-2">
        <div class="field span-2"><label for="cmName" id="cmNameLbl">F.I.Sh. <span class="req">*</span></label><input id="cmName" name="fullName" value="${fn:escapeXml(form.fullName)}" placeholder="Familiya Ism Otasining ismi" required minlength="3" maxlength="200"></div>
        <div class="field"><label for="cmCode" id="cmCodeLbl">PINFL <span class="req">*</span></label><input id="cmCode" name="taxCode" class="mono" value="${fn:escapeXml(form.taxCode)}" inputmode="numeric" maxlength="14" placeholder="14 ta raqam" required></div>
        <div class="field"><label for="cmPhone">Telefon <span class="req">*</span></label><input id="cmPhone" name="phone" class="mono" value="${fn:escapeXml(form.phone)}" placeholder="+998 90 123 45 67" required></div>
        <div class="field span-2"><label for="cmAddr">Manzil</label><input id="cmAddr" name="address" value="${fn:escapeXml(form.address)}" placeholder="Viloyat, tuman, ko'cha, uy" maxlength="300"></div>
      </div>
      <c:if test="${not empty formError}">
        <div class="alert err"><svg class="i"><use href="#i-alert"/></svg><span><code>${formError.oraCode}</code> <c:out value="${formError.message}"/></span></div>
      </c:if>
    </div>
    <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Bekor qilish</button><button type="submit" class="btn btn-primary"><svg class="i"><use href="#i-check"/></svg>Saqlash</button></div>
  </form>
</div>

<%@ include file="common/footer.jspf" %>
