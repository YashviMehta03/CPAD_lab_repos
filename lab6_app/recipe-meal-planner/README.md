# LAB 6 - React Native: Recipe & Meal Planner App

A cross-platform mobile application built with **React Native** and the **Expo** toolchain.

## App Features

### 🏠 Home Screen
- Personalized greeting with live stats (total recipes, favourites, meals planned)
- **Today's meal plan** view showing what's planned for Breakfast, Lunch & Dinner
- Quick action buttons to Add Recipe or Plan Meals
- Favourite and recent recipe cards

### 📖 Recipes Screen
- Browse all recipes with full cards (emoji, name, time, servings, category)
- **Real-time search** by name, category, or ingredient
- **Category filter chips**: All, Breakfast, Lunch, Dinner, Dessert, Snack
- Navigate to detail view per recipe

### 🍽️ Recipe Detail Screen
- Full recipe view: emoji, name, category badge, cook time, servings, calories
- Ingredient list
- **Add to Meal Plan** (via cascading Alert menus)
- **Favourite/Unfavourite** toggle
- **Delete recipe** with confirmation dialog

### ➕ Add Recipe Screen
- Emoji picker for recipe icon
- Category selector chips
- Free-text description
- Cook time, servings, calories fields
- **Dynamic ingredient tags** — type and add, or tap ✕ to remove
- Form validation with Alerts

### 🗓️ Meal Plan Screen
- Weekly grid (Mon–Sun × Breakfast/Lunch/Dinner)
- Tap empty slot → **bottom-sheet modal** to pick a recipe
- Long-press filled slot → clear it
- Weekly calorie totals in stats bar

## Concepts Demonstrated (from instructions)
| Instruction Step | Implementation |
|---|---|
| State hook | `useState` for search, form fields, ingredients, modal visibility |
| State management | React Context (`RecipeContext`) for global recipes + meal plan |
| Event handlers | `onPress`, `onChangeText`, `onSubmitEditing`, `onLongPress` |
| Navigation | Bottom Tab + Native Stack navigator |
| Styling | `StyleSheet` + Flexbox across all screens |
| Re-renders | All UI updates automatically on state change (lists, badges, stats) |
| Cross-platform | Runs on Android & iOS via Expo Go |

## Setup & Run

```bash
cd lab6_app/recipe-meal-planner
npm start           # Start Metro bundler + Expo dev server
npm run android     # Run on Android emulator / device
npm run web         # Run in browser (for quick preview)
```

Then scan the QR code with **Expo Go** app on your phone.

## Dependencies
- `expo` (SDK 57)
- `@react-navigation/native`
- `@react-navigation/bottom-tabs`
- `@react-navigation/native-stack`
- `react-native-screens`
- `react-native-safe-area-context`
