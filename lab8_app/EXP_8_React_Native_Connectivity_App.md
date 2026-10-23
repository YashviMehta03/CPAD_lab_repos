# EXPERIMENT 8

## Develop a Connectivity-Based Cross-Platform Application Using React Native

## Aim

To install the React Native development environment and develop a cross-platform (Android and iOS) application that detects the device's network connectivity status, displays whether the device is online or offline, identifies the type of connection, and updates automatically whenever the connectivity changes.

## Objectives

- Install and configure Node.js, npm, and the React Native tooling.
- Verify the development environment setup.
- Understand the default React Native project structure.
- Add a network-connectivity package to a React Native project.
- Design a screen that displays live connectivity status across platforms.
- Run and test the application on an emulator/simulator or physical device.

### Key Concepts Used in This Experiment

- **Cross-Platform Component:** A single React Native component whose code runs and renders natively on both Android and iOS without platform-specific rewrites.
- **Network State:** A combination of connection type (Wi-Fi, cellular, none, etc.), whether the device is connected to a network, and whether that network actually has internet reachability.
- **Event Listener:** A subscription that notifies the app whenever the network state changes, so the UI can update in real time.
- **State Management:** React's mechanism for storing the current connectivity values and re-rendering the screen whenever they change.
- **Native Module Bridge:** The underlying mechanism that lets a JavaScript package query native Android/iOS connectivity APIs and return the result to the React Native app.

## Part 3: Creating a New React Native Project

### Option A: Using the React Native Community CLI

21. Open a terminal and navigate to the folder where the project should be created.
22. Run the React Native CLI's project initialization command, providing a project name such as `ConnectivityApp`.
23. Allow the tool to download the project template and install the base dependencies.
24. Navigate into the newly created project folder.

### Option B: Using Expo (Simpler Setup, Recommended for Beginners)

25. Run the Expo project creation command and provide a project name.
26. Choose the blank TypeScript or JavaScript template when prompted.
27. Navigate into the newly created project folder.
28. Install the Expo Go app on a physical device, or prepare an emulator/simulator, to preview the app during development.

### Default Project Structure

| Folder / File | Purpose |
|---|---|
| `App.js` / `App.tsx` | Root component and entry point of the application's UI. |
| `android/` | Native Android project files (CLI workflow only). |
| `ios/` | Native iOS project files (CLI workflow only). |
| `package.json` | Project configuration: dependencies, scripts, and metadata. |
| `node_modules/` | Installed third-party packages. |
| `app.json` / `app.config.js` | App display name, icon, and platform settings (Expo workflow). |

## Part 4: Adding Network Connectivity Support

React Native does not expose network status directly; this capability is added through a community connectivity package that bridges to each platform's native network APIs.

### Step 1: Install the Connectivity Package

29. Open a terminal inside the project folder.
30. Install the community NetInfo package using your package manager (npm or yarn), or the Expo-compatible install command if using the Expo workflow.
31. For the CLI workflow on iOS, install the native CocoaPods dependencies inside the `ios` folder so the native module links correctly.

### Step 2: Confirm the Package Is Linked

32. Rebuild and reinstall the app on the emulator/simulator after installing the package, since a new native dependency requires a fresh native build.
33. Confirm no errors are reported about a missing native module when the app starts.

## Part 5: Designing the Connectivity Status Screen

This section describes, step by step, how the connectivity screen is planned and assembled. No source code is included here; the procedure focuses on what each part of the screen is responsible for and how the pieces fit together.

### Step 1: Plan the Screen Layout

- A title area at the top identifying the app, such as "Connectivity Status".
- A large status indicator in the centre of the screen — for example a coloured circle or badge — that turns green when online and red when offline.
- A text label beneath the indicator describing the connection type, such as Wi-Fi, Cellular, or No Connection.
- A secondary line of text showing whether the connection has actual internet reachability, not just a network link.
- A manual "Refresh" button that re-checks the connection on demand, in addition to automatic updates.

### Step 2: Read the Initial Connectivity State

34. When the screen first loads, request a one-time snapshot of the current network state from the connectivity package.
35. Store the connection type, the connected flag, and the internet-reachable flag as the screen's initial state values.
36. Render the status indicator and labels based on these initial values as soon as the screen appears.

### Step 3: Subscribe to Live Connectivity Changes

37. Register an event listener with the connectivity package when the screen is mounted, so that any future change in network status is reported automatically.
38. Inside the listener's callback, update the screen's stored state values with the newly reported connection type and status.
39. Ensure the listener is removed/unsubscribed when the screen is closed, to avoid memory leaks or duplicate callbacks.

### Step 4: Reflect State Changes Visually

- When the connected flag becomes true, switch the indicator to its "online" colour and update the type label (Wi-Fi/Cellular).
- When the connected flag becomes false, switch the indicator to its "offline" colour and show a "No Connection" message.
- Optionally, trigger a short animation or vibration cue when the state transitions, to draw the user's attention to the change.

### Step 5: Wire Up the Manual Refresh Button

40. Attach a press handler to the Refresh button.
41. On press, request a fresh one-time network state snapshot the same way as in Step 2.
42. Update the displayed state with the freshly fetched values, independent of the automatic listener.

### Step 6: Review the Screen Before Running

- Confirm the connectivity package is correctly installed and, for the CLI workflow, natively linked.
- Confirm the initial state is fetched when the screen loads, so the status is correct even before any change occurs.
- Confirm the live listener is both registered on mount and cleaned up on unmount.
- Confirm the visual indicator, labels, and refresh button all reference the same shared state values.

## Part 6: Running the Application

43. Start the configured Android emulator or iOS simulator, or connect a physical device (with the Expo Go app installed, if using Expo).
44. From the project folder, start the development server using the appropriate start command for your workflow.
45. Launch the app on the Android platform, the iOS platform, or scan the displayed QR code with Expo Go, depending on your setup.
46. Confirm the connectivity screen loads and correctly reflects the current network state.
47. Turn the device's Wi-Fi off and on (or toggle Airplane Mode) and confirm the screen updates automatically to reflect the change.
48. Press the Refresh button and confirm the status updates on demand as well.

## Part 7: Result

A cross-platform connectivity-based application was successfully installed, configured, and executed on Android (and, where applicable, iOS). The application correctly displayed the live network status, distinguished between Wi-Fi and cellular connections, reacted automatically to connectivity changes, and allowed the user to manually refresh the status, confirming correct integration of the network-connectivity component with React Native's state and lifecycle management.
