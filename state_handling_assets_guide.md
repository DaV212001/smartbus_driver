# SmartBus Driver App — State Handling & Styling Asset Guide

This guide serves as the standard development instruction and reference for network calls, loading states, success handlers, error handling, and visual skeletons. Whenever developing or integrating API endpoints in this repository, follow these precise patterns.

---

## 1. Core Network & State Utilities

### 🌐 Dio Template (`DioService`)
* **Location:** `lib/utils/templates/dio_template.dart`
* **Purpose:** Core networking wrapper built on top of the proactive/reactive token rotation system in `DioConfig`.
* **API Interface:**
  * `DioService.dioGet({required String path, Options? options, Object? data, Function(Response)? onSuccess, Function(Object, Response)? onFailure})`
  * `DioService.dioPost({required String path, Options? options, Object? data, Function(Response)? onSuccess, Function(Object, Response)? onFailure})`
  * `DioService.dioPatch({required String path, Options? options, Object? data, Function(Response)? onSuccess, Function(Object, Response)? onFailure})`
* **Rule:** All raw HTTP requests must go through these static methods to ensure seamless JWT headers, logging, and automated token refreshes.

### 🚦 Api Call Status (`ApiCallStatus`)
* **Location:** `lib/utils/api_call_status.dart`
* **Purpose:** State governing network operations.
* **States:** `loading`, `success`, `error`, `empty`, `holding`, `cache`, `refresh`.

### 🚨 Error Data Model (`ErrorData`) & Utilities (`ErrorUtil`)
* **Location:** `lib/utils/error_data.dart` and `lib/utils/error_utils.dart`
* **Purpose:** Decouples raw backend/network exception strings from user-facing UI messages and images.
* **Usage:**
  * Convert a raw error into structured visual information:
    ```dart
    ErrorData error = await ErrorUtil.getErrorData(exception.toString(), customMessage: "Failed to load data");
    ```
  * Custom translation integration (`.tr`) is handled internally by `ErrorUtil` based on connectivity and status codes.

---

## 2. Structural State Wrappers (UI Builders)

### 📦 Loaded Widgets Template (`LoadedWidget` & `LoadedListWidget`)
* **Location:** `lib/utils/templates/loaded_widgets_template.dart`
* **Purpose:** Declarative builders that switch automatically between loading, success, empty, and error views depending on `ApiCallStatus`.
* **LoadedWidget:**
  ```dart
  LoadedWidget(
    apiCallStatus: apiCallStatus,
    errorData: errorData,
    loadingChild: MyLoadingSkeleton(),
    errorChild: MyErrorCard(), // Optional, falls back to ErrorCard internally
    onReload: () => fetchData(),
    child: MyMainContent(),
  )
  ```
* **LoadedListWidget:** Wraps lists with a native `RefreshIndicator`.
  ```dart
  LoadedListWidget(
    apiCallStatus: apiCallStatus,
    errorData: errorData,
    list: itemsList,
    loadingChild: MyListSkeleton(),
    onEmpty: ErrorCard(errorData: syntheticEmptyData),
    onReload: () => fetchList(),
    child: ListView.builder(...),
  )
  ```

### 🎴 Error & Empty Card (`ErrorCard`)
* **Location:** `lib/widgets/cards/error_card.dart`
* **Purpose:** Uniform visual representation of both failure and empty states.
* **Synthetic Empty States:** For list or data empty states, construct an `ErrorCard` with synthetic `ErrorData` referencing `Assets.empty`:
  ```dart
  ErrorCard(
    errorData: ErrorData(
      title: "No Data Found",
      body: "There are no records to display at this time.",
      image: Assets.empty, // assets/images/empty.svg
      buttonText: "Refresh",
    ),
    refresh: () => refreshData(),
  )
  ```

---

## 3. Aesthetics, Animations, & Skeletons

### ✨ Shimmer Wrapper (`ShimmerWrapper`)
* **Location:** `lib/utils/wrappers/shimmer_wrapper.dart`
* **Purpose:** Premium loading state skeletons.
* **Skeleton Rules:**
  1. **Do not wrap cards as a whole:** Instead, wrap the *inner contents* (Row, Column, children) inside cards. This keeps card shadows/borders sharp while animating inside.
  2. **No sized boxes:** Use `Padding` instead of `SizedBox` for spacing within shimmering cards. `SizedBox` gets painted as a solid shimmering grey block which breaks spacing aesthetics.
  3. **Dummy Data:** Render placeholder content when `isEnabled` is true so that the children occupy correct layouts for the shimmer to trace.
  ```dart
  ShimmerWrapper(
    isEnabled: apiCallStatus == ApiCallStatus.loading,
    child: MyCardColumn(title: isLoading ? '---' : realTitle),
  )
  ```

### 🔘 Loading Animated Button (`LoadingAnimatedButton`)
* **Location:** `lib/widgets/animated_widgets/loading_animation_button.dart`
* **Purpose:** Captivating sweep-gradient visual feedback when submitting background actions.
* **Usage:** Ideal for active button submissions like "Start Trip", "End Trip", or login submissions.

### 🎬 Animations & Extensions (`animateOnPageLoad`)
* **Location:** `lib/utils/animations.dart`
* **Purpose:** Seamless slide-in, fade-in, and micro-interactions.
* **Usage:**
  ```dart
  myWidget.animateOnPageLoad(AnimationInfo(...))
  ```
