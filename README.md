


          
# ChatterG - Secure Messaging App with AI Integration

## Overview

ChatterG is a secure messaging application built with [Flutter](https://flutter.dev/) that prioritizes privacy and security. The app features end-to-end encryption for messages, secure file sharing, user authentication, and now includes AI-powered chat capabilities through Google's Gemini API.

## Screenshots

<!-- 
SCREENSHOT SECTION

Instructions for adding screenshots:

1. Take screenshots of your app showing key features:
   - Login/Registration screen
   - Chat list/home screen
   - Individual chat conversation
   - Group chat
   - Gemini AI chat interface
   - Settings/profile screen

2. Save the screenshots in a 'screenshots' folder at the root of your project

3. Add them to this section using the following markdown format:

```markdown
### Login Screen
![Login Screen](screenshots/login_screen.png)

### Home Screen
![Home Screen](screenshots/home_screen.png)

### Chat Screen
![Chat Screen](screenshots/chat_screen.png)

### Group Chat
![Group Chat](screenshots/group_chat.png)

### Gemini AI Chat
![Gemini Chat](screenshots/gemini_chat.png)

### Profile Settings
![Profile Settings](screenshots/profile_settings.png)
```

4. Make sure your screenshots are clear, properly cropped, and demonstrate the feature effectively

5. Recommended screenshot dimensions: 1080x1920 pixels (portrait) or appropriate device resolution

6. Keep file sizes reasonable (250KB-1MB per image) by using PNG or JPG format

7. Consider adding brief captions below each screenshot to highlight specific features
-->

## Features

### Authentication
- Email and password-based authentication using [Firebase Auth](https://firebase.google.com/products/auth)
- User registration with secure account creation
- Persistent login sessions

### Messaging
- One-on-one private chats with end-to-end encryption
- Group chat functionality
- Real-time message delivery and updates
- Message deletion capability
- Typing indicators and read receipts

### Security
- End-to-end encryption using [X25519](https://en.wikipedia.org/wiki/Curve25519) key pairs
- Secure key exchange for establishing encrypted sessions
- Encrypted message storage
- Secure attachment handling

### File Sharing
- Support for image attachments
- Support for document attachments
- Secure storage using [Supabase](https://supabase.com/)

### AI Integration
- Chat with [Google's Gemini AI](https://ai.google.dev/)
- Support for multiple Gemini models (Gemini 2.5 Pro, Gemini Pro, Gemini Pro Vision)
- Image and file upload capabilities with compatible models
- Secure API key storage
- Token usage tracking

### User Experience
- Dark theme UI
- Intuitive chat interface
- User profiles with display names and avatars
- Chat history with timestamps

## App Demo

<!-- 
VIDEO DEMO SECTION

Instructions for adding a video demo:

1. Create a short (1-3 minute) video demonstrating the key features of your app

2. Upload the video to YouTube or another video hosting platform

3. Add the video link using one of these formats:

   - YouTube embed:
   ```markdown
   <iframe width="560" height="315" src="https://www.youtube.com/embed/YOUR_VIDEO_ID" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
   ```

   - Simple link:
   ```markdown
   [Watch the ChatterG Demo Video](https://youtube.com/watch?v=YOUR_VIDEO_ID)
   ```

4. Ensure your video shows:
   - App startup and login
   - Creating a new chat
   - Sending and receiving messages
   - Attachment functionality
   - Gemini AI chat interaction
   - Any special security features
-->

## Technology Stack

### Frontend
- [Flutter](https://flutter.dev/) for cross-platform mobile development
- [GetX](https://pub.dev/packages/get) for state management and dependency injection
- [GoRouter](https://pub.dev/packages/go_router) for navigation

### Backend Services
- [Firebase Authentication](https://firebase.google.com/products/auth) for user management
- [Firebase Firestore](https://firebase.google.com/products/firestore) for database storage
- [Supabase](https://supabase.com/) for file storage
- [Google Gemini API](https://ai.google.dev/) for AI chat capabilities

### Security
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) for local secure key storage
- [Cryptography](https://pub.dev/packages/cryptography) package for encryption operations

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
- [Firebase](https://firebase.google.com/) project setup
- [Supabase](https://supabase.com/) project setup
- [Google Gemini API key](https://ai.google.dev/) (optional, for AI features)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/chatter_jee.git
cd chatter_jee
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Setting up Gemini API

1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. In the app, navigate to Settings
3. Enter your API key in the Gemini API Key section
4. The app will securely store your key for future use

## Project Structure

- `lib/app/bindings/` - Dependency injection setup
- `lib/app/controllers/` - Business logic and state management
- `lib/app/data/` - Data models and providers
- `lib/app/routes/` - Application routing
- `lib/app/theme/` - UI theme configuration
- `lib/app/ui/` - User interface components
- `lib/app/utils/` - Utility functions

## Security Architecture

ChatterG implements a robust security architecture:

1. **Identity Keys**: Each user generates a unique X25519 key pair during registration
2. **Session Establishment**: Secure session keys are established for each chat using key exchange
3. **Message Encryption**: All messages are encrypted using the session keys before transmission
4. **Secure Storage**: Keys are stored securely using platform-specific secure storage
5. **API Key Protection**: Gemini API keys are encrypted and stored securely on the device

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT) - see the LICENSE file for details.

## Acknowledgments

- [Flutter team](https://github.com/flutter) for the amazing framework
- [Firebase](https://firebase.google.com/) and [Supabase](https://supabase.com/) for backend services
- [Google Gemini](https://ai.google.dev/) for AI capabilities
- All contributors to the open-source packages used in this project
        