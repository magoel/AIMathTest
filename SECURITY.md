# Security Policy

## Security Review Summary

This document outlines the security review conducted on the AIMathTest repository and the improvements implemented.

## Security Improvements Implemented

### 1. Input Validation (Cloud Functions)

**Issue**: The `generateTest` Cloud Function lacked comprehensive input validation, which could lead to:
- Resource exhaustion attacks (unlimited question count)
- Invalid data injection
- Unexpected behavior from malformed inputs

**Fix**: Added comprehensive input validation in `functions/src/generateTest.ts`:
- Validated `profileId` is a non-empty string
- Validated `grade` is between 0-12
- Validated `difficulty` is between 1-10
- Validated `questionCount` is between 1-50 (prevents resource exhaustion)
- Validated `topics` array contains only valid topic strings from allowed list
- Limited maximum topics to 10
- Validated `timed` is a boolean

### 2. Enhanced Firestore Security Rules

**Issue**: Firestore rules lacked data validation on write operations, allowing malformed data to be stored.

**Fix**: Enhanced `firestore.rules` with:
- Helper functions for string and number validation
- Required field validation for all collections
- String length limits (email: 100, displayName: 100, name: 50)
- Number range validation (grade: 0-12, score: 0-10000, percentage: 0-100)
- Question count limits (1-50)
- Ensured `parentId` matches authenticated user on profile creation
- Split read/write rules for better granularity

### 3. Security Headers

**Issue**: Missing HTTP security headers exposed the application to various attacks:
- Clickjacking (missing X-Frame-Options)
- MIME type sniffing attacks (missing X-Content-Type-Options)
- XSS attacks (missing Content Security Policy)

**Fix**: Added comprehensive security headers in `firebase.json`:
- **X-Content-Type-Options**: `nosniff` - Prevents MIME type sniffing
- **X-Frame-Options**: `DENY` - Prevents clickjacking attacks
- **X-XSS-Protection**: `1; mode=block` - Enables XSS filtering
- **Referrer-Policy**: `strict-origin-when-cross-origin` - Controls referrer information
- **Permissions-Policy**: Restricts access to browser features (geolocation, microphone, camera, payment)
- **Content-Security-Policy**: Comprehensive CSP that:
  - Restricts script sources to self, Google APIs, and inline scripts (required for Flutter)
  - Restricts style sources to self, inline styles, and Google Fonts
  - Restricts frame sources to Google accounts and Firebase
  - Blocks object embeds
  - Restricts base URI to self

### 4. Cloud Function Resource Limits

**Issue**: No resource limits on Cloud Functions could lead to cost overruns or DoS attacks.

**Fix**: Added resource constraints to `generateTest` function:
- `maxInstances: 10` - Limits concurrent executions
- `memory: "512MiB"` - Restricts memory usage
- `timeoutSeconds: 60` - Prevents long-running requests
- Added `enforceAppCheck: false` with comment to enable when configured

### 5. Web Security Enhancements

**Issue**: Missing viewport meta tag could affect mobile security and usability.

**Fix**: Added viewport meta tag in `web/index.html`:
- Proper viewport configuration with reasonable zoom limits
- Enables user scaling for accessibility

## Security Best Practices Already in Place

1. **Authentication**: 
   - Firebase Authentication with Google Sign-In
   - All API endpoints require authentication
   - User context properly validated

2. **Secrets Management**:
   - Gemini API key stored in Firebase Secret Manager
   - No hardcoded secrets in code
   - Firebase API keys properly configured (public keys are safe for client-side use)

3. **Authorization**:
   - Proper user isolation in Firestore rules
   - Users can only access their own data
   - Tests require authentication to access
   - Profile management restricted to parent users

4. **Data Sanitization**:
   - Topics validated against whitelist (prevents prompt injection)
   - User inputs properly validated before AI prompt construction

5. **HTTPS Enforcement**:
   - All Firebase services use HTTPS by default
   - No insecure HTTP endpoints found

6. **Dependency Management**:
   - TypeScript strict mode enabled
   - Modern dependency versions
   - Firebase Admin SDK for secure backend operations

## Recommendations for Future Improvements

### High Priority

1. **Enable Firebase App Check**: Protects backend resources from abuse
   - Update `enforceAppCheck: true` in Cloud Functions
   - Configure App Check in Firebase Console
   - Add App Check SDK to Flutter app

2. **Implement Rate Limiting**: Use Firebase App Check or Firestore rules to limit requests per user
   - Consider implementing per-user rate limits in Firestore
   - Add exponential backoff on client side

3. **Add Security Monitoring**: 
   - Enable Firebase Security Rules monitoring
   - Set up alerts for unusual activity patterns
   - Monitor Cloud Function invocation rates

### Medium Priority

4. **Content Security Policy Refinement**:
   - Current CSP includes `unsafe-inline` and `unsafe-eval` in `script-src` which are required for Flutter web
   - These directives weaken XSS protection but are necessary for Flutter's current architecture
   - **Mitigation**: All other CSP directives are strict, and input validation prevents XSS at the source
   - **Future**: Monitor Flutter team's progress on CSP compatibility (tracked in Flutter issue #33009)
   - Consider implementing nonces for inline scripts once Flutter supports them
   - Document migration plan to remove unsafe directives when Flutter allows

5. **Implement Test Expiry Validation**:
   - Add Firestore rule to prevent access to expired tests
   - Client-side validation already exists, add server-side enforcement

6. **Add Request Signing**:
   - Consider implementing request signing for Cloud Functions
   - Validates requests come from legitimate app instances

### Low Priority

7. **Security Audit Logging**:
   - Log security-relevant events (failed auth, invalid requests)
   - Set up log analysis for security patterns

8. **Penetration Testing**:
   - Conduct regular security assessments
   - Test authentication flows
   - Verify Firestore rules effectiveness

## Reporting Security Issues

If you discover a security vulnerability, please follow responsible disclosure:

1. **DO NOT** open a public GitHub issue
2. Email the maintainer directly with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
3. Allow reasonable time for the issue to be addressed before public disclosure

## Security Update Policy

- Security patches will be released as soon as possible after discovery
- Critical vulnerabilities will be addressed within 48 hours
- Security updates will be documented in release notes
- Users will be notified of critical security updates

## Compliance

This application:
- Follows OWASP Top 10 security guidelines
- Implements Firebase security best practices
- Uses secure authentication mechanisms
- Protects user privacy and data
- Complies with data protection principles

## Testing

Security tests should be run before each release:
1. Run `flutter analyze` for Dart/Flutter code
2. Run TypeScript linter for Cloud Functions
3. Test Firestore rules with Firebase emulator
4. Verify CSP headers in production
5. Check for dependency vulnerabilities

## Last Updated

2026-02-15 - Initial security review and hardening
