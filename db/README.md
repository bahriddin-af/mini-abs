# Mini-ABS: ma'lumotlar bazasi (Oracle PL/SQL)

## O'rnatish

```bash
# 1. Sxema yaratish (SYSDBA). Windows'da avval: set ORACLE_SID=FREE
sqlplus / as sysdba @00_create_user.sql

# 2. Jadvallar, package'lar, trigger'lar va namunaviy ma'lumotlar
sqlplus miniabs/MiniAbs2026@//localhost:1521/FREEPDB1 @install.sql

# 3. Testlar (17 ta tekshiruv)
sqlplus miniabs/MiniAbs2026@//localhost:1521/FREEPDB1 @09_tests.sql
```

Serverga qo'yganda `00_create_user.sql` faylidagi `pdb_name` va `app_password` qiymatlarini o'zgartiring.

## Tuzilma

| Fayl | Tarkibi |
|---|---|
| `01_tables.sql` | `clients`, `accounts`, `transactions`, `app_users`, `audit_log`, ma'lumotnomalar |
| `02_pkg_util.sql` | Xato kodlari, joriy foydalanuvchi (`CLIENT_IDENTIFIER`), audit yozish |
| `03_pkg_auth.sql` | Operator yaratish, login (SHA-256 + salt, 5 ta xato urinishdan keyin bloklash) |
| `04_pkg_client.sql` | Mijoz CRUD, validatsiya, sahifalangan qidiruv |
| `05_pkg_account.sql` | Hisob ochish (20 xonali raqam), bloklash, ro'yxat, umumiy ko'rsatkichlar |
| `06_pkg_transfer.sql` | O'tkazma, jurnal, ko'chirma (qoldiq `SUM() OVER` bilan) |
| `07_triggers.sql` | Audit trigger'lari, bajarilgan hujjatni o'zgartirishni taqiqlash |
| `08_seed.sql` | 3 operator, 48 mijoz, 72 hisob, 84 o'tkazma |

## Asosiy yechimlar

- **Barcha biznes-logika PL/SQL'da.** Java faqat procedure'larni chaqiradi.
- **`transfer_money` COMMIT qilmaydi.** Tranzaksiyani chaqiruvchi boshqaradi.
- **Deadlock'ning oldini olish.** Ikkala hisob `SELECT ... FOR UPDATE` bilan doim bir xil tartibda (kichik raqamdan) bloklanadi.
- **Rad etilgan o'tkazmalar** `PRAGMA AUTONOMOUS_TRANSACTION` bilan jurnalga yoziladi, shuning uchun asosiy tranzaksiya rollback bo'lsa ham saqlanib qoladi.
- **Sahifalash va saralash bazada bajariladi.** `OFFSET ... FETCH`, jami soni `COUNT(*) OVER ()` bilan olinadi, saralashda dinamik SQL ishlatilmaydi, shuning uchun SQL injection xavfi yo'q.
- **Audit:** trigger'lar `CLIENT_IDENTIFIER` orqali ilovadagi operator nomini yozadi.

## Xato kodlari

| Kod | Ma'nosi |
|---|---|
| -20001 | Mablag' yetarli emas |
| -20002 | Qabul qiluvchi hisob topilmadi |
| -20003 | Hisobning o'zidan o'ziga o'tkazma |
| -20004 | Summa 0 dan katta bo'lishi kerak |
| -20005 | Hisob bloklangan |
| -20006 | Valyutalar mos emas |
| -20007 | Jo'natuvchi hisob topilmadi |
| -20008 | To'lov maqsadi kodi noto'g'ri |
| -20010 | PINFL/INN takrorlangan |
| -20011 | PINFL/INN formati noto'g'ri |
| -20012 | Telefon formati noto'g'ri |
| -20013 | Mijoz topilmadi |
| -20014 | Mijoz nomi juda qisqa |
| -20020 | Bloklangan mijozga hisob ochib bo'lmaydi |
| -20021 | Hisob topilmadi |
| -20022 | Holat o'zgarmagan |
| -20023 | Valyuta kodi noto'g'ri |
| -20024 | Bloklash sababi ko'rsatilmagan |
| -20030 | Bajarilgan hujjatni o'zgartirib bo'lmaydi |
| -20101 | Login yoki parol noto'g'ri |
| -20102 | Foydalanuvchi bloklangan |

## Kirish ma'lumotlari (namunaviy)

| Login | Parol | Rol |
|---|---|---|
| admin | Admin2026! | ADMIN |
| b.abdusalomov | Operator2026 | OPERATOR |
| k.saidova | Operator2026 | OPERATOR |
