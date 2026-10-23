## Designing the Sample Application Screen

This section describes, step by step, how a single-screen "Student Profile Card" application is planned and assembled using the widgets introduced above. No source code is included here; the procedure focuses on what each part of the screen is responsible for and how the widgets are connected.

## Step 1: Plan the Screen Layout

A ContentPage as the overall screen, with its Title property set to something like "Widget Demo App".

An outer StackLayout (or ScrollView wrapping a StackLayout) to stack all the visual sections vertically and allow scrolling on smaller screens.

An Image widget near the top acting as a circular profile picture placeholder.

A Frame containing a vertical StackLayout of two Label widgets — one for the student's name in a larger, bold font, and one for their course in a smaller, grey font — to create a card-like profile summary.

A horizontal StackLayout containing two Button widgets, one labelled "Like" and one labelled "Message".

An Entry widget beneath the buttons, with its Placeholder property set to something like "Add a comment".

A horizontally scrolling ListView or CollectionView near the bottom, used to display a short list of skill tags.

## Step 2: Add the Profile Image and Summary Card

Place the Image widget at the top of the outer StackLayout and set its Source to a placeholder avatar image.

Add a Frame directly beneath the image, with its CornerRadius property set to give it rounded corners and a subtle shadow.

Inside the Frame, add a StackLayout containing the name Label and the course Label, one above the other.

## Step 3: Add the Interactive Like Button

Add a numeric counter value in the code-behind file to keep track of how many times "Like" has been pressed, starting at zero.

Set the Like Button's Text property initially to display the counter value, for example "Like (0)".

In the code-behind file, create an event-handler method that increases the counter by one and updates the Button's Text property to show the new count.

Connect this event-handler method to the Like Button's Clicked event so it runs whenever the button is tapped.

## Step 4: Add the Message Button and Comment Entry

Add a second Button labelled "Message" beside the Like button inside the same horizontal StackLayout.

Optionally connect this button's Clicked event to a simple handler, such as one that displays an alert/confirmation dialog.

Add the Entry widget beneath the button row, configured with placeholder text inviting the user to add a comment.

## Step 5: Add the Scrollable Skill List

Define a small collection of skill names, such as "C#", "Xamarin", ".NET", and "Git", in the code-behind file or as a bindable property.

Add a ListView or CollectionView widget to the page, with its Orientation (or ScrollDirection) set to Horizontal so the skills scroll sideways.

Define a simple item template for the list, consisting of a small Frame or BoxView with a Label showing each skill's name.

Bind the ListView/CollectionView's ItemsSource property to the skill collection prepared earlier, so each entry is automatically rendered using the template.

## Step 6: Review the Screen Before Running

Confirm every widget added to the XAML page has a matching, correctly spelled event-handler method in the code-behind file where interaction is required.

Confirm the outer layout (StackLayout/ScrollView) wraps all sections so the page scrolls correctly on smaller screens.

Confirm the Like Button's Clicked event is wired to its handler, and that the handler updates the Button's displayed text.

Confirm the skill list's ItemsSource is bound correctly so the horizontal list renders all prepared skill entries.

## Part 6: Running the Application

In Visual Studio's toolbar, set the startup project to the Android (or iOS) platform project.

Select a target device or emulator from the run-target dropdown, such as the Android Virtual Device configured earlier.

Click the "Run" (Play) button, or use the Debug menu, to build and deploy the application.

Wait for the emulator to launch (if not already running) and for the application to install and start automatically.

Confirm the Student Profile Card screen appears with the profile image, name/course card, buttons, comment box, and scrollable skill list.

Tap the "Like" button repeatedly and confirm the displayed count increases each time, demonstrating the event-handler logic.

Scroll the skill list horizontally to confirm all skill entries are visible and render correctly.

## Part 7: Result

A Xamarin.Forms application demonstrating the use of core widgets — ContentPage, StackLayout, Grid, Label, Image, Frame, Button, Entry, and ListView/CollectionView — was successfully installed, configured, designed, and executed on an Android emulator/device. The interactive "Like" button confirmed correct wiring between a XAML widget and its code-behind event handler.
