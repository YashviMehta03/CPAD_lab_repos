# Lab 10 - LayoutsDemoApp

## App Overview

LayoutsDemoApp is a .NET MAUI application that demonstrates how different layout containers can be combined and nested to build a single "Profile Page" screen. The aim of the experiment is to understand what each layout contributes and how layouts behave when placed inside one another.

The app is a single page (`MainPage.xaml`). The whole page is wrapped in a `ScrollView`, so the content can scroll when it is taller than the screen. The ScrollView has exactly one child, a vertical `StackLayout`, which stacks every section of the page one below another.

## Screen Sections

| Section | Layouts / Views used | Purpose |
|---|---|---|
| Header | Horizontal `StackLayout`, `Label`, `AbsoluteLayout`, `Image`, `BoxView` | Shows the "Profile Page" title on the left and a notification icon on the right. A small red circular `BoxView` badge is placed at the icon's top-right corner using exact `AbsoluteLayout` bounds, so it overlaps the icon. |
| Profile card | `Frame`, `Grid`, `Image`, vertical `StackLayout`, `Label` | The `Frame` groups the content as a card. The `Grid` has two columns: a fixed 80-wide column for the profile picture and a star-sized column for the text. A `StackLayout` nested in the second cell holds the name and role. |
| Statistics row | Horizontal `StackLayout` with three vertical `StackLayout`s | Displays Posts, Followers and Following. Each group has a bold number above a smaller caption, and the groups are spaced evenly across the row. |
| Tag list | `FlexLayout`, `Frame`, `Label` | Tag chips (Design, Mobile, UI, .NET MAUI, XAML, C#, Layouts) are laid out with `Wrap="Wrap"`, so they flow onto new lines depending on the screen width instead of overflowing. |
| Action button | `Button` | A "View Full Profile" button spanning the full width. Tapping it shows an alert. |

## Layouts Demonstrated

- **ScrollView** - scrolls the page; holds a single child.
- **StackLayout (vertical and horizontal)** - the page backbone, the header row, and the statistics groups.
- **Grid** - column-based arrangement of the profile image and text.
- **FlexLayout** - wrapping tag list.
- **AbsoluteLayout** - precise, overlapping placement of the notification badge.

## Project Structure

- `LayoutsDemoApp/MainPage.xaml` - UI definition of the Profile Page.
- `LayoutsDemoApp/MainPage.xaml.cs` - code-behind with the button click handler.
- `LayoutsDemoApp/Resources/Images/` - `yashvi_image.jpg` (profile picture) and `notif_icon.jpg` (notification icon).

## How to Run

Requirements: .NET SDK with the MAUI workload installed (Visual Studio 2022/2026 with the ".NET Multi-platform App UI development" workload).

```powershell
cd LayoutsDemoApp
dotnet build -t:Run -f net10.0-windows10.0.19041.0
```

Or open `LayoutsDemoApp.csproj` in Visual Studio, select **Windows Machine** (or an Android emulator) and press F5. If the Windows run fails, enable Developer Mode in Windows Settings.
