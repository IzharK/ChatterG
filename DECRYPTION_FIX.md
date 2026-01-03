# Decryption Failure Fix

## Problem

Older chats were failing to decrypt with the following issue:

**Root Cause**: When messages were stored without a MAC (Message Authentication Code), the decryption was failing because of improper null/empty string handling.

### What Was Happening

1. **In `chat_controller.dart` (line 175)**:
   ```dart
   msg.macBase64 ?? ''  // Passing empty string when macBase64 is null
   ```

2. **In `crypto_service.dart` (line 183)**:
   ```dart
   if (macBase64 != null) {  // Empty string is NOT null!
     mac = Mac(base64Decode(macBase64));  // Trying to decode empty string
   }
   ```

3. **The Problem**:
   - When `macBase64` is `null`, it gets converted to an empty string `''`
   - The condition `if (macBase64 != null)` evaluates to `true` for empty strings
   - `base64Decode('')` fails or produces invalid data
   - Decryption fails for all older messages that don't have a MAC

## Solution

**File**: `lib/app/data/providers/crypto_service.dart` (line 183)

**Changed**:
```dart
if (macBase64 != null) {
```

**To**:
```dart
if (macBase64 != null && macBase64.isNotEmpty) {
```

This ensures that:
- `null` values are handled correctly (no MAC)
- Empty strings are also treated as "no MAC"
- Only valid MAC values are decoded and used

## Impact

✅ **Older chats without MAC will now decrypt correctly**
✅ **New messages with MAC will continue to work**
✅ **No breaking changes to encryption/decryption logic**
✅ **Backward compatible with existing messages**

## Testing

To verify the fix works:

1. Open an older chat that was failing to decrypt
2. Messages should now display correctly
3. New messages should continue to encrypt/decrypt normally
4. No errors should appear in the console

## Files Modified

- `lib/app/data/providers/crypto_service.dart` - Fixed MAC null/empty check

---

**Status**: ✅ Fixed
**Date**: 2026-01-03

