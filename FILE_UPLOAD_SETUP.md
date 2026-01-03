# File Upload Setup Guide

This document provides detailed instructions for enabling file upload functionality in ChatterG. Currently, all file upload code is commented out to avoid requiring external storage services. Follow the steps below to add file upload support using either **Supabase** or **Firebase Storage**.

## Table of Contents
1. [Option 1: Supabase (Recommended)](#option-1-supabase-recommended)
2. [Option 2: Firebase Storage](#option-2-firebase-storage)
3. [Troubleshooting](#troubleshooting)

---

## Option 1: Supabase (Recommended)

Supabase is recommended because it has a generous free tier and is already partially integrated in the codebase.

### Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Fill in project details:
   - **Name**: Choose any name (e.g., "chatter-jee")
   - **Database Password**: Create a strong password
   - **Region**: Select closest to your users
4. Click "Create new project" and wait for initialization

### Step 2: Get Your Credentials

1. In Supabase dashboard, go to **Settings** → **API**
2. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key under "Project API keys"

### Step 3: Create Storage Bucket

1. In Supabase dashboard, go to **Storage**
2. Click "Create a new bucket"
3. Name it: `chat-attachments`
4. Make it **Public** (for easier access)
5. Click "Create bucket"

### Step 4: Set Up RLS Policies

1. Click on `chat-attachments` bucket
2. Go to **Policies** tab
3. Click "New Policy" and select "For full customization"
4. Create policy for uploads:
   ```sql
   CREATE POLICY "Allow authenticated users to upload"
   ON storage.objects
   FOR INSERT
   WITH CHECK (
     bucket_id = 'chat-attachments' AND
     auth.role() = 'authenticated'
   );
   ```
5. Create policy for downloads:
   ```sql
   CREATE POLICY "Allow public read access"
   ON storage.objects
   FOR SELECT
   USING (bucket_id = 'chat-attachments');
   ```

### Step 5: Update main.dart

Uncomment the Supabase initialization in `lib/main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Uncomment and add your credentials
  await Supabase.initialize(
    url: 'https://your-project-id.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  InitialBinding().dependencies();
  runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => MyApp()));
}
```

### Step 6: Enable Storage Services

1. **In `lib/app/bindings/initial_binding.dart`:**
   - Uncomment: `import 'package:chatter_jee/app/data/providers/storage_service.dart';`
   - Uncomment: `Get.put(StorageService(), permanent: true);`

2. **In `lib/app/controllers/chat_controller.dart`:**
   - Uncomment all imports (dart:io, file_picker, image_picker, path)
   - Uncomment StorageService and ImagePicker initialization
   - Uncomment all attachment-related properties and methods
   - Uncomment attachment handling in sendMessage()
   - Uncomment helper method `_extractStoragePathFromUrl()`

3. **In `lib/app/ui/screens/chat/chat_screen.dart`:**
   - Uncomment attachment UI in `_buildMessageInput()`
   - Uncomment `AttachmentSheet` class

### Step 7: Test

1. Run the app: `flutter run`
2. Create a chat and try uploading an image or file
3. Verify files appear in Supabase Storage dashboard

---

## Option 2: Firebase Storage

Firebase Storage requires a credit card but has a generous free tier.

### Step 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your ChatterG project
3. Go to **Storage** in left sidebar
4. Click "Get Started"
5. Choose location (closest to users)
6. Accept default security rules for now

### Step 2: Update Security Rules

In Firebase Storage Rules editor, replace with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chats/{chatId}/attachments/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid != null;
      allow delete: if request.auth != null;
    }
  }
}
```

### Step 3: Update Code for Firebase

You'll need to modify the storage service to use Firebase instead of Supabase:

1. **Remove Supabase initialization** from `main.dart`
2. **Update `storage_service.dart`** to use Firebase Storage:
   ```dart
   import 'package:firebase_storage/firebase_storage.dart';
   
   class StorageService extends GetxService {
     final _storage = FirebaseStorage.instance;
     
     Future<Map<String, dynamic>?> uploadAttachment(...) async {
       // Use Firebase Storage API instead
     }
   }
   ```
3. Follow the same uncomment steps as Supabase (Step 6 above)

---

## Removing Supabase (If Switching to Firebase)

If you initially set up Supabase but want to switch to Firebase:

1. **In `main.dart`:**
   - Comment out: `import 'package:supabase_flutter/supabase_flutter.dart';`
   - Comment out: `await Supabase.initialize(...);`

2. **In `pubspec.yaml`:**
   - Remove or comment out: `supabase_flutter: ^2.12.0`
   - Run: `flutter pub get`

3. **In `storage_service.dart`:**
   - Remove Supabase imports
   - Rewrite methods to use Firebase Storage

---

## Troubleshooting

### "You must initialize the supabase instance before calling Supabase.instance"
- Make sure `Supabase.initialize()` is called in `main.dart` before `InitialBinding().dependencies()`

### Upload fails with 403 Forbidden
- Check RLS policies in Supabase Storage
- Ensure user is authenticated
- Verify bucket name matches in code

### Files not appearing in storage
- Check network connectivity
- Verify credentials are correct
- Check browser console for errors

### Firebase Storage quota exceeded
- Check Firebase Console for usage
- Upgrade plan or delete old files

---

## File Structure

After enabling file uploads, the storage structure will be:
```
chat-attachments/
├── chats/
│   ├── {chatId}/
│   │   ├── attachments/
│   │   │   ├── {uuid}.jpg
│   │   │   ├── {uuid}.pdf
│   │   │   └── ...
```

---

## Security Notes

- **Never commit credentials** to version control
- Use environment variables for sensitive data
- Implement proper RLS policies
- Validate file types and sizes on client and server
- Consider implementing virus scanning for production

---

## Next Steps

After enabling file uploads:
1. Test with various file types
2. Implement file size limits
3. Add file type validation
4. Consider implementing file compression
5. Add progress indicators for uploads

For more help, refer to:
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [Firebase Storage Docs](https://firebase.google.com/docs/storage)

