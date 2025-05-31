# TaskMate - Task Tracking Application

TaskMate is a Flutter To-Do application where users can create and complete tasks, see only their own data, and authenticate using Supabase Authentication.

## Features

- **User Management**: Registration, login, and password reset (Supabase Authentication)
- **Task Management**: Create, edit, delete, and complete tasks
- **Smart Filtering**: All, completed, deadline-based, overdue, and upcoming tasks
- **Security**: User-specific tasks (row-level security)
- **Notification System**: Customizable reminders and deadline notifications
- **Visual Improvements**: Modern interface and task cards
- **Offline Support**: Offline access and synchronization
- **Turkish Language Support**: Fully Turkish interface

## Latest Updates

### v1.2.0 - 2024-08-05

- **Notification System Improvements**:
  - Notification time can now be customized by users
  - Fixed persistent storage issues with SharedPreferences
  - Prevented user-defined notification time from resetting when app is closed and reopened
  - Fixed task time and task reminder notifications

- **Task Filtering Improvements**:
  - Fixed issue with completed tasks being marked as overdue
  - Optimized filter switching operations
  - Ensured correct loading of data after filtering

- **User Experience Improvements**:
  - Removed unnecessary test notifications
  - Accelerated task completion process
  - Improved task card design

## Installation

### Requirements

- Flutter 3.x or higher
- Supabase account
- Dart 3.x or higher

### Steps

1. Clone the project
```bash
git clone https://github.com/your-username/taskmate.git
cd taskmate
```

2. Install dependencies
```bash
flutter pub get
```

3. Supabase Setup

- Create a new project on [Supabase](https://supabase.io/)
- Create the following table in SQL Editor:

```sql
-- Tasks table
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  deadline TIMESTAMP WITH TIME ZONE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Row Level Security (RLS) policies
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Users can only view their own tasks
CREATE POLICY "Users can view their own tasks" ON tasks
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own tasks
CREATE POLICY "Users can insert their own tasks" ON tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own tasks
CREATE POLICY "Users can update their own tasks" ON tasks
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own tasks
CREATE POLICY "Users can delete their own tasks" ON tasks
  FOR DELETE USING (auth.uid() = user_id);
```

4. API Key Security

**IMPORTANT**: Before uploading to GitHub, you need to hide your API keys.

You can create a `.env` file or edit the `lib/config/app_config.dart` file:

```dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Make sure to add this file to your `.gitignore`:
```
lib/config/app_config.dart  # Contains Supabase API keys
```

5. Run the application
```bash
flutter run
```

## Structure

- **lib/config**: Application configuration and API keys
- **lib/models**: Data models (Task, User, etc.)
- **lib/providers**: State management (TaskProvider, AuthProvider)
- **lib/screens**: Application screens (Home, Login, etc.)
- **lib/services**: Services (TaskService, NotificationService, etc.)
- **lib/widgets**: Reusable UI components
- **lib/utils**: Helper functions and tools

## Technologies

- **Flutter**: UI framework
- **Supabase**: Backend as a Service (Auth and Database)
- **Provider**: State Management
- **Flutter Local Notifications**: Notifications
- **Shared Preferences**: Local storage
- **Intl**: Date and language localization

## Security Measures

The following security measures have been implemented in this project:

1. **API Key Protection**: Supabase keys are protected with .gitignore
2. **Row-Level Security**: Users can only access their own data
3. **Secure Storage**: Sensitive data is stored securely
4. **Input Validation**: User inputs are validated
5. **Error Handling**: Errors are handled securely

## Troubleshooting

If you encounter issues while running the application:

1. **Update dependencies**: `flutter pub upgrade`
2. **Clean cache**: `flutter clean`
3. **Verify Supabase keys are correct**
4. **Check platform permissions**: Notifications, storage, etc.
5. **Review log outputs**: Error messages often indicate the source of the problem

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
