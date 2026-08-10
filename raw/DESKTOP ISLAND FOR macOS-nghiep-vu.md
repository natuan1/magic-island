# DESKTOP ISLAND FOR macOS
# PRODUCT REQUIREMENTS DOCUMENT — PRD

**Version:** 1.0  
**Platform:** macOS  
**Minimum OS:** macOS 14 Sonoma  
**Distribution:** Direct Distribution — DMG  
**Codename:** Desktop Island Mac  
**Status:** Ready for implementation

---

# 1. Product Overview

Desktop Island là một macOS utility biến vùng notch/top-center của màn hình thành một surface tương tác luôn sẵn sàng.

Trên MacBook có physical notch, ứng dụng hòa giao diện vào notch.

Trên Mac không có notch hoặc external monitor, ứng dụng tạo một floating island ở chính giữa cạnh trên màn hình.

Mục tiêu:

> **Biến notch/top-center của macOS thành một productivity surface luôn sẵn sàng.**

Sản phẩm không chỉ là media controller.

Nó kết hợp:

- Dynamic Island.
- Live Activities.
- Media Control.
- File Shelf.
- Clipboard History.
- Quick Actions.
- Timer.
- Calendar.
- System HUD.
- Camera Mirror.
- Utilities.

---

# 2. Reference Products

Sản phẩm tham khảo chính:

- NotchNook.
- Boring Notch.
- Atoll.
- DynamicNotchKit.
- NotchDrop.
- DynamicWin.

Boring Notch hiện đã chứng minh được nhiều use case của mô hình này như media control, calendar, reminders, mirror, file shelf/AirDrop, system HUD và Bluetooth activity; project hỗ trợ macOS 14+.

Atoll cũng triển khai mô hình tương tự với media, live activities, clipboard history, timer, calendar preview và system monitoring.

Chúng ta dùng các sản phẩm trên làm:

- product reference;
- UX reference;
- edge-case reference;

không clone source code.

---

# 3. Core Product Vision

Desktop Island phải thỏa mãn bốn nguyên tắc.

## 3.1 Native

Người dùng phải có cảm giác đây là một phần của macOS.

Không được tạo cảm giác:

- Electron app;
- web popup;
- floating browser window.

---

## 3.2 Fast

Island phải xuất hiện gần như tức thì.

Interaction phải có cảm giác:

```text
pointer
   ↓
Island
   ↓
response
```

không có độ trễ dễ nhận thấy.

---

## 3.3 Beautiful

Animation là feature cốt lõi.

Expand/collapse phải sử dụng:

- spring animation;
- smooth geometry transition;
- opacity;
- blur;
- scale;
- matched transitions.

Animation không chỉ để trang trí.

Animation phải giúp người dùng hiểu:

```text
activity appeared
activity changed
island expanded
view changed
action completed
```

---

## 3.4 Invisible When Unused

Khi không cần sử dụng:

- không chiếm Dock;
- không chiếm Alt/Command-Tab;
- không steal keyboard focus;
- không chạy animation loop;
- CPU idle phải cực thấp.

---

# 4. Distribution Strategy

Desktop Island không phát hành qua Mac App Store.

Distribution:

```text
Website
   ↓
DMG
   ↓
Desktop Island.app
   ↓
/Applications
```

Production binary phải:

```text
Developer ID signed
+
Hardened Runtime
+
Notarized
+
Stapled notarization ticket
```

Apple hỗ trợ chính thức Developer ID và notarization cho phần mềm phân phối ngoài Mac App Store.

Không yêu cầu người dùng:

```text
xattr -d
Gatekeeper bypass
Disable SIP
```

trong bản production.

---

# 5. Target Users

Primary users:

- developers;
- designers;
- office workers;
- content creators;
- productivity enthusiasts;
- macOS power users.

Đặc biệt phù hợp với người thường xuyên:

- copy/paste;
- kéo file;
- nghe nhạc khi làm việc;
- họp online;
- dùng timer;
- chuyển nhiều ứng dụng.

---

# 6. Primary Interaction Model

Island có hai trạng thái cơ bản:

```text
Compact
   ↓
Expanded
```

Ví dụ Compact:

```text
        █████████████
       physical notch

       ♪ Spotify  ▶
```

Expanded:

```text
╭───────────────────────────────╮
│                               │
│  Album                        │
│  Beautiful Things            │
│  Benson Boone                 │
│                               │
│      ◀     ▶/Ⅱ     ▶          │
│                               │
│  ───────────────────────────  │
│                               │
│ Shelf   Clipboard   Timer     │
│                               │
╰───────────────────────────────╯
```

---

# 7. Island States

Business state machine:

```text
Hidden

Idle

CompactActivity

Hovering

Expanding

Expanded

Interacting

DragTarget

Collapsing
```

Additional flags:

```text
Pinned
DoNotDisturb
Passive
Interactive
```

---

# 8. Opening the Island

Island có thể được mở bằng:

### Hover

Pointer vào notch.

Có configurable delay.

Ví dụ:

```text
150 ms
250 ms
400 ms
disabled
```

### Click

Click notch.

### Global shortcut

Ví dụ mặc định:

```text
⌥ Space
```

User có thể đổi.

### Drag

Kéo file vào notch:

```text
Idle
 ↓
DragTarget
 ↓
Expanded Shelf
```

---

# 9. Physical Notch Detection

Ứng dụng không hard-code từng model MacBook.

macOS cung cấp thông tin safe area và top auxiliary regions trên `NSScreen`; safe-area top inset có thể phản ánh camera housing của Mac có notch.

Product phải hỗ trợ:

```text
Physical notch MacBook

Mac without notch

External monitor

Multiple monitors
```

---

# 10. Compact Activity

Compact mode dùng để hiển thị activity ngắn.

Ví dụ:

```text
♪ Spotify
```

```text
🔊 72%
```

```text
🎧 AirPods Connected
```

```text
⏱ 04:32
```

```text
✓ File added
```

---

# 11. Activity System

Đây là nghiệp vụ quan trọng nhất của toàn ứng dụng.

Feature không tự điều khiển Island.

Feature publish:

```text
Activity
```

Ví dụ:

```text
MediaFeature
     ↓
MediaActivity

TimerFeature
     ↓
TimerActivity

ShelfFeature
     ↓
FileAddedActivity
```

Activity Engine quyết định activity nào xuất hiện.

---

# 12. Activity Priority

Ví dụ:

| Activity | Priority |
|---|---:|
| Media | 20 |
| Calendar upcoming | 30 |
| Bluetooth | 40 |
| Timer running | 40 |
| Volume | 60 |
| Timer completed | 80 |
| File dropped | 90 |
| Critical system state | 100 |

Ví dụ:

```text
Spotify
   ↓

Volume changed

Spotify
```

Activity tạm thời hết hạn thì activity trước được restore.

---

# 13. Home View

Expanded Island mặc định mở Home.

```text
╭─────────────────────────────╮
│ CURRENT ACTIVITY            │
│                             │
│ Spotify                     │
│                             │
│ ─────────────────────────── │
│                             │
│ Shelf  Clipboard  Timer     │
│                             │
╰─────────────────────────────╯
```

Home không được trở thành dashboard lớn.

Mục tiêu:

> Feature thường dùng phải truy cập trong tối đa 1–2 interaction.

---

# 14. Media Feature — P0

Media là vertical slice đầu tiên của sản phẩm.

Hiển thị:

- application.
- artwork.
- title.
- artist.
- album.
- playback state.
- timeline.
- duration.

Controls:

- play.
- pause.
- previous.
- next.
- seek.

Compact:

```text
♪ Song Title
```

Expanded:

```text
[ Artwork ]

Song
Artist

──────●────────────

◀      ▶/Ⅱ      ▶
```

Không hard-code Spotify.

---

# 15. Media Integration Policy

macOS không cung cấp public system-wide Now Playing API tương đương Windows GSMTC.

Các project như Boring Notch hiện sử dụng MediaRemoteAdapter để tiếp tục truy cập Now Playing trên macOS mới; adapter dựa trên private MediaRemote framework và một helper mechanism.

Vì chúng ta direct-distribute:

```text
MediaRemote integration
```

được phép nghiên cứu và sử dụng như một optional platform adapter.

Tuy nhiên:

- feature phải degrade gracefully;
- MediaRemote không được trở thành dependency của core;
- update macOS không được crash app nếu adapter hỏng.

---

# 16. File Shelf — P0

Đây là một trong các core productivity features.

Workflow:

```text
Finder
   ↓ drag

     Island

   ↓ drop

File Shelf

   ↓

Finder / Mail / Slack / Browser
```

User có thể:

- drag file vào;
- drag nhiều file;
- drag file ra;
- open;
- reveal in Finder;
- Quick Look;
- copy;
- delete khỏi shelf;
- pin;
- AirDrop;
- share.

---

# 17. Shelf Storage

Ba modes:

### Reference

Chỉ lưu URL gốc.

### Temporary Copy

File được copy vào application storage.

Có retention.

Ví dụ:

```text
1 hour
1 day
7 days
```

### Pinned

Giữ cho tới khi user xóa.

---

# 18. File Drop Feedback

Khi drag file tới notch:

```text
Normal

██████
```

transition:

```text
╭──────────────────────╮
│ Drop files here      │
╰──────────────────────╯
```

Drop thành công:

```text
✓ Added 3 files
```

sau đó quay về activity trước.

---

# 19. Clipboard History — P0

Support:

- plain text.
- URL.
- image.
- file references.

History:

```text
Clipboard

────────────────

SELECT * FROM Order...

github.com/...

[ screenshot ]

Invoice.pdf
```

Actions:

- copy again;
- pin;
- search;
- delete;
- clear;
- reveal file.

---

# 20. Clipboard Privacy

Clipboard là dữ liệu nhạy cảm.

Default:

```text
Local only
```

Không:

```text
upload cloud
analytics content
send telemetry
```

User có:

```text
Pause Clipboard Monitoring

Clear History

Retention Policy
```

Retention options:

```text
Session
24 hours
7 days
30 days
Unlimited
```

---

# 21. Clipboard Monitoring

AppKit cung cấp `NSPasteboard.changeCount`, tăng khi pasteboard ownership thay đổi; Desktop Island có thể dùng giá trị này để phát hiện thay đổi clipboard.

Do macOS không có event tương đương `WM_CLIPBOARDUPDATE` của Windows cho use case này, clipboard monitoring có thể sử dụng lightweight polling.

Target:

```text
500ms – 1000ms
```

Chỉ chạy nếu Clipboard Feature được bật.

---

# 22. Quick Actions — P0

Quick Action chạy dựa trên loại dữ liệu.

## Text

```text
Copy
Search
Open URL
Create QR
```

## File

```text
Open
Quick Look
Reveal
Copy Path
Rename
Compress
Share
AirDrop
```

## Image

```text
Copy
Save
Quick Look
Compress
Convert
```

Future:

```text
OCR
AI
```

---

# 23. Timer — P0

User có thể:

- create;
- pause;
- resume;
- cancel;
- restart.

Compact:

```text
⏱ 14:32
```

Timer completed:

```text
╭─────────────────────╮
│ Timer finished      │
│                     │
│ Restart       Close │
╰─────────────────────╯
```

Timer Finished priority cao hơn Media.

---

# 24. Global Shortcuts — P0

Các shortcut:

```text
Open Island

Open Clipboard

Open Shelf

Start Timer
```

User có thể customize.

KeyboardShortcuts là một Swift package MIT hỗ trợ user-customizable global shortcuts và được thiết kế cho macOS.

---

# 25. Menu Bar — P0

Desktop Island chạy dạng menu-bar utility.

Menu:

```text
Desktop Island

Show Island

Clipboard
Shelf
Timer

──────────

Pause Activities

Settings

Check for Updates

Quit
```

Không cần Dock icon mặc định.

---

# 26. Launch at Login — P0

Setting:

```text
Launch Desktop Island at Login
```

Dùng native:

```text
SMAppService.mainApp
```

Apple cung cấp `SMAppService` trên macOS 13+ để quản lý Login Items và `mainApp` để cấu hình app chính launch at login.

---

# 27. Multiple Displays — P0

MVP:

```text
Primary Display

Specific Display
```

P1:

```text
Active Display

Display Under Cursor

All Displays
```

Khi monitor disconnect:

```text
Island
 ↓
move to Primary Display
```

Không crash.

Không để panel nằm ngoài màn hình.

---

# 28. Non-notch Displays

External monitor hoặc Mac không notch:

```text
          ╭────────────╮
          │   Island   │
          ╰────────────╯
```

Sử dụng floating-island geometry.

DynamicNotchKit cũng hỗ trợ floating style trên Mac không có notch và toàn bộ content được render bằng SwiftUI.

---

# 29. Calendar — P1

Dùng Apple Calendar database thông qua EventKit.

Hiển thị:

```text
Next Event

10:30
Architecture Review

in 14 min
```

Expanded:

```text
Today

10:30 Architecture Review
13:00 Lunch
15:30 Customer Call
```

EventKit cung cấp API để lấy và quản lý Calendar/Reminder data và gửi notification khi database thay đổi.

Feature phải request permission rõ ràng.

---

# 30. Camera Mirror — P1

Use cases:

```text
Check appearance before meeting

Check camera framing
```

Camera chỉ chạy khi Mirror mở.

Không background capture.

---

# 31. System Activities — P1

Activities:

```text
Volume

Brightness

Keyboard brightness

Battery

Charging

Microphone

Camera

Focus

Bluetooth
```

Ví dụ:

```text
🔊 68%
```

```text
☀ 74%
```

```text
🔋 32% Charging
```

---

# 32. Mirror — P1

UI:

```text
╭──────────────────────────╮
│                          │
│      Camera Preview      │
│                          │
╰──────────────────────────╯
```

Không record.

Không save.

Không transmit.

---

# 33. View Navigation

Expanded view gồm:

```text
Home

Media

Shelf

Clipboard

Timer
```

Navigation bằng:

- click;
- horizontal gesture;
- trackpad;
- optional scroll navigation.

Scroll navigation có thể disable.

---

# 34. Appearance Settings

Settings:

```text
Island size

Expanded size

Corner radius

Animation strength

Shadow

Blur

Hover delay

Theme
```

Presets:

```text
Compact

Default

Large

Custom
```

---

# 35. Behavior Settings

```text
Expand on Hover

Expand on Click

Collapse Delay

Open on Drag

Show Media Activity

Show System Activities

Follow Cursor Display
```

---

# 36. Permission Center

Ứng dụng cần một màn hình:

```text
Permissions
```

Hiển thị:

```text
Calendar       Granted

Camera         Not Granted

Accessibility  Not Required

Automation     Not Granted
```

Mỗi permission giải thích:

- dùng để làm gì;
- feature nào cần;
- cách revoke.

Không request tất cả permission ngay lần launch đầu tiên.

Request just-in-time.

---

# 37. Direct Distribution UX

First run:

```text
Welcome

Choose basic settings

Enable Launch at Login?

Enable Clipboard?

Done
```

Không yêu cầu account.

Không yêu cầu sign-in.

Không bắt user cấp Calendar/Camera nếu chưa sử dụng.

---

# 38. Updates

Ứng dụng phải có auto updater.

Recommended:

```text
Sparkle 2
```

Sparkle là framework update chuyên cho macOS direct-distribution; release hiện tại tại thời điểm research là 2.9.4 và có cả fix liên quan dockless/background applications.

Modes:

```text
Automatically check updates

Automatically download

Manual check
```

---

# 39. Feature Flags

Mọi feature phải có khả năng disable.

```json
{
  "features": {
    "media": true,
    "shelf": true,
    "clipboard": true,
    "timer": true,
    "calendar": false,
    "mirror": false,
    "bluetooth": false
  }
}
```

---

# 40. Customer Build Profiles

Không fork project cho customer.

Ví dụ:

```text
Default

Lite

Pro

CustomerA

CustomerB
```

Customer A:

```text
Media
Shelf
Timer
```

Customer B:

```text
Media
Clipboard
Calendar
```

---

# 41. Extension System

Không hỗ trợ arbitrary third-party plugin trong MVP.

Future architecture:

```text
Main App

  ↓ XPC

Plugin Host

  ↓

Plugin
```

Không load random bundle trực tiếp vào main process.

---

# 42. AI — P2

AI hoàn toàn optional.

Use cases:

```text
Clipboard
 ↓
Rewrite
Translate
Summarize

Image
 ↓
OCR
Explain

PDF
 ↓
Summarize

File
 ↓
Ask AI
```

AI không được đưa vào Core.

AI là Feature Module.

---

# 43. Performance Requirements

Engineering targets:

### Idle

```text
CPU average < 0.5%
```

trên hardware baseline.

### Memory

Target:

```text
< 150 MB working set
```

với base feature set.

### Animation

Target:

```text
60 FPS
```

và ProMotion-friendly.

### Startup

Island visible:

```text
< 1 second
```

trên normal warm launch.

---

# 44. Reliability

Phải xử lý được:

```text
sleep

wake

screen lock

screen unlock

display connect

display disconnect

resolution change

Spaces change

full-screen application

media app terminate

file deleted

permission revoked
```

mà không restart app.

---

# 45. Privacy Principles

Default:

```text
Local First

No clipboard upload

No file upload

No account

No cloud

No content telemetry
```

Telemetry nếu dùng chỉ chứa:

```text
performance
crashes
feature usage counters
```

không chứa content.

---

# 46. Accessibility

Support:

- Reduce Motion.
- keyboard navigation.
- VoiceOver labels.
- sufficient contrast.

Passive Island không steal focus.

Khi user mở Search hoặc nhập dữ liệu, Island mới chuyển Interactive Mode.

`NSPanel.becomesKeyOnlyIfNeeded` hỗ trợ mô hình panel chỉ trở thành key window khi cần keyboard input.

---

# 47. MVP Scope

Version 1.0:

```text
Notch / Floating Island Engine

Activity Engine

Media

File Shelf

Clipboard

Timer

Quick Actions

Global Shortcuts

Menu Bar

Settings

Multiple Display Basics

Updater

Direct Distribution
```

Không có trong MVP:

```text
AI

Plugins

Cloud Sync

Weather

Calendar

Bluetooth

System Monitor

Lock Screen Widgets
```

---

# 48. Vertical Slice đầu tiên

Ứng dụng đầu tiên phải làm được:

```text
Launch

 ↓

Island appears

 ↓

Media starts

 ↓

Compact activity appears

 ↓

Hover

 ↓

Island expands

 ↓

Play / Pause

 ↓

Next track

 ↓

Collapse

 ↓

Media ends

 ↓

Idle
```

Nếu workflow này chưa hoàn hảo thì không phát triển Clipboard/Shelf.

---

# 49. Release Roadmap

## 0.1 — Window Prototype

```text
Notch detection
NSPanel
positioning
animation
multi-display
```

## 0.2 — Media Vertical Slice

```text
Activity Engine
Media
metadata
artwork
controls
```

## 0.3 — Productivity

```text
Shelf
Clipboard
Timer
Quick Actions
```

## 0.4 — Productization

```text
Settings
Menu Bar
Global shortcuts
Launch at Login
Sparkle
```

## 0.5 — Hardening

```text
performance
sleep/wake
multi-display
permissions
accessibility
```

## 1.0

Production release.

## 1.x

```text
Calendar
Mirror
System HUD
Bluetooth
```

## 2.x

```text
AI
Automation
Plugin SDK
Cloud Sync
```

---

# 50. Definition of Done

Một feature chỉ Done khi:

- functionality complete;
- unit tests pass;
- integration tests pass;
- UI states tested;
- no crash;
- no compiler warning;
- permissions handled;
- resource cleanup đúng;
- sleep/wake tested;
- multi-display tested;
- settings persist;
- feature can disable independently;
- logging sufficient;
- CI green.

---

# 51. Product Rule

Trước khi thêm feature:

> Tính năng này có làm người dùng quay lại Island thường xuyên hơn không?

Nếu không:

không đưa vào Core.

Desktop Island phải là:

> **một productivity surface nhỏ, nhanh và hữu dụng**

không phải:

> **một dashboard chứa tất cả mọi thứ.**