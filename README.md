# FIxOnGo AI

FIxOnGo is a modern on-demand automotive service platform that connects vehicle owners with specialized service providers. Built with Flutter and Firebase, it offers a seamless, role-aware experience for all users.

## 🚀 Key Features

- **Multi-Role Support**: Tailored experiences for Users, Mechanics, Towing Services, Spare Part Sellers, and Drivers.
- **Universal Authentication**:
  - **Traditional Email/Password** login and signup.
  - **Mobile OTP (One-Time Password)** for fast and secure access.
  - **Google Sign-In** integration for one-tap authentication.
- **Step-Based Signup**: A refined two-step registration flow that prioritizes security and user experience.
- **Unified Dashboards**: Dynamic dashboards that automatically adapt to the user's role (Mechanic, Seller, etc.) upon login.
- **Modern UI/UX**: Feature-rich interface with support for both Light and Dark modes, elegant animations, and responsive layouts.

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **Backend/Auth**: Firebase Authentication, Cloud Firestore
- **Theme**: Custom ThemeProvider with Dark Mode support
- **State Management**: Provider / SetState (Context-aware)

## 🏁 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Dacalk/FIxOnGo_AI.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

## 📂 Project Structure

- `lib/screens/`: Main application screens (Login, Signup, Dashboards, etc.)
- `lib/components/`: Reusable UI components (Buttons, Inputs, Dropdowns)
- `lib/services/`: Core logic and third-party integrations (Google Auth, Firestore)
- `lib/assets/`: Image assets and icons

---

_Developed with ❤️ for the automotive community._
