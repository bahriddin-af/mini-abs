# Mini-ABS: bank operatori tizimi (JSP + Oracle PL/SQL)

Kichik avtomatlashtirilgan bank tizimi. Unda mijozlar, hisob raqamlar, hisobdan hisobga o'tkazmalar, operatsiyalar jurnali va hisob ko'chirmasi bor.
**Barcha biznes-logika Oracle PL/SQL package'larida yozilgan.** Java (Servlet + JSP) qatlami faqat procedure'larni chaqiradi va natijani ko'rsatadi.

## Tuzilma

```
db/          Oracle: jadvallar, 5 ta package, trigger'lar, namunaviy ma'lumotlar, testlar
web/         Maven WAR: Servlet + JSP + JSTL, HikariCP, ojdbc11
prototype/   Dastlabki HTML dizayn-prototip
run-local.ps1  Lokal yig'ish va Tomcat'da ishga tushirish
```

## Arxitektura

```
Brauzer ──> AuthFilter (login, CSRF) ──> Servlet ──> DAO ──CallableStatement──> PL/SQL package ──> jadvallar
                                            │                                      │
                                            └── JSP + JSTL <── model ──────────────┘ (SYS_REFCURSOR)
```

| Qatlam | Fayllar |
|---|---|
| PL/SQL | `pkg_auth`, `pkg_client`, `pkg_account`, `pkg_transfer`, `pkg_util`, audit trigger'lari |
| DAO | `AuthDao`, `ClientDao`, `AccountDao`, `TransferDao`: har bir metod bitta package chaqiruvi |
| Servlet | `/login`, `/clients`, `/accounts`, `/transfer`, `/journal`, `/api/account-owner` |
| JSP | `WEB-INF/jsp/*.jsp`, umumiy qismlar `common/*.jspf`, EL funksiyalari `WEB-INF/miniabs.tld` |

## Lokal ishga tushirish

1. Bazani o'rnatish: [db/README.md](db/README.md)
2. `powershell -ExecutionPolicy Bypass -File run-local.ps1`
3. http://localhost:8090/miniabs, login `b.abdusalomov`, parol `Operator2026`

## Serverga qo'yish

1. Serverda Oracle bo'lsa, `db/00_create_user.sql` faylidagi PDB nomi va parolni o'zgartirib, `install.sql`ni ishga tushiring.
2. Tomcat 10.1 va Java 17 o'rnating.
3. Ma'lumotlar bazasiga ulanishni muhit o'zgaruvchilari orqali bering. Kod ichida parol saqlanmaydi:
   ```
   MINIABS_DB_URL=jdbc:oracle:thin:@//DB_HOST:1521/PDB_NOMI
   MINIABS_DB_USER=miniabs
   MINIABS_DB_PASSWORD=...
   ```
   Linux'da bular `$CATALINA_BASE/bin/setenv.sh` fayliga `export ...` qilib yoziladi.
4. `web/target/miniabs.war` faylini `webapps/` papkasiga ko'chiring.

## Xavfsizlik

- Parollar SHA-256 va salt bilan saqlanadi. 5 ta noto'g'ri urinishdan keyin foydalanuvchi bloklanadi.
- Barcha POST so'rovlar CSRF token bilan himoyalangan. Login'dan keyin sessiya ID'si almashtiriladi (session fixation'ga qarshi).
- SQL injection'ga qarshi: faqat bind parametrlar ishlatiladi, saralashda dinamik SQL yo'q.
- JSP'da barcha foydalanuvchi ma'lumotlari `c:out` yoki `fn:escapeXml` bilan chiqariladi (XSS'ga qarshi).
- Audit: har bir o'zgarishni trigger'lar operator nomi bilan yozadi (`CLIENT_IDENTIFIER`).
