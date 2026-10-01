Follow the steps below to set up, design, and run the application (using React Native, with the Expo toolchain,
which is commonly used for lab/learning environments as it simplifies setup). This is a guide to the concepts
and workflow, not the source code itself.

### Setup Requirements
• Node.js and npm (or yarn) installed on the system, since React Native tooling runs on Node.js.

• A code editor such as VS Code, ideally with React Native / JavaScript extensions.
• Either the Expo Go app installed on a physical Android/iOS device, or an Android Studio emulator /
Xcode iOS simulator set up on the development machine.

### Design / Logic Steps
1. Create a new React Native project using the project-creation tooling (for example, Expo&#39;s CLI), which
scaffolds the folder structure, configuration files, and a starter entry-point component automatically.
2. Examine the generated project structure: the package.json file (listing dependencies and scripts), the
entry-point component file (typically App.js or App.tsx), and an assets folder for images/fonts.
3. Plan the screen(s) of the application: decide what information needs to be displayed and what interactions
(buttons, inputs, lists) the user should be able to perform.
4. In the entry-point component, structure the UI using core components — a View as the outer container,
Text components for any labels or content, and interactive components such as a Button or
TouchableOpacity for user actions.
5. Apply styling using the StyleSheet system and Flexbox properties, so that the layout positions elements
correctly and remains responsive across different device screen sizes and both platforms.
6. Introduce state into the component (using a state hook) for any data that should change while the app is
running, such as a counter, an input value, or a toggle.
7. Attach event handlers to the interactive components (such as an on-press handler on a button) that update
the state when the user interacts with the UI.
8. Confirm that the UI re-renders correctly and automatically whenever the state changes, reflecting the
interaction on screen.
9. If the application needs more than one screen, add a navigation library, define the individual screens as
separate components, and configure a navigator (such as a stack navigator) to move between them.
10. Start the development server using the project&#39;s start command, which bundles the JavaScript code and
makes it available to run on a device or emulator.
11. Launch the app either by scanning the development server&#39;s QR code with the Expo Go app on a physical
device, or by running it directly on an Android emulator / iOS simulator.
12. Test the application&#39;s behaviour and appearance on both Android and iOS (using two emulators, or a
device plus a simulator) to confirm that the same codebase produces a consistent, correctly working app
on both platforms.
13. Optionally, use the platform&#39;s build tooling to generate a distributable Android APK/AAB or iOS build
for installation outside the development environment.

### Expected Output
When the development server is started and the app is opened (via Expo Go or an emulator/simulator), the
designed screen(s) should appear correctly laid out on the device. Interacting with the app&#39;s controls (such as
tapping a button) should immediately update the relevant part of the UI as intended by the app&#39;s state logic.
Running the same project on both an Android and an iOS target should produce a consistent UI and behaviour,
confirming that the single React Native codebase works correctly across both platforms.