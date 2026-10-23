# Lab 8 - Connectivity-based mobile application

The Connectivity Status App is a cross-platform mobile application developed using React Native that monitors the device's network connectivity in real time. It provides a simple and user-friendly interface to display whether the device is online or offline, identify the current connection type, and indicate internet reachability.

The application uses the NetInfo package to retrieve network information and listen for connectivity changes. React Native's state management updates the interface dynamically whenever the network status changes. A manual Refresh button is also provided to check the current connectivity status on demand.

The main features of the application are:
- Live Connectivity Monitoring: Automatically detects changes in the device's network connection.
- Online/Offline Status: Displays the current connectivity status using a visual indicator.
- Connection Type Detection: Identifies whether the device is connected through Wi-Fi, cellular data, or has no connection.
- Internet Reachability: Indicates whether the device can access the internet.
- Manual Refresh: Allows users to recheck the current network status whenever required.
- Cross-Platform Support: Designed to run on Android and iOS using a shared React Native codebase.

The application demonstrates how React Native can be used to develop responsive, connectivity-aware mobile applications that adapt to changes in network conditions.