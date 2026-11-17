# نظام تسجيل زوار المدرسة

تطبيق عربي RTL بواجهتين:
- `/` تسجيل الزائر دون حساب، مع وقت وصول تلقائي من قاعدة البيانات.
- `/admin` لوحة خاصة عبر Supabase Auth، مع البحث والتصفية وإحصاءات اليوم وتصدير CSV.

## إعداد Supabase
1. أنشئ مشروعاً جديداً في Supabase.
2. افتح SQL Editor وشغّل كامل الملف `supabase/schema.sql`.
3. من Project Settings → API انسخ Project URL والمفتاح العام anon/publishable.
4. من Authentication → Users أنشئ مستخدم الإدارة بالبريد وكلمة مرور قوية.
5. أضف المستخدم إلى قائمة المسؤولين بتشغيل SQL التالي بعد استبدال البريد:

```sql
insert into public.admin_users(user_id)
select id from auth.users where email = 'admin@school.example';
```

## التشغيل
يتطلب Node.js 18 أو أحدث:

```bash
npm install
cp .env.example .env
```

أدخل بيانات المشروع في `.env`:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY
```

ثم شغّل `npm run dev`. افتح `/admin` لدخول الإدارة.

## النشر
اربط المستودع بخدمة استضافة مثل Vercel أو Netlify. أمر البناء `npm run build` ومجلد النشر `dist`. أضف متغيري البيئة السابقين في إعدادات الاستضافة.

## الأمان
- الزائر يستطيع الإضافة فقط ولا يستطيع قراءة السجلات.
- قراءة السجلات محصورة بحسابات Auth المدرجة يدوياً في `admin_users` عبر RLS.
- لا تضع مفتاح `service_role` في المتصفح أو GitHub.
- يحفظ Supabase الوقت في `timestamptz` ويعرض الموقع التوقيت وفق `Asia/Bahrain`.
- تعرض لوحة الإدارة أحدث 2000 سجل كحد أقصى في الإصدار الحالي.
