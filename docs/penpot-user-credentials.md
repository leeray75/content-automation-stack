# Penpot User Credentials

## Overview
This document contains login credentials for Penpot accounts created during testing and development.

**⚠️ SECURITY WARNING**: This file contains sensitive credentials. Do not commit to version control or share publicly.

## Penpot Access Information

**Service URL**: http://localhost:9001

### Test User Account
**Created**: September 24, 2025 at 3:52 AM EST  
**Purpose**: Testing email verification disabled configuration

**Login Credentials:**
- **Email**: `hoyenlee@gmail.com`
- **Password**: `TestPass123!`
- **Full Name**: Hoyen Lee
- **Status**: ✅ Active (No email verification required)

### Pre-existing Admin Account
**Login Credentials:**
- **Email**: `admin@example.com`
- **Password**: *(Unknown - created during initial setup)*
- **Full Name**: Administrator
- **Status**: ✅ Active

## Configuration Notes

### Email Verification Status
- ✅ **DISABLED** - Users can register and login immediately without email verification
- Configuration flags active:
  - `disable-email-verification`
  - `enable-insecure-register`
  - `enable-registration`
  - `enable-login-with-password`

### Registration Process
1. Visit http://localhost:9001
2. Click "Create an account"
3. Fill in required fields (Full Name, Work Email, Password)
4. Click "CREATE AN ACCOUNT"
5. **No email verification required** - immediate access granted

## Database Information

**Total Registered Users**: 2
1. `admin@example.com` (Administrator) - Pre-existing
2. `hoyenlee@gmail.com` (Hoyen Lee) - Test account

## Security Considerations

**Current Configuration:**
- ⚠️ Email verification is disabled
- ⚠️ SMTP is disabled
- ⚠️ Insecure registration is enabled

**Recommended for:**
- ✅ Local development
- ✅ Testing environments
- ✅ Internal team usage

**NOT recommended for:**
- ❌ Production environments
- ❌ Public-facing instances
- ❌ Environments with sensitive data

## Troubleshooting

### If login fails:
1. Verify containers are running: `docker compose --profile penpot ps`
2. Check container logs: `docker compose --profile penpot logs penpot-backend`
3. Confirm environment variables: `docker exec penpot-backend env | grep PENPOT_FLAGS`

### To reset password:
Since email verification is disabled, password reset may not work properly. Consider:
1. Creating a new account
2. Using database direct access to reset password
3. Re-enabling email functionality temporarily

---

**Last Updated**: September 24, 2025  
**Updated By**: Cline AI Assistant  
**Configuration Version**: Penpot 2.9.0 with email verification disabled
