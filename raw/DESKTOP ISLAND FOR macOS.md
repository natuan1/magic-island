# DESKTOP ISLAND FOR macOS
# TECHNICAL ARCHITECTURE DOCUMENT

**Version:** 1.0  
**Language:** Swift 6.4  
**IDE:** Xcode 26.6  
**UI:** SwiftUI + AppKit  
**Minimum Deployment:** macOS 14 Sonoma  
**Distribution:** Developer ID / DMG / Notarization  
**Architecture:** Clean Architecture + Modular Monolith  
**Concurrency:** Swift Concurrency  
**Package Management:** Swift Package Manager

---

# 1. Architecture Goals

Architecture ưu tiên:

```text
Maintainability

Performance

Native macOS Integration

Feature Isolation

Testability

Reliability

Replaceable Private APIs
```

Không ưu tiên:

```text
Cross-platform UI

maximum abstraction

microservices

framework experimentation
```

Windows và macOS chia sẻ:

```text
product architecture
domain concepts
protocol specifications
```

nhưng không share runtime/UI source.

---

# 2. Toolchain

Toolchain baseline:

```text
Xcode 26.6

Swift 6.4

Swift Language Mode 6

macOS SDK 26.x
```

Deployment target:

```text
macOS 14+
```

Apple hiện liệt kê Xcode 26.6 với Swift 6.4 compiler.

Không yêu cầu macOS 26 chỉ để sử dụng toolchain mới.

---

# 3. Core Technology Stack

```text
Swift

SwiftUI

AppKit

Swift Concurrency

Foundation

Combine only where required

EventKit

AVFoundation

ServiceManagement

OSLog

SQLite
```

Selective third-party packages:

```text
Sparkle
KeyboardShortcuts
```

Private integration layer:

```text
MediaRemote Adapter
SkyLight [future only]
```

---

# 4. Architecture Style

Sử dụng:

> Clean Architecture inside a Modular Monolith.

Logical dependency:

```text
Presentation
     ↓

Application
     ↓

Domain
```

Platform:

```text
Platform.macOS
      ↓
Application abstractions
```

Infrastructure:

```text
Infrastructure
      ↓
Application abstractions
```

Features:

```text
Feature
  ↓
Application
  ↓
Domain
```

---

# 5. Core Rule

Domain không được import:

```swift
SwiftUI
AppKit
EventKit
AVFoundation
MediaRemote
Sparkle
```

Domain chỉ dùng:

```text
Swift standard types

Foundation value types khi cần
```

Không có:

```text
NSWindow
NSImage
NSPasteboard
EKEvent
```

trong Domain Model.

---

# 6. Project Structure

Recommended:

```text
DesktopIsland/
│
├── DesktopIsland.xcodeproj
│
├── App/
│   ├── DesktopIslandApp.swift
│   ├── AppDelegate.swift
│   ├── Bootstrapper.swift
│   └── AppEnvironment.swift
│
├── Packages/
│
│   ├── Domain/
│   │   └── Sources/
│   │       └── DesktopIslandDomain/
│   │
│   ├── Application/
│   │   └── Sources/
│   │       └── DesktopIslandApplication/
│   │
│   ├── PlatformMacOS/
│   │   └── Sources/
│   │       └── DesktopIslandPlatformMacOS/
│   │
│   ├── Infrastructure/
│   │   └── Sources/
│   │       └── DesktopIslandInfrastructure/
│   │
│   └── Features/
│       ├── Media/
│       ├── Shelf/
│       ├── Clipboard/
│       ├── Timer/
│       ├── QuickActions/
│       ├── Calendar/
│       └── Mirror/
│
├── Presentation/
│   ├── Island/
│   ├── Settings/
│   ├── MenuBar/
│   └── Shared/
│
├── Tests/
│
├── scripts/
│
└── docs/
    └── adr/
```

Local Swift Packages tạo compile-time dependency boundaries.

---

# 7. Domain Modules

```text
Activities

Media

Shelf

Clipboard

Timer

QuickActions

Common
```

Không chứa platform implementation.

---

# 8. Activity Domain Model

```swift
struct IslandActivity: Identifiable, Sendable {

    let id: UUID

    let source: ActivitySource

    let kind: ActivityKind

    let priority: Int

    let lifetime: ActivityLifetime

    let createdAt: Date

    let expiresAt: Date?

    let content: ActivityContent

    let actions: [ActivityAction]
}
```

Không chứa SwiftUI View.

---

# 9. Activity Lifetime

```swift
enum ActivityLifetime: Sendable {

    case persistent

    case temporary(Duration)

    case whileSourceActive

    case until(Date)
}
```

---

# 10. Activity Engine

Activity Engine nên implement bằng actor:

```swift
actor ActivityEngine {

    private var activities:
        [UUID: IslandActivity] = [:]

    private var current:
        IslandActivity?

}
```

Lý do:

- activity đến từ nhiều asynchronous sources;
- actor serialize mutation;
- tránh locks thủ công.

---

# 11. Activity Engine API

```swift
protocol ActivityPublishing: Sendable {

    func publish(
        _ activity: IslandActivity
    ) async

    func remove(
        id: UUID
    ) async
}
```

Read stream:

```swift
protocol ActivityObserving: Sendable {

    var activities:
        AsyncStream<IslandActivity?> { get }
}
```

---

# 12. Event Architecture

Không cần:

```text
Kafka
RabbitMQ
NSNotificationCenter everywhere
```

Application event bus dùng:

```text
AsyncStream
AsyncSequence
Actors
```

hoặc typed in-process event dispatcher.

Ví dụ:

```swift
struct MediaChanged: Sendable {
    let snapshot: MediaSnapshot
}
```

Không dùng String event names.

---

# 13. Island State Machine

```swift
enum IslandState: Sendable {

    case hidden

    case idle

    case compact

    case hovering

    case expanding

    case expanded

    case interacting

    case dragTarget

    case collapsing
}
```

State transitions phải đi qua:

```swift
actor IslandStateMachine
```

Không cho View:

```swift
state = .expanded
```

tùy tiện.

---

# 14. Presentation State

Presentation nhận domain state và chuyển thành:

```swift
@MainActor
@Observable
final class IslandViewModel {
}
```

Pipeline:

```text
Domain

 ↓

Application State

 ↓

ViewModel

 ↓

SwiftUI
```

---

# 15. Window Architecture

Window shell:

```text
NSPanel

  ↓

NSHostingView

  ↓

SwiftUI IslandRootView
```

Không sử dụng:

```text
full-screen transparent NSWindow
```

Window chỉ bằng kích thước Island.

---

# 16. Panel Controller

```swift
@MainActor
protocol IslandWindowControlling {

    func show()

    func hide()

    func move(
        to display: DisplayDescriptor
    )

    func transition(
        to layout: IslandLayout
    )

    func setInteractionMode(
        _ mode: InteractionMode
    )
}
```

Implementation:

```text
IslandPanelController
```

---

# 17. NSPanel Configuration

Initial configuration conceptual:

```swift
let panel = NSPanel(
    contentRect: frame,
    styleMask: [
        .borderless,
        .nonactivatingPanel
    ],
    backing: .buffered,
    defer: false
)
```

Properties:

```text
transparent background

no title

floating behavior

no Dock presence

passive focus by default
```

Apple mô tả NSPanel là loại window dùng cho auxiliary UI và cung cấp `isFloatingPanel` cùng `becomesKeyOnlyIfNeeded`.

---

# 18. Passive vs Interactive Mode

## Passive

Dùng:

```text
Idle

Compact Activity

Media controls không cần keyboard
```

Không steal current application focus.

## Interactive

Dùng khi:

```text
Clipboard Search

Rename

Text Input

Settings
```

Có thể become key.

`becomesKeyOnlyIfNeeded` cho phép panel chỉ trở thành key khi keyboard input thực sự cần.

---

# 19. Window Levels

Public implementation trước:

```text
NSWindow.Level
```

Không bắt đầu project bằng SkyLight.

Requirement MVP:

```text
visible over normal application windows

behaves correctly with Spaces

configurable fullscreen behavior
```

SkyLight chỉ là fallback/future requirement cho:

```text
lock screen

system-level overlay
```

SkyLightWindow dùng private SkyLight APIs, vì vậy nếu sử dụng phải nằm trong một adapter riêng.

---

# 20. Notch Geometry

Platform service:

```swift
protocol NotchGeometryProviding {

    func geometry(
        for screen: NSScreen
    ) -> NotchGeometry
}
```

Model:

```swift
struct NotchGeometry: Sendable {

    let hasPhysicalNotch: Bool

    let notchFrame: CGRect?

    let safeAreaTop: CGFloat

    let screenFrame: CGRect

    let visibleFrame: CGRect
}
```

---

# 21. Detecting Physical Notch

Use:

```swift
screen.safeAreaInsets

screen.auxiliaryTopLeftArea

screen.auxiliaryTopRightArea
```

Apple xác nhận `safeAreaInsets` phản ánh vùng bị che, bao gồm camera housing trên một số Mac, còn hai auxiliary regions mô tả vùng top-left/top-right không bị che.

Không hard-code model name.

---

# 22. Notch Bounds Calculation

Conceptually:

```text
Left auxiliary area

         ↓

┌─────────────────────┐
│      physical       │
│       notch         │
└─────────────────────┘

         ↑

Right auxiliary area
```

Notch region có thể suy ra từ khoảng trống giữa:

```text
auxiliaryTopLeftArea.maxX

and

auxiliaryTopRightArea.minX
```

nếu dữ liệu có sẵn.

Fallback:

```text
centered floating geometry
```

---

# 23. Display Service

```swift
protocol DisplayProviding {

    var displays:
        [DisplayDescriptor] { get }

    func primary()
        -> DisplayDescriptor

    func displayContainingMouse()
        -> DisplayDescriptor?
}
```

Observe:

```text
NSApplication.didChangeScreenParametersNotification
```

và refresh geometry khi:

- connect display;
- disconnect;
- resolution change.

---

# 24. Non-notch Geometry

Strategy Pattern:

```text
IslandGeometryStrategy

    ├── PhysicalNotchStrategy

    └── FloatingIslandStrategy
```

DynamicNotchKit chứng minh mô hình physical/floating này khả thi và hỗ trợ Mac không có notch.

---

# 25. Animation Architecture

Không có:

```swift
while true {
    render()
}
```

SwiftUI render theo state.

Use:

```text
spring animations

matched geometry

keyframe animation

phase animation

content transitions
```

Core animation chỉ dùng khi SwiftUI không đáp ứng performance requirement.

---

# 26. Motion Tokens

Centralize:

```swift
enum MotionToken {

    static let quick = Duration
        .milliseconds(120)

    static let normal = Duration
        .milliseconds(220)

    static let slow = Duration
        .milliseconds(320)
}
```

Spring configuration cũng centralized.

Không hard-code:

```swift
.animation(.spring(duration: ...))
```

ở 50 views khác nhau.

---

# 27. Reduce Motion

Observe accessibility setting.

Reduced motion:

```text
remove bounce

reduce scale

prefer opacity

shorter transition
```

Không disable functionality.

---

# 28. Media Architecture

Application abstraction:

```swift
protocol MediaSessionProvider: Sendable {

    var updates:
        AsyncStream<MediaSnapshot?> { get }

    func playPause() async throws

    func next() async throws

    func previous() async throws

    func seek(
        to position: Duration
    ) async throws
}
```

---

# 29. Media Snapshot

```swift
struct MediaSnapshot: Sendable {

    let bundleIdentifier: String?

    let title: String?

    let artist: String?

    let album: String?

    let artwork: Data?

    let playbackState:
        MediaPlaybackState

    let position: Duration?

    let duration: Duration?

    let capabilities:
        MediaCapabilities
}
```

Không đưa:

```text
NSImage
```

vào Domain.

---

# 30. Media Implementations

```text
MediaSessionProvider

    ├── PublicMediaProvider

    └── MediaRemoteProvider
```

`MediaRemoteProvider` nằm tại:

```text
PlatformMacOSPrivate/
```

Không nằm trong Application.

---

# 31. MediaRemote Boundary

Package:

```text
DesktopIslandPlatformPrivate
```

có thể chứa:

```text
MediaRemoteAdapter

SkyLightAdapter
```

Main project chỉ biết:

```swift
MediaSessionProvider
```

Nếu MediaRemote bị Apple thay đổi:

```text
replace adapter

not architecture
```

MediaRemoteAdapter hiện sử dụng private MediaRemote framework và helper mechanism để cung cấp Now Playing trên macOS mới, bao gồm macOS 15.4+.

---

# 32. Media Failure Strategy

Nếu adapter fail:

```text
Media feature unavailable
```

Không:

```text
fatalError()
```

Activity Engine tiếp tục chạy.

Shelf/Clipboard/Timer tiếp tục hoạt động.

---

# 33. File Shelf Architecture

```text
NSDragging

   ↓

DragDropAdapter

   ↓

ShelfApplicationService

   ↓

ShelfRepository

   ↓

Shelf Feature

   ↓

SwiftUI
```

---

# 34. Shelf Domain Model

```swift
struct ShelfItem:
    Identifiable,
    Sendable {

    let id: UUID

    let displayName: String

    let originalURL: URL

    let managedURL: URL?

    let type: ShelfItemType

    let storageMode: ShelfStorageMode

    let createdAt: Date

    let pinned: Bool
}
```

---

# 35. File Security

Không auto-read toàn bộ file.

Shelf chỉ:

```text
metadata

thumbnail

file operations explicitly requested
```

Không index file content mặc định.

---

# 36. Thumbnail Service

Protocol:

```swift
protocol ThumbnailProviding: Sendable {

    func thumbnail(
        for url: URL,
        size: CGSize
    ) async throws -> Data
}
```

Implementation có thể dựa trên Quick Look APIs.

Cache thumbnail.

Không regenerate mỗi render.

---

# 37. Clipboard Architecture

```text
NSPasteboard

 ↓

ClipboardMonitor

 ↓

ClipboardNormalizer

 ↓

ClipboardRepository

 ↓

Clipboard Feature
```

---

# 38. Clipboard Monitor

Use:

```swift
NSPasteboard.general.changeCount
```

Store:

```swift
lastChangeCount
```

Timer:

```text
500ms–1s
```

Nếu:

```text
changeCount != previous
```

read new content.

Apple mô tả `changeCount` tăng mỗi lần ownership pasteboard thay đổi.

---

# 39. Clipboard Monitoring Rules

Polling:

```text
only when feature enabled
```

Pause khi:

```text
user disables clipboard
```

Never:

```text
update SwiftUI every polling tick
```

UI chỉ update khi clipboard thực sự thay đổi.

---

# 40. Clipboard Deduplication

Normalize:

```text
text

URL

image

file
```

Generate:

```text
SHA-256 content hash
```

Unique:

```text
Type + Hash
```

Repeated copy:

```text
update timestamp
```

không tạo record mới liên tục.

---

# 41. Clipboard Storage

Metadata:

```text
SQLite
```

Large payload:

```text
filesystem
```

Ví dụ:

```text
~/Library/Application Support/
    DesktopIsland/
        Clipboard/
        Shelf/
        Cache/
```

Không lưu screenshot binary khổng lồ trực tiếp vào settings.

---

# 42. Repository Abstraction

```swift
protocol ClipboardRepository: Sendable {

    func store(
        _ item: ClipboardItem
    ) async throws

    func search(
        _ query: String
    ) async throws
        -> [ClipboardItem]

    func delete(
        id: UUID
    ) async throws
}
```

Domain không biết SQLite.

---

# 43. Timer Architecture

Store absolute timestamps.

Không giảm:

```text
remaining -= 1
```

mỗi giây.

Model:

```text
startedAt

duration

pausedAt

accumulatedPause
```

Remaining:

```text
duration
-
elapsed time
```

Như vậy sleep/wake không phá timer.

---

# 44. Calendar Architecture

```text
EventKit

 ↓

EventKitCalendarProvider

 ↓

CalendarEvent

 ↓

Calendar Feature

 ↓

Activity Engine
```

`EKEventStore` là entry point chính thức để truy cập events/reminders và cần user authorization.

---

# 45. Calendar Permissions

Không request calendar permission lúc first launch.

Request khi user:

```text
Enable Calendar
```

Permission denied:

```text
feature remains disabled
```

Không liên tục popup lại.

---

# 46. Camera Architecture

```text
AVFoundation

 ↓

CameraProvider

 ↓

Mirror Feature
```

Camera session lifecycle:

```text
Open Mirror
 ↓
Start Capture

Close Mirror
 ↓
Stop Capture
 ↓
Release resources
```

Không giữ camera hoạt động background.

---

# 47. Quick Actions

Protocol:

```swift
protocol QuickAction: Sendable {

    var id: String { get }

    func canExecute(
        context: ActionContext
    ) async -> Bool

    func execute(
        context: ActionContext
    ) async throws
}
```

Feature register actions.

Ví dụ:

```text
Shelf

  → Open

  → Reveal

  → CopyPath

CompressionFeature

  → Compress

AI

  → Summarize
```

---

# 48. Feature Module Contract

```swift
protocol FeatureModule: Sendable {

    var id: FeatureID { get }

    func start() async throws

    func stop() async
}
```

Feature owns:

```text
services

subscriptions

activities

lifecycle
```

---

# 49. Feature Registry

```swift
actor FeatureRegistry {

    private var modules:
        [FeatureID: any FeatureModule]
}
```

Startup:

```text
Read config

 ↓

Resolve enabled features

 ↓

Build features

 ↓

Start

```

Disabled feature:

```text
does not monitor OS

does not allocate resources

does not appear in UI
```

---

# 50. Dependency Injection

Không cần DI framework.

Use composition root:

```swift
@MainActor
final class AppBootstrapper {

    func build()
        -> AppEnvironment
}
```

Dependencies explicit qua initializer.

Ví dụ:

```swift
MediaFeature(
    provider: mediaProvider,
    activities: activityEngine
)
```

Không Service Locator.

---

# 51. App Environment

```swift
@MainActor
final class AppEnvironment {

    let activityEngine:
        ActivityEngine

    let stateMachine:
        IslandStateMachine

    let features:
        FeatureRegistry

    let windowController:
        IslandPanelController
}
```

AppEnvironment chỉ tồn tại ở composition/presentation boundary.

---

# 52. Global Keyboard Shortcut

Recommended:

```text
KeyboardShortcuts
```

Swift Package này hỗ trợ global customizable keyboard shortcuts và dùng MIT license.

Nó được wrap sau:

```swift
protocol GlobalShortcutProviding
```

để không leak dependency vào Application.

---

# 53. Menu Bar Architecture

```text
MenuBarController

 ↓

Application Commands
```

Không gọi trực tiếp:

```text
ShelfRepository
```

từ menu.

Menu gửi:

```text
OpenIslandCommand

OpenSettingsCommand

QuitApplicationCommand
```

---

# 54. Dockless Utility

Production configuration:

```text
LSUIElement = true
```

App chủ yếu sống trong:

```text
Menu Bar
+
Island
```

Settings là standard app window.

---

# 55. Launch at Login

Use native:

```swift
SMAppService.mainApp
```

Apple hỗ trợ API này để cấu hình main application launch at login.

Không cần helper LoginItem app riêng.

---

# 56. Settings

Settings:

```text
General

Island

Appearance

Behavior

Media

Shelf

Clipboard

Timer

Shortcuts

Displays

Permissions

Updates

About
```

Settings storage:

```text
UserDefaults
```

cho simple values.

Structured storage không dùng UserDefaults.

---

# 57. Settings Versioning

```swift
struct AppSettings: Codable {

    let schemaVersion: Int
}
```

Migrations:

```text
V1 → V2 → V3
```

App update không reset preference.

---

# 58. Persistence

Recommended:

```text
UserDefaults
    → settings

SQLite
    → structured metadata/history

File System
    → cached binary/file shelf

Keychain
    → license/token/secret
```

---

# 59. Auto Update Architecture

Use:

```text
Sparkle 2
```

Current research release:

```text
2.9.4
```

Sparkle chuyên cho macOS software updates và có support cho dockless/background application behavior.

Wrap:

```swift
protocol UpdateProviding
```

Presentation không import Sparkle trực tiếp ngoài updater adapter.

---

# 60. Update Pipeline

```text
Git Tag

 ↓

Build Archive

 ↓

Developer ID Sign

 ↓

Notarize

 ↓

Staple

 ↓

DMG

 ↓

Release

 ↓

Sparkle Appcast
```

---

# 61. Direct Distribution Security

Distribution outside Mac App Store vẫn dùng Developer ID + notarization để Gatekeeper xác minh ứng dụng.

Production:

```text
Hardened Runtime = ON
```

Recommended:

```text
App Sandbox = OFF
```

cho utility này, vì direct distribution không bắt buộc sandbox và nhiều filesystem/system integrations sẽ đơn giản hơn; Apple liệt kê sandboxing là “recommended” thay vì bắt buộc cho distribution ngoài Store.

---

# 62. Private API Policy

Private APIs chỉ được đặt tại:

```text
PlatformPrivate/
```

Mỗi private integration phải có:

```text
protocol

adapter

health check

fallback

feature flag

logging

compatibility test
```

Không:

```text
import private framework
```

trong App/Domain/Application.

---

# 63. Private Media Health Check

Startup không assume MediaRemote hoạt động.

```text
MediaRemoteAdapter

 ↓

healthCheck()

 ├── healthy
 │      ↓
 │   enable
 │
 └── failed
        ↓
     fallback
```

Nếu macOS update làm hỏng adapter:

```text
Media unavailable
```

không crash app.

---

# 64. SkyLight Policy

Không dùng trong MVP.

Nếu P2 cần:

```text
Lock Screen Island
```

hoặc system-level windows:

```text
SkyLightAdapter
```

mới được triển khai.

SkyLightWindow xác nhận giải pháp này dùng private macOS SkyLight APIs.

---

# 65. Swift Concurrency Rules

Swift 6 strict concurrency.

Default:

```text
Sendable correctness

Actors for mutable shared state

@MainActor for UI

Structured concurrency
```

Không dùng:

```text
DispatchQueue.main.async
```

khắp codebase nếu Swift concurrency xử lý được.

---

# 66. Main Actor Boundary

Chỉ:

```text
Window

SwiftUI state

AppKit

presentation
```

chạy MainActor.

Không thực hiện:

```text
hash files

database

file copy

thumbnail generation
```

trên MainActor.

---

# 67. Cancellation

Long operations nhận cancellation.

Ví dụ:

```text
File Copy

Thumbnail

Search

Network

AI

Update
```

Feature shutdown:

```text
cancel child tasks
```

---

# 68. Background Tasks

Không tạo detached task tùy tiện.

Feature:

```swift
TaskGroup
```

hoặc lifecycle-owned task.

Khi feature stop:

```text
cancel

await cleanup
```

---

# 69. Logging

Use:

```text
OSLog
```

Subsystem categories:

```text
app

activity

window

media

clipboard

shelf

timer

update

performance

private-api
```

Không log:

```text
clipboard contents

file contents

calendar event body
```

---

# 70. Error Model

Platform errors được map thành typed application errors.

Ví dụ:

```swift
enum ShelfError: Error {

    case fileNotFound

    case permissionDenied

    case copyFailed

    case invalidItem
}
```

Không để random:

```text
NSError
```

propagate tới SwiftUI.

---

# 71. Crash Isolation

Một feature failure không được crash application.

Boundary:

```text
Media error
    ↓
disable Media

Shelf still works

Clipboard still works
```

Private integrations có isolation mạnh nhất.

---

# 72. Performance Rule

Không polling nếu có event.

Exceptions:

```text
NSPasteboard.changeCount
```

vì không có event phù hợp cho clipboard history use case.

Polling phải:

```text
low frequency

feature-scoped

cancelable
```

---

# 73. Resource Lifecycle

Mọi service phải có ownership rõ.

Ví dụ:

```text
Camera → Mirror Feature

Clipboard Timer → Clipboard Feature

Media process → Media Feature

Display observer → Windowing
```

Không global singleton tự sống vĩnh viễn nếu không cần.

---

# 74. Testing Framework

Use:

```text
Swift Testing
```

cho:

```text
Domain

Application

Feature logic
```

Xcode đã tích hợp Swift Testing trong toolchain hiện đại của Apple.

Use XCTest/XCUITest nơi cần UI/system integration.

---

# 75. Domain Tests

Bắt buộc:

```text
Activity priority

Activity expiration

Activity interruption

Activity restoration

Island transitions

Timer calculations

Clipboard dedup

Shelf storage modes
```

Không cần launch macOS UI.

---

# 76. Architecture Tests

Validate package dependency graph.

Forbidden:

```text
Domain → AppKit

Domain → SwiftUI

Application → AppKit

Feature.Media → Feature.Shelf

Feature.Shelf → Feature.Clipboard
```

CI fail nếu dependency sai.

---

# 77. Platform Tests

Test trên real macOS runner/device:

```text
notch detection

non-notch display

external display

display disconnect

NSPanel focus

drag/drop

clipboard

MediaRemote

login item
```

---

# 78. Media Compatibility Matrix

CI/manual compatibility:

```text
Apple Music

Spotify

Safari media

Chrome media

YouTube

VLC
```

Media failure không được crash.

---

# 79. Display Compatibility Matrix

Test:

```text
MacBook notch only

MacBook + external monitor

external monitor primary

clamshell

different scaling

multiple Spaces

fullscreen app
```

---

# 80. Sleep/Wake Testing

Scenarios:

```text
Timer running
 ↓
Sleep 10 min
 ↓
Wake
 ↓
Timer remains correct
```

```text
Media playing
 ↓
Sleep
 ↓
Wake
 ↓
Media provider reconnects
```

---

# 81. UI Performance Tests

Repeated:

```text
1000 expand/collapse

1000 activity switches

100 file drops

100 clipboard captures
```

Observe:

```text
CPU

memory

task count

file handles

animation frames
```

---

# 82. Build Profiles

Configuration:

```text
Config/

default.json

lite.json

pro.json

customer-a.json
```

Example:

```json
{
  "features": {
    "media": true,
    "shelf": true,
    "clipboard": false,
    "timer": true
  }
}
```

No customer source fork.

---

# 83. Release Build

Architectures:

```text
arm64

x86_64
```

Decision:

MVP nên build Universal Binary nếu dependencies hỗ trợ.

Có thể chuyển sang Apple Silicon-only trong tương lai nếu telemetry/product data chứng minh Intel support không còn đáng chi phí QA.

---

# 84. Release Script

```text
scripts/

build-release.sh

sign.sh

notarize.sh

create-dmg.sh

publish-appcast.sh
```

Release phải reproducible.

Không manual signing từng component.

---

# 85. Notarization Pipeline

Conceptual:

```text
xcodebuild archive

 ↓

Developer ID export

 ↓

notarytool submit

 ↓

stapler staple

 ↓

verify
```

Apple mô tả notarization là việc Apple scan Developer-ID-signed software trước khi phân phối ngoài Mac App Store.

---

# 86. CI/CD

Pipeline:

```text
Format

 ↓

SwiftLint/static analysis

 ↓

Build

 ↓

Swift Tests

 ↓

Architecture Tests

 ↓

Integration Tests

 ↓

Release Archive

 ↓

Sign

 ↓

Notarize

 ↓

DMG

 ↓

Publish
```

---

# 87. ADR

Architecture decisions:

```text
docs/adr/

0001-native-swiftui-appkit.md

0002-macos14-minimum.md

0003-direct-distribution.md

0004-nspanel-island.md

0005-activity-engine.md

0006-mediaremote-isolation.md

0007-no-skylight-mvp.md

0008-feature-modules.md

0009-sparkle.md

0010-clipboard-polling.md
```

---

# 88. Coding Principles

Required:

```text
SOLID

KISS

YAGNI

Composition over inheritance

Protocol at architectural boundaries

Value types by default

Actors for shared mutable state

Explicit dependencies
```

Không tạo protocol chỉ vì muốn “Clean”.

Ví dụ không cần:

```text
IStringService

UUIDFactoryBuilderProvider
```

Clean Architecture:

> Dependency direction.

Không phải:

> Maximum number of interfaces.

---

# 89. First Technical Spike

Trước tất cả business features:

```text
Detect screen

 ↓

Detect notch

 ↓

Create NSPanel

 ↓

Position at notch

 ↓

Passive focus

 ↓

Hover

 ↓

Spring expand

 ↓

Interactive mode

 ↓

Collapse

 ↓

External monitor

 ↓

Display disconnect
```

Nếu spike này chưa hoàn thành:

không phát triển Shelf.

---

# 90. First Vertical Slice

Sau Window Spike:

```text
Media Provider

 ↓

MediaSnapshot

 ↓

Media Feature

 ↓

Activity

 ↓

Activity Engine

 ↓

IslandViewModel

 ↓

SwiftUI Island

 ↓

NSPanel
```

Acceptance:

```text
Spotify starts

 ↓

Island shows media

 ↓

Track changes

 ↓

metadata updates

 ↓

play/pause works

 ↓

Spotify stops

 ↓

Island returns idle
```

---

# 91. Milestone Plan

## M0 Foundation

```text
Xcode project

Swift packages

CI

logging

configuration

architecture boundaries
```

## M1 Window Engine

```text
NSScreen

NotchGeometry

NSPanel

multi-display

focus

SwiftUI shell
```

## M2 Island Engine

```text
StateMachine

ActivityEngine

animations

navigation
```

## M3 Media

```text
MediaRemote adapter

metadata

controls

artwork
```

## M4 Shelf

```text
drag/drop

storage

thumbnail

Quick Look

share
```

## M5 Clipboard

```text
monitor

persistence

search

privacy
```

## M6 Timer

```text
timer engine

activity

UI
```

## M7 Productization

```text
Settings

Menu Bar

Shortcuts

Login Item

Sparkle

DMG
```

## M8 Hardening

```text
performance

permissions

sleep/wake

multiple displays

accessibility

private API fallback
```

---

# 92. Final Architecture

```text
                      macOS
                        │
           ┌────────────┼────────────┐
           │            │            │
         AppKit      EventKit    AVFoundation
           │            │            │
           └────────────┼────────────┘
                        │
               Platform macOS
                        │
         ┌──────────────┼──────────────┐
         │              │              │
       Media          Shelf        Clipboard
         │              │              │
         └──────────────┼──────────────┘
                        │
                  Features
                        │
                        ▼
                Application Layer
                        │
          ┌─────────────┼─────────────┐
          │             │             │
    ActivityEngine  StateMachine  Commands
          │
          ▼
                     Domain
          │
          ▼
                Presentation State
          │
          ▼
                    SwiftUI
          │
          ▼
                     NSPanel
```

Private branch:

```text
Media Feature
     │
     ▼
MediaSessionProvider
     │
     ├── Public Adapter
     │
     └── PlatformPrivate
             │
             └── MediaRemote
```

Future:

```text
Window Abstraction
      │
      ├── Public NSPanel
      │
      └── SkyLight Adapter
```

---

# 93. Architecture Success Criterion

Một feature mới tốt phải được thêm theo flow:

```text
Create Feature Module

 ↓

Implement Platform Adapter

 ↓

Register Feature

 ↓

Publish Activities

 ↓

Provide SwiftUI View
```

mà không sửa:

```text
ActivityEngine

IslandPanelController

MediaFeature

ShelfFeature
```

Nếu muốn thêm Calendar mà phải sửa 10 module khác:

architecture đang sai.

---

# 94. Technical Definition of Done

Architecture foundation chỉ Done khi:

```text
Swift 6 strict concurrency clean

Zero build warnings

CI green

Notch Mac works

Non-notch Mac works

External display works

NSPanel doesn't steal focus

Interactive focus works

State machine tested

Activity engine tested

Media vertical slice works

No continuous render loop

Clipboard polling isolated

Sleep/wake works

Developer ID build succeeds

Notarization succeeds

DMG installs normally

Sparkle updater works
```

Sau milestone này mới bắt đầu mở rộng feature set.