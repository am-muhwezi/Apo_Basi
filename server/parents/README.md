# Parents API Documentation

## Overview

The Parents API has been refactored to use a clean, simple **APIView** approach instead of ModelViewSet. This provides only the essential operations that parents need: **Login** and **View Children**.

### Why APIView over ModelViewSet?

- ✅ **Simpler** - Only exposes endpoints you need
- ✅ **More Secure** - No accidental CRUD operations exposure
- ✅ **Easier to maintain** - Clear, explicit code
- ✅ **Better for juniors** - Easier to understand and debug

## API Endpoints

### Base URL: `/api/parents/`

---

### 1. **Parent Login** (Phone Number Only)

**Endpoint:** `POST /api/parents/login/`

**Permission:** `AllowAny` (Public)

**Description:** Parents login using their phone number. Only active parents can login.

#### Request Body:
```json
{
  "phone_number": "1234567890"
}
```

#### Success Response (200 OK):
```json
{
  "message": "Login successful",
  "tokens": {
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  },
  "parent": {
    "id": 5,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@parent.com",
    "phone": "1234567890"
  },
  "children": [
    {
      "id": 12,
      "first_name": "Jane",
      "last_name": "Doe",
      "class_grade": "Grade 5",
      "assigned_bus": {
        "id": 3,
        "number_plate": "ABC-123"
      }
    }
  ]
}
```

#### Error Response (404 Not Found):
```json
{
  "error": "No active parent account found with this phone number"
}
```

#### Error Response (400 Bad Request):
```json
{
  "phone_number": [
    "Phone number is required"
  ]
}
```

---

### 2. **Get My Children**

**Endpoint:** `GET /api/parents/my-children/`

**Permission:** `IsAuthenticated, IsParent`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Description:** Returns all children assigned to the authenticated parent with today's attendance status.

#### Success Response (200 OK):
```json
{
  "children": [
    {
      "id": 12,
      "first_name": "Jane",
      "last_name": "Doe",
      "class_grade": "Grade 5",
      "age": 10,
      "status": "active",
      "assigned_bus": {
        "id": 3,
        "number_plate": "ABC-123"
      },
      "today_attendance": {
        "status": "Present",
        "time": "2024-11-07T08:30:00Z"
      }
    },
    {
      "id": 13,
      "first_name": "Jack",
      "last_name": "Doe",
      "class_grade": "Grade 3",
      "age": 8,
      "status": "active",
      "assigned_bus": {
        "id": 3,
        "number_plate": "ABC-123"
      },
      "today_attendance": {
        "status": "No record today",
        "time": null
      }
    }
  ],
  "count": 2
}
```

#### Error Response (404 Not Found):
```json
{
  "error": "Parent profile not found"
}
```

---

### 3. **Get Child Attendance History**

**Endpoint:** `GET /api/parents/children/<child_id>/attendance/`

**Permission:** `IsAuthenticated, IsParent`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Description:** Returns complete attendance history for a specific child. Parents can only view their own children's attendance.

#### Success Response (200 OK):
```json
{
  "child": {
    "id": 12,
    "name": "Jane Doe",
    "class_grade": "Grade 5"
  },
  "attendance_history": [
    {
      "id": 45,
      "date": "2024-11-07",
      "status": "Present",
      "bus": {
        "id": 3,
        "number_plate": "ABC-123"
      },
      "marked_by": "John Driver",
      "timestamp": "2024-11-07T08:30:00Z",
      "notes": "On time"
    },
    {
      "id": 44,
      "date": "2024-11-06",
      "status": "Absent",
      "bus": null,
      "marked_by": "Jane Minder",
      "timestamp": "2024-11-06T08:35:00Z",
      "notes": "Sick leave"
    }
  ],
  "total_records": 2
}
```

#### Error Response (403 Forbidden):
```json
{
  "error": "You can only view attendance for your own children"
}
```

#### Error Response (404 Not Found):
```json
{
  "detail": "Not found."
}
```

---

## Security Features

1. **Phone-only login** - No password needed, school manages parent accounts
2. **Active status check** - Only active parents can login
3. **JWT Authentication** - Secure token-based authentication
4. **Permission checks** - `IsParent` ensures only parents access their data
5. **Ownership verification** - Parents can only view their own children's data
6. **No open registration** - School creates parent accounts via admin

---

## Code Structure

```
parents/
├── models.py              # Parent model (unchanged)
├── serializers.py         # ParentLoginSerializer (simplified)
├── views.py              # 3 APIView classes (refactored)
├── urls.py               # Clean URL routing (refactored)
└── README.md             # This file
```

### Views (parents/views.py):
- `ParentLoginView` - Handles phone-based authentication
- `ParentChildrenView` - Returns parent's children with today's attendance
- `ChildAttendanceHistoryView` - Returns attendance history for a child

### Serializers (parents/serializers.py):
- `ParentLoginSerializer` - Validates phone number for login
- `ParentSerializer` - For admin operations (kept for compatibility)

---

## Testing the API

### Using cURL:

#### 1. Login:
```bash
curl -X POST http://localhost:8000/api/parents/login/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "1234567890"}'
```

#### 2. Get My Children:
```bash
curl -X GET http://localhost:8000/api/parents/my-children/ \
  -H "Authorization: Bearer <access_token>"
```

#### 3. Get Child Attendance:
```bash
curl -X GET http://localhost:8000/api/parents/children/12/attendance/ \
  -H "Authorization: Bearer <access_token>"
```

---

## Frontend Integration

### Login Example (React/JavaScript):
```javascript
const login = async (phoneNumber) => {
  const response = await fetch('http://localhost:8000/api/parents/login/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ phone_number: phoneNumber })
  });

  const data = await response.json();

  if (response.ok) {
    // Store tokens
    localStorage.setItem('access_token', data.tokens.access);
    localStorage.setItem('refresh_token', data.tokens.refresh);

    // Store parent and children data
    localStorage.setItem('parent', JSON.stringify(data.parent));
    localStorage.setItem('children', JSON.stringify(data.children));

    return data;
  } else {
    throw new Error(data.error);
  }
};
```

### Get Children Example:
```javascript
const getMyChildren = async () => {
  const token = localStorage.getItem('access_token');

  const response = await fetch('http://localhost:8000/api/parents/my-children/', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });

  return await response.json();
};
```

---

## Database Optimization

The views use optimized queries:

- `select_related('user')` - Reduces database queries for User data
- `select_related('assigned_bus')` - Preloads bus information
- `prefetch_related('attendance_set')` - Efficiently loads attendance data

---

## What Was Removed?

✅ Removed endpoints (not needed for parents):
- `POST /api/parents/` - Create parent (admin only now)
- `GET /api/parents/` - List all parents (admin only now)
- `GET /api/parents/{pk}/` - Get specific parent (admin only now)
- `PUT/PATCH /api/parents/{pk}/` - Update parent (admin only now)
- `DELETE /api/parents/{pk}/` - Delete parent (admin only now)
- `POST /api/parents/login/` - Username/password login (removed)
- `POST /api/parents/register/` - Public registration (removed)
- `POST /api/parents/{pk}/assign-children/` - Assign children (admin only now)

---

## Next Steps / Future Enhancements

1. **Add OTP Verification** - Send SMS code for secure login
2. **Rate Limiting** - Prevent brute force login attempts
3. **Phone Number Validation** - Add regex pattern for your region
4. **Database Index** - Add index on `Parent.contact_number`
5. **Logging** - Track login attempts for security audit

---

## Troubleshooting

### Error: "No active parent account found"
- Check if parent exists in database
- Verify parent status is 'active'
- Confirm phone number matches exactly

### Error: "Parent profile not found"
- User is not associated with a parent profile
- Check user type is 'parent'

### Error: "Authentication credentials were not provided"
- Missing Authorization header
- Token expired (use refresh token to get new access token)

---

## Support

For questions or issues, contact the backend development team.
