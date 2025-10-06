# Django Authentication Setup Guide

## Prerequisites
Before running the Django server, install the required dependencies:

## Using pip (recommended)
```bash
# Create a virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

## Using system packages (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install python3-django python3-pip
pip install djangorestframework djangorestframework-simplejwt django-cors-headers
```

## Database Setup
After installing the dependencies:

```bash
# Create and run migrations
python manage.py makemigrations
python manage.py migrate

# Create a superuser (optional)
python manage.py createsuperuser

# Run the server
python manage.py runserver
```

## API Endpoints

### Role-Specific Registration Endpoints
- `POST /api/parents/register/` - Register a new parent (auto-sets user_type to 'parent')
- `POST /api/busminders/register/` - Register a new busminder (auto-sets user_type to 'busminder')

### General Authentication Endpoints
- `POST /api/users/register/` - Register a new user (requires user_type in body)
- `POST /api/users/login/` - Login user
- `POST /api/users/logout/` - Logout user
- `POST /api/users/token/` - Get JWT token
- `POST /api/users/token/refresh/` - Refresh JWT token

### Profile Endpoints
- `GET /api/users/profile/` - Get user profile
- `PUT /api/users/profile/` - Update user profile
- `GET /api/users/profile/detail/` - Get detailed profile
- `PUT /api/users/change-password/` - Change password

## Role-Specific Registration Examples

### Parent Registration
```json
POST /api/parents/register/
{
    "username": "john_parent",
    "email": "john@example.com",
    "password": "securePassword123",
    "password_confirm": "securePassword123",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+1234567890"
}
```

### BusMinder Registration
```json
POST /api/busminders/register/
{
    "username": "jane_minder",
    "email": "jane@example.com",
    "password": "securePassword123",
    "password_confirm": "securePassword123",
    "first_name": "Jane",
    "last_name": "Smith",
    "phone_number": "+1234567891"
}
```

### General User Registration (Legacy - requires user_type)
```json
POST /api/users/register/
{
    "username": "admin_user",
    "email": "admin@example.com",
    "password": "securePassword123",
    "password_confirm": "securePassword123",
    "first_name": "Admin",
    "last_name": "User",
    "user_type": "admin",
    "phone_number": "+1234567892"
}
```

## Login Example
```json
POST /api/users/login/
{
    "username": "john_doe",
    "password": "securePassword123"
}
```

## User Types
- `parent` - Creates a Parent profile
- `busminder` - Creates a BusMinder profile
- `admin` - Admin user (no additional profile)

## Authentication Headers
For protected endpoints, include JWT token:
```
Authorization: Bearer <access_token>
```