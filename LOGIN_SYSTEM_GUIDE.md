# Ruby-HTML Website Manager - Login System Guide

## Overview
A complete welcome/login/registration system has been added to the Ruby-HTML Website Manager. Users must now authenticate before accessing the main DSL application.

## New Flow

### 1. **Startup**
When you run `ruby test_web_dsl.rb`, you'll be prompted to enter your role:
```
Enter your role (admin/user/editor):
```

**Options:**
- **editor**: Enters the console-based editor mode for modifying templates and functions
- **admin**: Starts the web server and you can log in as an admin
- **user**: Starts the web server and you can log in as a user

### 2. **Welcome Page** (`/welcome`)
When users first access the web application at `http://localhost:4567`, they arrive at a beautiful welcome page with two options:
- **Existing User - Login**: Direct to the login page
- **New User - Register**: Direct to the registration page

### 3. **Login Page** (`/login`)
- Enter your email address
- The system checks against the registered users in `users.json`
- **If found**: User is authenticated and redirected to the main application
- **If not found**: User is shown a helpful message with options to create a new account or try another email

### 4. **Registration Page** (`/register`)
- Enter your full name
- Enter your email address
- New users are registered with a **"user" role** by default
- After registration, users are automatically logged in and redirected to the main app

### 5. **Main Application**
After successful login, users see:
- A personalized header showing their name, email, and role
- A **Logout** button in the top-right corner
- For **admin users**: An additional "Admin Controls" tab with user management, session management, and server controls
- All existing features of the DSL application

### 6. **Logout** (`/logout`)
Users can click the "Logout" button to end their session and return to the welcome page.

## Key Features

### ✅ Authentication
- Email-based login system
- Session management with secure cookies
- Automatic role assignment based on user data

### ✅ User Registration
- Simple 2-field registration (Name & Email)
- Duplicate email prevention
- Automatic login after registration
- Users assigned "user" role by default

### ✅ Role-Based Access Control
- **Admin**: Full access to user management, session control, and server administration
- **User**: Access to the main application features
- **Editor**: Console-based editing mode (terminal access, not web-based)

### ✅ Session Management
- User information persists during session
- Session ID stored in browser cookies
- Logout clears authentication data
- Activity logging for login/registration/logout events

### ✅ Beautiful UI
- Modern gradient design (purple/blue)
- Responsive layout
- User-friendly error messages
- Clear call-to-action buttons

## Routes

### Public Routes (No Authentication Required)
- `GET /welcome` - Welcome/landing page
- `GET /login` - Login form
- `GET /register` - Registration form
- `POST /authenticate_user` - Handle login
- `POST /register_user` - Handle registration

### Protected Routes (Authentication Required)
- `GET /` - Main application (redirects to /welcome if not authenticated)
- `GET /logout` - Logout
- All existing routes (User Data, Project Info, Webapp Builder, etc.)

## User Data Files

### users.json
Stores registered user information:
```json
[
  {
    "name": "Alice",
    "email": "alice@example.com",
    "role": "editor",
    "submitted_at": "2025-04-09T10:00:00Z"
  },
  {
    "name": "Bob",
    "email": "bob@example.com",
    "role": "user",
    "submitted_at": "2025-04-09T10:05:00Z"
  }
]
```

### Session Management
- Session cookies are automatically created when users log in
- Session data is stored in the server's session store
- Each session is tracked with creation time and status

### Changelog
- All login, registration, and logout events are logged to `changelog.json`
- Admins can view the complete audit trail in the Admin Controls

## Testing the System

### Test as New User
1. Run `ruby test_web_dsl.rb` and select any role (user/admin)
2. Navigate to `http://localhost:4567`
3. You'll see the welcome page
4. Click "New User - Register"
5. Enter a name and email (not in users.json yet)
6. You'll be registered and logged in automatically
7. Explore the main application

### Test as Existing User
1. Run `ruby test_web_dsl.rb` and select any role
2. Navigate to `http://localhost:4567`
3. Click "Existing User - Login"
4. Enter an email from `users.json` (e.g., "alice@example.com")
5. You'll be logged in with the role from users.json
6. If admin, access Admin Controls tab

### Test as Editor
1. Run `ruby test_web_dsl.rb`
2. Enter "editor" when prompted
3. You'll enter the editor console (not the web interface)
4. Use the console menu to modify templates and functions

## Authentication Flow Diagram

```
┌─────────────────────────────┐
│ User Accesses Application   │
│ http://localhost:4567       │
└──────────────┬──────────────┘
               │
               ▼
        ┌─────────────┐
        │ /welcome    │
        │ Welcome Page│
        └──────┬──────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
    /login          /register
    (Login)         (Register)
       │                │
       ├────────┬───────┤
       │        │       │
  ┌────▼──┐  ┌──▼──┐  ┌▼────┐
  │Validate│ │Valid│ │New  │
  │Email   │ │Email│ │Email?│
  └─┬──────┘ └──┬──┘ └┬────┘
    │           │     │
 NO │           YES   │
    │           │     NO
    │           │     │
    ▼           ▼     ▼
  Error      Auth  Error
  Page       Success  Page
    │           │     │
    └────┬──────┘     │
         │            │
         │      ┌─────┴──┐
         │      │Register│
         │      │Success │
         │      └───┬────┘
         │          │
         └──────┬───┘
                │
                ▼
        ┌──────────────────┐
        │ Main Application │
        │ (Protected Route)│
        │ "/" - Form etc   │
        └──────────────────┘
```

## Backend Implementation Details

### Modified Files
- `test_web_dsl.rb` - Added templates and routes for login system

### New Routes Added
- `route "/welcome"` - Welcome page
- `route "/login"` - Login form
- `route "/register"` - Registration form
- `route "/authenticate_user"` - Login handler
- `route "/register_user"` - Registration handler
- `route "/logout"` - Logout handler
- Modified `route "/"` - Added authentication check and user info

### Session Variables
- `sess["authenticated"]` - Boolean flag for auth state
- `sess["user_email"]` - User's email
- `sess["user_name"]` - User's name
- `sess["user_role"]` - User's role (admin, user, editor)

### Templates Added
1. `:welcome_login` - Beautiful welcome landing page
2. `:login_page` - Email-based login form
3. `:register_page` - New user registration form

## Security Considerations

### Current Implementation
- Email-based authentication (simple, no passwords)
- Session-based (cookies)
- Role-based access control for admin features

### Recommendations for Production
- Add password authentication
- Implement HTTPS/SSL
- Add rate limiting for login attempts
- Implement email verification
- Add stronger session security
- Implement CSRF protection
- Add IP-based access controls for admin panel

## Troubleshooting

### Issue: "Email is not registered" but user exists
- Make sure the email in `users.json` matches exactly (case-insensitive, but check for spaces)
- Clear browser cookies and try again

### Issue: Can't access admin panel
- Make sure your user has `"role": "admin"` in `users.json`
- Logout and log back in to refresh role

### Issue: New user wasn't created
- Check `users.json` was updated
- Check `changelog.json` for registration events
- Clear browser cache if redirect seems broken

### Issue: Session keeps logging out
- Check browser's cookie settings (not blocking session cookies)
- Try a different browser
- Clear cookies and cache

## Future Enhancements

Suggested improvements:
- [ ] Password authentication
- [ ] Email verification
- [ ] "Remember Me" functionality
- [ ] OAuth/SSO integration
- [ ] Two-factor authentication
- [ ] User profile editing
- [ ] Password reset flow
- [ ] User deactivation
- [ ] Session timeout
- [ ] Activity audit log viewing

---

**Enjoy your new login system! 🎉**
