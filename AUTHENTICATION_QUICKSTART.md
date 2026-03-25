# Welcome/Login System - Quick Start

## What Was Added

A complete user authentication system has been integrated into the Ruby-HTML Website Manager. The system includes:

✅ **Welcome Page** - Beautiful landing page with login/register options
✅ **Login System** - Email-based authentication for existing users
✅ **Registration** - Easy sign-up for new users
✅ **Session Management** - Persistent user sessions with role-based access
✅ **User Profile Display** - Shows logged-in user info on main page
✅ **Logout Function** - Secure logout with session cleanup
✅ **Admin Controls** - Dashboard visible only to admin users
✅ **Audit Logging** - All login/logout events logged to changelog

## How to Use

### 1. Start the Application
```bash
ruby test_web_dsl.rb
```

When prompted, enter your role:
- **editor** - For console-based template editing
- **admin** - To access web app with admin privileges
- **user** - To access web app as a regular user

### 2. Access the Web Application
Navigate to `http://localhost:4567` in your browser

### First-Time Users
1. You'll see the Welcome page
2. Choose "New User - Register"
3. Enter your name and email
4. You're automatically logged in!

### Existing Users
1. You'll see the Welcome page
2. Choose "Existing User - Login"
3. Enter your email (from users.json)
4. Access the application

### Available Test Users (from users.json)
- Alice (alice@example.com) - Role: editor
- Bob (bob@example.com) - Role: user  
- Michael (mike@example.com) - Role: admin
- Carol (carol@example.com) - Role: user

### Admin Features
If logged in as admin:
- Access "Admin Controls" tab
- Manage users (add, edit, delete)
- View and close sessions
- Shutdown the server
- View activity changelog

## Key Pages

- **`/welcome`** - Landing page (public)
- **`/login`** - Email login form (public)
- **`/register`** - New user registration (public)
- **`/`** - Main app dashboard (requires login)
- **`/logout`** - Logout and return to welcome page

## File Structure

```
DSL/
├── web_dsl.rb              # Core framework (unchanged)
├── test_web_dsl.rb         # Main app with login system (UPDATED)
├── users.json              # User database
├── changelog.json          # Activity log
├── submitted_data.json     # Form submissions
└── user_data.json          # User preferences
```

## Session Flow

```
Welcome Page → Login/Register → Authenticate → Main App
                                                    ↓
                                               (Admin only) Admin Panel
                                                    ↓
                                                 Logout → Welcome Page
```

## Authentication Details

- Uses **email-based authentication** (no password currently)
- Stores user data in `users.json`
- Session managed via browser cookies
- Role stored in session: "admin", "user", or "editor"
- Activity tracked in `changelog.json`

## Testing the Login System

### Quick Test
1. Run: `ruby test_web_dsl.rb`
2. Enter: `user` (or `admin`, `editor`)
3. Visit: `http://localhost:4567`
4. Try: Login with "alice@example.com" or register with new email
5. Click: "Logout" button to test logout

### Test Registration
1. On welcome page, click "New User - Register"
2. Enter a new name and email (not alice, bob, michael, or carol)
3. Account created and automatically logged in
4. New entry added to `users.json`

### Test Admin Features
1. Login as "michael@example.com" (admin user)
2. Visit the main page - you'll see "Admin Controls" tab
3. Explore user management and session features

## Security Notes

⚠️ **Current Implementation**
- Email-only authentication (no passwords)
- For demonstration and testing purposes
- Not recommended for production use without enhancements

🔐 **Recommended for Production**
- Add password authentication
- Implement HTTPS/SSL
- Add email verification
- Implement session timeout
- Add rate limiting
- Store passwords securely (hashed)

## Troubleshooting

**Q: "User not found" when trying to login**
A: Make sure the email exactly matches what's in `users.json`. Create a new account with your email.

**Q: Admin controls not showing**
A: Your logged-in user must have `"role": "admin"` in `users.json`. Login as Michael to test.

**Q: Can't logout**
A: Click the "Logout" button in the top-right corner of the main page (after login).

**Q: Want to change a user's role**
A: As an admin, use the "Admin Controls" tab to edit user roles, or manually edit `users.json` and restart.

## Documentation

For detailed documentation, see [LOGIN_SYSTEM_GUIDE.md](LOGIN_SYSTEM_GUIDE.md)

---

**Your Ruby-HTML DSL now has professional authentication! 🔐✨**
