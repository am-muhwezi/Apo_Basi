# ApoBasi Project – GitHub Copilot Instructions

This document provides structured guidance so GitHub Copilot can generate consistent, high‑quality code across the entire ApoBasi stack.

---

## 🏗️ **Tech Stack Overview**

### **Frontend**

* Flutter (Mobile + Web)
* State management: Provider / Riverpod *(choose one and stay consistent)*
* API calls: `dio`
* Auth: JWT from Django backend
* Build output (for web): `/build/web` served by NGINX

### **Backend**

* Django + Django REST Framework
* PostgreSQL
* Redis (caching + sessions + rate limiting)
* Gunicorn application server
* NGINX reverse proxy

### **Infrastructure**

* DigitalOcean droplet (production)
* DigitalOcean App Platform (old environment)
* Docker + docker-compose (local & production use)
* Domain: `apobasi.com`, API at `api.apobasi.com`

---

# 🔥 GitHub Copilot General Rules

## **1. Follow project architecture**

Copilot must:

* Keep Flutter code in **clean architecture**: `presentation/`, `application/`, `domain/`, `infrastructure/`.
* Keep Django code clean: `apps/`, `serializers/`, `services/`, `urls/`, `views/`.
* Never mix concerns.

## **2. Generate code that integrates with the existing stack**

Examples:

* (Flutter) Use `dio` + interceptors for JWT
* (Django) Always use DRF `APIView` or `GenericViewSet`
* (DB) Use PostgreSQL-safe queries
* (Redis) Use caching decorators or custom helpers

## **3. Use best‑practice patterns**

* Add error handling in both Flutter & Django
* Return consistent API shapes
* Validate all inputs
* Document important classes and methods

---

# 🚀 Flutter – Copilot Instructions

## **API clients**

When generating API services, Copilot should:

* Use `dio`
* Include retry logic
* Include JWT token from secure storage
* Auto-refresh expired tokens

**Template Copilot should follow:**

```dart
final dio = Dio(BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  headers: {'Accept': 'application/json'},
));

dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await storage.read(key: 'jwt');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    return handler.next(options);
  },
  onError: (e, handler) async {
    // refresh token logic here
    return handler.next(e);
  },
));
```

## **State Management**

Copilot must:

* Use Provider or Riverpod consistently
* Implement ChangeNotifier or StateNotifier

## **UI Rules**

Copilot must:

* Generate responsive layouts
* Avoid business logic in widgets
* Use theming, avoid inline styles

---

# 🔥 Django/DRF – Copilot Instructions

## **Structure**

Always place code in these folders:

```
apps/
  users/
    models.py
    serializers.py
    views.py
    services/
    urls.py
```

## **Views**

Copilot should ONLY use:

* `APIView`
* `GenericViewSet`
* `ModelViewSet`

NO function-based views unless necessary.

## **Serializers**

Rules:

* Validate all inputs
* Use `SerializerMethodField` where needed
* No nested serializers unless required

## **Auth**

Copilot must:

* Implement JWT with refresh tokens
* Store tokens securely on the client
* Use DRF authentication classes

## **Redis Usage**

Copilot should:

* Use Redis for caching expensive queries
* Use keys like: `apobasi:users:<id>`
* Implement TTLs

---

# 🌐 NGINX + Deployment Instructions

## **Reverse Proxy Template**

Copilot should ALWAYS generate configs based on this pattern:

```
server {
    server_name api.apobasi.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## For Flutter Web:

```
server {
    server_name apobasi.com;

    root /var/www/apobasi/build/web;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
    }
}
```

---

# 🧪 Tests

Copilot must generate:

* Django unit tests using `pytest`
* Flutter widget tests + integration tests

---

# 📦 Docker + Compose Rules

Copilot should align with this structure:

```
backend/
  Dockerfile
frontend/
  Dockerfile
nginx/
  nginx.conf
```

Compose services:

* backend
* frontend
* nginx
* postgres
* redis

---

# ✔️ Summary – Copilot Behavior Checklist

Copilot must:

* Follow clean architecture in Flutter
* Follow Django best practices
* Use consistent API patterns
* Always include JWT logic
* Use dio + interceptors
* Use DRF viewsets
* Use Redis properly
* Generate production‑ready configs
* Use docker-compose patterns

---

If you want, I can add:
✅ more templates
✅ commit message rules
✅ PR standards


