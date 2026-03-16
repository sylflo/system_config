# Shinkai Lock - Project Plan 🎬🔒

**A themeable, beautiful Wayland lock screen with HTML/CSS/JS support**

> "Building a platform for cinematic lock screens"

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Development Phases](#development-phases)
4. [Resources & Learning](#resources--learning)
5. [Timeline Estimate](#timeline-estimate)

---

## Project Overview

### Vision
A fully customizable Wayland lock screen where users can create themes using web technologies (HTML/CSS/JS), with a plugin system for advanced functionality.

**Security First:** This project uses a two-process architecture to ensure that theme code (untrusted) cannot compromise authentication security (trusted).

### Core Features
- 🔒 Secure screen locking (PAM authentication)
- 🎨 HTML/CSS/JS theming system
- 🔌 Plugin API (Python/Rust)
- 🎬 Default Makoto Shinkai theme
- 📦 Theme marketplace/sharing
- ⚡ Live preview mode
- 🎛️ Theme configuration UI

### Success Criteria
- ✅ Securely locks the screen (no bypasses, no password leaks)
- ✅ Loads and renders HTML/CSS/JS themes safely
- ✅ Beautiful default theme (your current demo)
- ✅ Theme creator can customize without touching core code
- ✅ Works reliably on Hyprland (your daily driver)
- ✅ Documented well enough for others to create themes

---

## 🔐 Security Architecture

### Two-Process Model

```
┌─────────────────────────────────────────┐
│   Core Locker Process (Trusted)         │
│   - ext-session-lock-v1 protocol         │
│   - PAM authentication                   │
│   - GTK Entry widget for password        │
│   - Keyboard input handling              │
│   - Renders password field as overlay    │
└─────────────────────────────────────────┘
              ↕ (IPC - only status messages)
┌─────────────────────────────────────────┐
│   Theme Renderer Process (Sandboxed)    │
│   - WebKit2GTK view                      │
│   - HTML/CSS/JS animations               │
│   - Displays time, music, etc.           │
│   - NO access to keyboard input          │
│   - NO access to password field          │
└─────────────────────────────────────────┘
```

### Key Security Principles

1. **Password Input is Native GTK**
   - The password field is rendered by the core locker process using GTK Entry widget
   - Keyboard input goes directly to GTK, never touches WebKit
   - Theme code cannot see, capture, or intercept password input

2. **WebKit is for Visuals Only**
   - HTML/CSS/JS renders background, animations, decorative elements
   - It's like a video playing behind the lock screen
   - No access to authentication logic

3. **Limited JavaScript API**
   - JS can only access display data (time, music, battery)
   - JS receives unlock event notifications (for animations)
   - JS **cannot** verify passwords or access auth state

4. **Plugin Sandboxing**
   - Plugins run in the trusted core process (they need system access)
   - They provide data to themes via a controlled API
   - Theme JS consumes this data but cannot execute plugin code

### What This Means for Theme Creators

**You can customize:**
- ✅ Background animations, particles, visual effects
- ✅ Layout and positioning of all elements
- ✅ Colors, fonts, styling of password field (via config)
- ✅ Time display, music info, battery status
- ✅ Unlock animations and transitions

**You cannot do:**
- ❌ Create custom HTML input field for password (security risk)
- ❌ Access keyboard input directly (security risk)
- ❌ Verify passwords or bypass auth (security risk)
- ❌ Make network requests or read files (sandboxed)

This keeps your lock screen **both beautiful and secure**.

---

## 🔒 IPC Security Model

### Message Validation

All communication between the core locker and theme renderer must be **strictly validated**:

```python
# Core Locker → Theme Renderer (allowed messages)
ALLOWED_OUTBOUND = {
    'time-update': {'hours': int, 'minutes': int, 'seconds': int},
    'music-update': {'title': str, 'artist': str, 'isPlaying': bool},
    'battery-update': {'level': int, 'charging': bool},
    'unlock-success': {},
    'unlock-failure': {},
    'plugin-data': {'plugin': str, 'data': dict}
}

# Theme Renderer → Core Locker (allowed messages)
ALLOWED_INBOUND = {
    'get-time': {},
    'get-music': {},
    'get-battery': {},
    'get-plugin-data': {'plugin': str},
    'theme-ready': {}
}
```

### Sanitization Rules

1. **Type Checking:** All message fields must match expected types
2. **Whitelist Only:** Reject any message type not in `ALLOWED_*`
3. **Size Limits:** Cap string lengths (e.g., 1KB max per message)
4. **No Code Injection:** Never `eval()` or execute data from messages
5. **Rate Limiting:** Max 100 messages/second from theme renderer

### Example Implementation

```python
def validate_message(msg, direction='inbound'):
    allowed = ALLOWED_INBOUND if direction == 'inbound' else ALLOWED_OUTBOUND

    if msg['type'] not in allowed:
        raise SecurityError(f"Unknown message type: {msg['type']}")

    schema = allowed[msg['type']]
    for key, expected_type in schema.items():
        if key not in msg or not isinstance(msg[key], expected_type):
            raise SecurityError(f"Invalid message format")

    return True
```

**Critical:** The core locker must **never** execute arbitrary code based on theme messages. All IPC is data-only, never code.

---

## 🛡️ WebKit Sandboxing Hardening

### APIs to Explicitly Disable

```python
# In core locker, before loading theme
webkit_settings = webkit_view.get_settings()

# Disable dangerous features
webkit_settings.set_enable_javascript(True)  # We need JS, but...
webkit_settings.set_allow_universal_access_from_file_urls(False)
webkit_settings.set_allow_file_access_from_file_urls(False)
webkit_settings.set_enable_webgl(False)  # No WebGL (GPU attack surface)
webkit_settings.set_enable_webaudio(False)  # No Web Audio
webkit_settings.set_enable_media_stream(False)  # No camera/mic access
webkit_settings.set_enable_media_capabilities(False)
webkit_settings.set_enable_plugins(False)  # No NPAPI plugins
webkit_settings.set_enable_java(False)  # No Java applets
webkit_settings.set_javascript_can_open_windows_automatically(False)
webkit_settings.set_javascript_can_access_clipboard(False)
webkit_settings.set_allow_modal_dialogs(False)

# Network restrictions
webkit_context = webkit_view.get_context()
webkit_context.set_network_proxy_settings(WebKit2.NetworkProxyMode.NO_PROXY)
webkit_context.set_spell_checking_enabled(False)

# Content Security Policy
webkit_view.load_html(theme_html, base_uri="app://shinkai-lock")
# CSP header: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'none';"
```

### JavaScript Globals to Remove

```javascript
// Inject this BEFORE theme loads
delete window.XMLHttpRequest;
delete window.fetch;
delete window.WebSocket;
delete window.localStorage;
delete window.sessionStorage;
delete window.indexedDB;
delete window.open;
delete window.alert;
delete window.confirm;
delete window.prompt;

// Freeze dangerous prototypes
Object.freeze(Function.prototype);
Object.freeze(Object.prototype);
```

### CSP (Content Security Policy)

Set strict CSP headers for theme HTML:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: file:;
  font-src 'self' data:;
  connect-src 'none';
  frame-src 'none';
  object-src 'none';
```

**Note:** `'unsafe-inline'` is needed for theme scripts/styles, but `connect-src 'none'` blocks all network requests.

---

## 🔄 Fallback Mode

### The Problem

If WebKit crashes, the screen must **stay locked** with a way to unlock.

### The Solution

**Plain GTK Fallback UI** - No WebKit, just basic GTK widgets.

```python
class FallbackUI:
    """Emergency fallback if WebKit fails"""

    def __init__(self):
        self.window = Gtk.Window()
        self.window.set_decorated(False)
        self.window.fullscreen()

        # Simple, safe UI
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)

        # Warning message
        warning = Gtk.Label()
        warning.set_markup(
            '<span font="24" foreground="red">⚠️ Theme Failed</span>\n'
            '<span font="16">Enter password to unlock</span>'
        )
        box.append(warning)

        # Password input (native GTK)
        self.password_entry = Gtk.Entry()
        self.password_entry.set_visibility(False)
        self.password_entry.set_placeholder_text("Password")
        self.password_entry.connect('activate', self.on_unlock_attempt)
        box.append(self.password_entry)

        # Unlock button
        unlock_btn = Gtk.Button(label="Unlock")
        unlock_btn.connect('clicked', self.on_unlock_attempt)
        box.append(unlock_btn)

        self.window.set_child(box)
        self.window.present()

    def on_unlock_attempt(self, widget):
        password = self.password_entry.get_text()
        if verify_password(password):
            unlock_session()
        else:
            self.password_entry.set_text("")
            # Show error
```

### When to Trigger Fallback

```python
def monitor_theme_renderer():
    """Watch theme renderer process"""
    while locked:
        if theme_process.poll() is not None:
            # Theme renderer crashed!
            logger.error("Theme renderer crashed, switching to fallback")
            switch_to_fallback_ui()
        time.sleep(0.1)
```

### Fallback Trigger Conditions

1. **WebKit crashes** - Process exits unexpectedly
2. **Theme hangs** - No response for 5+ seconds
3. **Resource exhaustion** - CPU > 80% for 10+ seconds
4. **Manual trigger** - User presses emergency key combo (Ctrl+Alt+F)

**Critical:** Fallback UI uses **zero WebKit**, only GTK. Cannot crash.

---

## 🔌 Plugin Isolation Strategy

### The Problem

Plugins run in the trusted core process with full system access. A buggy plugin could:
- Crash the entire lock screen
- Cause memory leaks
- Block the event loop
- Expose security vulnerabilities

### The Solution

**Thread-Based Isolation** - Run each plugin in a separate thread with monitoring.

```python
import threading
import queue
from contextlib import contextmanager

class IsolatedPlugin:
    """Wrapper that runs plugin in isolated thread"""

    def __init__(self, plugin_class, timeout=5.0):
        self.plugin = plugin_class()
        self.timeout = timeout
        self.result_queue = queue.Queue()

    def get_data(self):
        """Call plugin.get_data() with timeout protection"""
        def worker():
            try:
                result = self.plugin.get_data()
                self.result_queue.put(('success', result))
            except Exception as e:
                self.result_queue.put(('error', str(e)))

        thread = threading.Thread(target=worker, daemon=True)
        thread.start()
        thread.join(timeout=self.timeout)

        if thread.is_alive():
            # Plugin hung, return cached data or None
            return {'error': 'Plugin timeout'}

        try:
            status, result = self.result_queue.get_nowait()
            if status == 'success':
                return result
            else:
                logger.error(f"Plugin error: {result}")
                return None
        except queue.Empty:
            return None
```

### Plugin Health Monitoring

```python
class PluginMonitor:
    """Monitor plugin health and performance"""

    def __init__(self):
        self.plugin_stats = {}

    def track_call(self, plugin_name, duration, success):
        if plugin_name not in self.plugin_stats:
            self.plugin_stats[plugin_name] = {
                'calls': 0,
                'failures': 0,
                'total_time': 0.0
            }

        stats = self.plugin_stats[plugin_name]
        stats['calls'] += 1
        stats['total_time'] += duration

        if not success:
            stats['failures'] += 1

        # Disable plugin if too many failures
        failure_rate = stats['failures'] / stats['calls']
        if failure_rate > 0.5 and stats['calls'] > 5:
            logger.warning(f"Disabling plugin {plugin_name} (high failure rate)")
            disable_plugin(plugin_name)
```

### Resource Limits

```python
# Limit plugin execution time
PLUGIN_TIMEOUT = 5.0  # seconds

# Limit plugin data size
MAX_PLUGIN_DATA_SIZE = 1024 * 100  # 100KB

# Limit plugin call frequency
PLUGIN_RATE_LIMIT = 10  # calls per second
```

### Future Enhancement: Process Isolation

For maximum safety, run plugins in separate processes (Phase 6+):

```python
import multiprocessing

class ProcessIsolatedPlugin:
    """Run plugin in separate process (future enhancement)"""

    def __init__(self, plugin_module):
        self.process = None
        self.queue = multiprocessing.Queue()

    def get_data(self):
        # Send request to plugin process
        self.queue.put({'type': 'get_data'})

        # Wait for response (with timeout)
        try:
            result = self.queue.get(timeout=5.0)
            return result
        except queue.Empty:
            # Plugin process hung, restart it
            self.restart_plugin()
            return None
```

**Note:** Thread isolation for MVP, process isolation for production hardening.

---

## 📊 Performance Budget

### Target Metrics

**Idle State (lock screen shown, no animations):**
- CPU: < 1%
- RAM: < 50 MB
- GPU: 0%

**Active Animations (particles, transitions):**
- CPU: < 5-10%
- RAM: < 100 MB
- GPU: < 20% (if hardware accelerated)

**Unlock Time:**
- Correct password → unlock: < 500ms
- Failed password → error feedback: < 100ms

**Theme Load Time:**
- Simple theme: < 1 second
- Complex theme (Shinkai): < 2 seconds

### Performance Testing

```python
import psutil
import time

class PerformanceMonitor:
    """Monitor lock screen performance"""

    def __init__(self):
        self.process = psutil.Process()
        self.start_time = time.time()

    def get_metrics(self):
        return {
            'cpu_percent': self.process.cpu_percent(interval=1.0),
            'memory_mb': self.process.memory_info().rss / 1024 / 1024,
            'uptime': time.time() - self.start_time
        }

    def check_budget(self):
        metrics = self.get_metrics()

        if metrics['cpu_percent'] > 15:
            logger.warning(f"CPU usage high: {metrics['cpu_percent']}%")

        if metrics['memory_mb'] > 150:
            logger.warning(f"Memory usage high: {metrics['memory_mb']} MB")

        return metrics
```

### Optimization Strategies

1. **Lazy Loading:** Don't load theme assets until needed
2. **RequestAnimationFrame:** Use RAF for animations, not setInterval
3. **CSS Transforms:** Use GPU-accelerated transforms (translate, scale)
4. **Debouncing:** Limit plugin data refresh rate
5. **Image Optimization:** Compress wallpapers, use WebP format
6. **Virtual Rendering:** Only render visible elements

### Performance Success Criteria

- ✅ Can run for 24+ hours without memory leaks
- ✅ Stays responsive on low-end hardware (< 4GB RAM)
- ✅ Doesn't drain laptop battery significantly
- ✅ Works smoothly on 4K displays
- ✅ Multi-monitor setups don't degrade performance

---

## 🧪 Testing Matrix

### Compositor Compatibility

Test on multiple Wayland compositors early:

| Compositor | Priority | Test Phase |
|------------|----------|------------|
| Hyprland   | HIGH (your daily driver) | Phase 1+ |
| Sway       | HIGH (reference impl) | Phase 2 |
| GNOME      | MEDIUM | Phase 3 |
| KDE Plasma | MEDIUM | Phase 3 |
| River      | LOW | Phase 6 |
| Wayfire    | LOW | Phase 6 |

### Multi-Monitor Testing

- Single monitor (1920x1080)
- Dual monitor (different resolutions)
- Triple monitor
- Mixed refresh rates (60Hz + 144Hz)
- Monitor hotplug (disconnect/reconnect while locked)

### Hardware Testing

- **Low-end:** 4GB RAM, integrated GPU
- **Mid-range:** 8GB RAM, discrete GPU
- **High-end:** 16GB+ RAM, modern GPU
- **Laptop:** Battery impact testing

### Security Testing

- [ ] Attempt to escape lock (VT switching, Alt+Tab, etc.)
- [ ] Attempt to crash theme renderer
- [ ] Attempt to inject malicious IPC messages
- [ ] Attempt to access password via theme JS
- [ ] Attempt to bypass authentication
- [ ] Fuzz test plugin API
- [ ] Memory corruption testing

### User Testing

- [ ] Install and configure by non-technical user
- [ ] Create custom theme without programming experience
- [ ] Recover from broken theme
- [ ] Unlock with accessibility features (screen reader)

---

## Tech Stack

### Core Locker Process (Trusted)
- **Language:** Python (→ Rust later for performance)
  - Start with Python (you know it from desktop-ui)
  - Migrate critical parts to Rust in Phase 5+
- **Authentication:** python-pam
- **Wayland Protocol:** ext-session-lock-v1
- **UI Toolkit:** GTK4 (for password input field)
- **IPC:** D-Bus or Unix sockets (to communicate with renderer)

### Theme Renderer Process (Sandboxed)
- **Renderer:** WebKit2GTK (PyGObject)
- **Theme Format:** HTML/CSS/JavaScript bundles
- **API Bridge:** JavaScript ↔ Python (via WebKit message handlers)
- **Sandboxing:** Disabled network, file access, dangerous APIs

### Password Field Styling
- **Input Widget:** GTK Entry (native, secure)
- **Styling Config:** theme.json metadata (colors, position, size)
- **Overlay:** GTK renders password field on top of WebKit view

### Distribution
- **Nix Package:** You're already using NixOS!
- **Config Location:** `~/.config/shinkai-lock/`
- **Themes Location:** `~/.config/shinkai-lock/themes/`

---

## Development Phases

## 📚 Phase 0: Research & Learning (Week 1-2)
**Goal:** Understand the fundamentals before coding

### Tasks:
- [ ] **Learn PAM basics**
  - Read: [Linux PAM Documentation](https://www.linux-pam.org/Linux-PAM-html/)
  - Study: How swaylock/hyprlock use PAM
  - Experiment: Simple Python PAM auth test

- [ ] **Understand Wayland session locking**
  - Read: [ext-session-lock-v1 protocol](https://wayland.app/protocols/ext-session-lock-v1)
  - Study: How swaylock-effects implements it
  - Find: Python Wayland libraries (pywayland)

- [ ] **Explore WebKit2GTK**
  - Read: [WebKit2GTK Python docs](https://lazka.github.io/pgi-docs/WebKit2-4.1/)
  - Study: Your own desktop-ui code (you already use GTK!)
  - Test: Simple WebKit window loading HTML

- [ ] **Research existing solutions**
  - Clone & study: gtklock, swaylock, hyprlock source
  - Understand: What they do well, what they lack
  - List: Features you want that they don't have

### Deliverables:
- ✅ Notes document with learnings
- ✅ Simple PAM test script (authenticate user)
- ✅ Simple WebKit test (load HTML in window)
- ✅ List of technical challenges identified

### Resources:
- [Wayland Book](https://wayland-book.com/)
- [Python PAM module](https://github.com/FirefighterBlu3/python-pam)
- [swaylock source](https://github.com/swaywm/swaylock)
- [gtklock source](https://github.com/jovanlanik/gtklock)

---

## 🔒 Phase 1: Minimal Viable Lock Screen (Week 3-4)
**Goal:** Create a basic working lock screen (no theming yet)

### Tasks:
- [ ] **Project setup**
  - Create Git repo: `shinkai-lock`
  - Set up Python project structure
  - Create Nix development shell
  - Add dependencies (PyGObject, python-pam, etc.)

- [ ] **Implement PAM authentication**
  ```python
  # Simple password verification
  def verify_password(username, password):
      # Use python-pam to verify
      pass
  ```

- [ ] **Create basic GTK window**
  - Fullscreen window on all monitors
  - Capture all input (no escape!)
  - Simple password input field
  - "Unlock" button

- [ ] **Implement session lock protocol**
  - Use ext-session-lock-v1 via pywayland
  - Lock all screens
  - Prevent switching to other apps
  - Test on Hyprland

- [ ] **Add basic security**
  - Don't show password (use password field)
  - Rate limiting (prevent brute force)
  - Lock after N failed attempts
  - Proper cleanup on unlock

### Deliverables:
- ✅ Working lock screen (ugly but functional!)
- ✅ Can lock and unlock via password
- ✅ No way to escape/bypass
- ✅ Works on your Hyprland setup

### Success Criteria:
- You can lock your screen and ONLY unlock with password
- No crashes, no bypasses, no security holes
- Reliable enough for daily use (even if ugly)

### File Structure:
```
shinkai-lock/
├── shinkai_lock/
│   ├── __init__.py
│   ├── main.py           # Entry point
│   ├── auth.py           # PAM authentication
│   ├── lock.py           # Session lock protocol
│   └── window.py         # GTK window
├── flake.nix             # Nix package
├── README.md
└── pyproject.toml        # Python project config
```

---

## 🎨 Phase 2: Add WebKit Rendering (Week 5-6)
**Goal:** Add WebKit for visual theming while keeping password input secure

### Tasks:
- [ ] **Integrate WebKit2GTK (as background layer)**
  - Add WebKit2.WebView to your GTK window
  - Load a simple HTML file
  - Make it fullscreen, but behind password input

- [ ] **Create static HTML background**
  - Simple HTML with time display
  - Background gradients/animations
  - Basic CSS styling (Shinkai aesthetic!)
  - No password input in HTML (security!)

- [ ] **Keep password input as GTK Entry**
  - GTK Entry widget overlaid on top of WebKit
  - Position/style it to match theme aesthetic
  - Keyboard input goes directly to GTK (secure!)

- [ ] **Bridge WebKit ↔ Python (with IPC validation)**
  - Python sends time/date to WebKit for display
  - WebKit notifies Python of UI events (animations)
  - WebKit **never** sees password input
  - Use WebKit2 message handlers for IPC
  - Implement message validation (whitelist, type checking)
  - Add rate limiting (100 messages/second max)

- [ ] **Harden WebKit sandbox**
  - Disable WebGL, WebAudio, media streams
  - Remove fetch(), XMLHttpRequest, WebSocket
  - Set Content Security Policy
  - Block network proxy settings
  - Disable modal dialogs and window.open
  - See "WebKit Sandboxing Hardening" section for full checklist

- [ ] **Implement fallback mode**
  - Create plain GTK fallback UI (no WebKit)
  - Monitor theme renderer process health
  - Auto-switch to fallback if WebKit crashes
  - Test manual trigger (Ctrl+Alt+F)
  - Ensure screen stays locked on crash

- [ ] **Add multiple monitor support**
  - Detect all monitors
  - Create WebView + GTK overlay per monitor
  - Load same HTML on each
  - Test monitor hotplug scenarios

- [ ] **Test thoroughly**
  - Password input only captured by GTK
  - WebKit cannot access keyboard input
  - IPC messages are validated
  - Fallback mode works reliably
  - Works with multiple monitors
  - No security regressions
  - Test on Sway compositor (reference implementation)

### Deliverables:
- ✅ Lock screen with WebKit background + GTK password field
- ✅ HTML/CSS can be edited separately from Python
- ✅ Password input is 100% native GTK (secure)
- ✅ Visual theming works beautifully
- ✅ Still secure, no bypasses

### Success Criteria:
- You can style the background/animations by editing HTML/CSS
- Your Makoto Shinkai aesthetic can start to appear!
- Password field is native but positioned/styled to fit theme
- Still fully functional and secure

### Example HTML (Background Only):
```html
<!-- themes/default/index.html -->
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      margin: 0;
      height: 100vh;
      background: linear-gradient(
        135deg,
        rgba(26, 35, 50, 0.9) 0%,
        rgba(43, 62, 80, 0.7) 50%,
        rgba(26, 35, 50, 0.8) 100%
      );
      font-family: Inter;
      color: white;
    }
    #time {
      position: absolute;
      top: 20%;
      left: 3%;
      font-size: 150px;
      font-weight: 300;
    }
  </style>
</head>
<body>
  <div id="time">17:46</div>
  <!-- No password input here! GTK handles that -->

  <script>
    // Update time from Python
    window.addEventListener('message', (event) => {
      if (event.data.type === 'time-update') {
        document.getElementById('time').textContent = event.data.time;
      }
    });
  </script>
</body>
</html>
```

### Python Overlay Example:
```python
# GTK password field overlaid on WebKit
password_entry = Gtk.Entry()
password_entry.set_visibility(False)  # Hide password
password_entry.set_placeholder_text("Enter password...")

# Position based on theme config
overlay = Gtk.Overlay()
overlay.add(webkit_view)  # WebKit background
overlay.add_overlay(password_entry)  # GTK password field on top
```

---

## 🎭 Phase 3: Theme System (Week 7-9)
**Goal:** Support multiple themes, load them dynamically

### Tasks:
- [ ] **Design theme format**
  ```
  ~/.config/shinkai-lock/themes/
    makoto-shinkai/
      theme.json        # Metadata
      index.html        # Main HTML
      style.css         # Styling
      script.js         # Animations
      assets/           # Images, fonts, etc.
  ```

- [ ] **Create theme.json spec**
  ```json
  {
    "name": "Makoto Shinkai Dreams",
    "author": "sylflo",
    "version": "1.0.0",
    "description": "Cinematic lock screen",
    "entry": "index.html",
    "passwordField": {
      "position": { "x": "3%", "y": "50%" },
      "size": { "width": "20%", "height": "7%" },
      "alignment": { "horizontal": "left", "vertical": "center" },
      "colors": {
        "text": "rgba(255, 255, 255, 1.0)",
        "background": "rgba(0, 0, 0, 0.0)",
        "border": "rgba(255, 255, 255, 1.0)",
        "placeholder": "rgba(138, 153, 164, 1.0)"
      },
      "font": {
        "family": "Inter Light",
        "size": 24
      },
      "border": {
        "width": 3,
        "radius": 15
      }
    },
    "settings": {
      "particleCount": { "type": "number", "default": 50 },
      "overlayOpacity": { "type": "number", "default": 70 }
    }
  }
  ```

- [ ] **Implement theme loader**
  - Scan themes directory
  - Parse theme.json
  - Load selected theme's HTML
  - Handle missing/broken themes gracefully

- [ ] **Add theme selector**
  - CLI argument: `--theme makoto-shinkai`
  - Config file: `~/.config/shinkai-lock/config.toml`
  - Fallback to default theme if not found

- [ ] **Port your HTML demo as default theme**
  - Take your `shinkai-movies-demo-v4.html`
  - Split into theme structure
  - Add wallpaper/quote config system
  - Make it the built-in default

- [ ] **Create second example theme**
  - Minimalist theme (for testing variety)
  - Different aesthetic (proves system works)
  - Document how it was created

### Deliverables:
- ✅ Theme system that loads different HTML/CSS/JS
- ✅ Your Shinkai demo as the default theme
- ✅ At least one alternative theme
- ✅ Users can create themes by adding folders

### File Structure:
```
~/.config/shinkai-lock/
├── config.toml           # User config
├── themes/
│   ├── makoto-shinkai/   # Your default theme
│   │   ├── theme.json
│   │   ├── index.html
│   │   ├── style.css
│   │   ├── script.js
│   │   └── wallpapers/
│   └── minimal/          # Simple alternative
│       └── ...
```

---

## 🚀 Phase 4: JavaScript API (Week 10-12)
**Goal:** Provide a safe JS API for themes (display data only)

### Tasks:
- [ ] **Design the API surface**
  ```javascript
  window.ShinkaiiLock = {
    // Time & Date (for display)
    getTime() → { hours, minutes, seconds }
    getDate() → { day, month, year, weekday }

    // System Info (for display)
    getMusic() → { title, artist, album, isPlaying }
    getBattery() → { level, charging, timeRemaining }

    // Auth Events (for animations - NO password access!)
    on('unlock-success', callback)  // Play success animation
    on('unlock-failure', callback)  // Shake input field
    on('theme-loaded', callback)    // Initialize theme

    // Plugin Data (from trusted plugins)
    getPluginData(pluginName) → Promise<data>

    // Theme Config (user preferences)
    getSetting(key) → value
    setSetting(key, value) → Promise<void>
  }
  ```

  **Security Note:** No `verify(password)` function! Password verification happens in the core locker process. JavaScript only receives success/failure notifications.

- [ ] **Implement API injection**
  - Use `webkit_user_content_manager_add_script()`
  - Inject API before page loads
  - Create Python ↔ JS message bridge

- [ ] **Implement each API method**
  - Time/Date: Simple Python datetime
  - Music: Use playerctl via subprocess
  - Battery: Read from `/sys/class/power_supply/`
  - Auth: Already have PAM integration

- [ ] **Add security restrictions**
  - Sandbox: No network access
  - Sandbox: No file system access
  - Whitelist: Only allow specific JS APIs
  - Timeout: Kill infinite loops
  - Resource limits: Max CPU/memory

- [ ] **Test with animations**
  - Particles system using API
  - Live clock updates
  - Music visualizer
  - Performance monitoring

### Deliverables:
- ✅ Documented JavaScript API
- ✅ Themes can access time, music, etc.
- ✅ Themes can trigger unlock
- ✅ Properly sandboxed (safe)
- ✅ Example theme using all APIs

### Example Theme Using API:
```javascript
// In theme's script.js
async function init() {
  // Update time every second
  setInterval(async () => {
    const time = await ShinkaiiLock.getTime();
    document.getElementById('clock').textContent =
      `${String(time.hours).padStart(2, '0')}:${String(time.minutes).padStart(2, '0')}`;
  }, 1000);

  // Get current music
  const music = await ShinkaiiLock.getMusic();
  if (music.isPlaying) {
    showMusicInfo(music.title, music.artist);
  }

  // Get plugin data (e.g., weather)
  const weather = await ShinkaiiLock.getPluginData('weather');
  if (weather) {
    document.getElementById('weather').textContent =
      `${weather.temperature} ${weather.condition}`;
  }

  // Listen for unlock events (for animations only!)
  ShinkaiiLock.on('unlock-success', () => {
    // Play success animation (fade out, particles, etc.)
    playSuccessAnimation();
  });

  ShinkaiiLock.on('unlock-failure', () => {
    // Shake effect, flash red, etc.
    shakePasswordFieldArea();
  });
}

// Theme can trigger visual effects but cannot access password
function shakePasswordFieldArea() {
  // Animate the area around the password field
  // (The password field itself is GTK, but we can animate decorations)
  const decorator = document.getElementById('password-decorator');
  decorator.classList.add('shake');
  setTimeout(() => decorator.classList.remove('shake'), 500);
}
```

---

## 🔌 Phase 5: Plugin System (Week 13-15)
**Goal:** Allow extending functionality via plugins

### Plugin vs Theme: What's the Difference?

**Themes** = Frontend (Sandboxed)
- HTML/CSS/JS that runs in WebKit (untrusted sandbox)
- **Cannot:** Make network requests, read files, access system APIs
- **Can:** Display data, animate, respond to events
- **Example:** A theme can display weather, but can't fetch it

**Plugins** = Backend (Trusted)
- Python code that runs in the core locker process
- **Can:** Make network requests, read files, call system APIs, run heavy computations
- **Cannot:** Access password or auth state directly
- **Example:** A plugin fetches weather data and provides it to themes

**Why both?**
- Themes are sandboxed for security (can't steal passwords)
- Plugins run with full permissions (can do real work)
- Plugins provide "backend services" that themes consume
- Like npm packages for your lock screen!

**Example Flow:**
```
Weather Plugin (Python, trusted)
    ↓ fetches from API
    ↓ returns { temp: "72°F", condition: "Sunny" }
    ↓
Core Locker exposes via API
    ↓
Theme (JS, sandboxed) calls getPluginData('weather')
    ↓ receives data
    ↓ displays it beautifully
```

### Tasks:
- [ ] **Design plugin architecture**
  ```
  ~/.config/shinkai-lock/plugins/
    weather/
      plugin.py         # Python plugin
      config.json       # Metadata
  ```

- [ ] **Create plugin API**
  ```python
  class ShinkaiiPlugin:
      def on_lock(self): pass        # Called when screen locks
      def on_unlock(self): pass      # Called when screen unlocks
      def get_data(self):            # Expose data to themes
          return { "key": "value" }
  ```

- [ ] **Implement plugin loader with isolation**
  - Scan plugins directory
  - Load Python modules safely
  - Wrap each plugin in IsolatedPlugin class (thread-based)
  - Set timeout limits (5 seconds per call)
  - Monitor plugin health and performance
  - Call plugin hooks at appropriate times
  - Handle plugin crashes gracefully (don't crash core locker)
  - Implement automatic plugin disabling (high failure rate)
  - Add resource limits (data size, call frequency)

- [ ] **Create example plugins**

  **Weather Plugin:**
  ```python
  # ~/.config/shinkai-lock/plugins/weather/plugin.py
  import requests

  class WeatherPlugin:
      def get_data(self):
          # Plugin runs in trusted process - CAN make network calls
          response = requests.get('https://api.weather.com/...')
          return {
              "temperature": "72°F",
              "condition": "Partly Cloudy",
              "location": "Tokyo"
          }
  ```

  **Quote Plugin:**
  ```python
  # ~/.config/shinkai-lock/plugins/quotes/plugin.py
  import random, json

  class QuotePlugin:
      def __init__(self):
          # Plugin CAN read files from disk
          with open('quotes.json') as f:
              self.quotes = json.load(f)

      def get_data(self):
          quote = random.choice(self.quotes)
          return {
              "text": quote["text"],
              "author": quote["author"]
          }
  ```

  **Anime Wallpaper Plugin:**
  ```python
  # ~/.config/shinkai-lock/plugins/anime-walls/plugin.py
  import os, random

  class AnimeWallpaperPlugin:
      def on_lock(self):
          # Called every time screen locks
          # Plugin CAN access file system
          walls = os.listdir('/home/user/anime-wallpapers')
          self.current_wall = random.choice(walls)

      def get_data(self):
          return {
              "wallpaper": f"/home/user/anime-wallpapers/{self.current_wall}",
              "title": self.current_wall.replace('.jpg', '')
          }
  ```

- [ ] **Expose plugin data to themes**
  ```javascript
  // In theme's script.js
  // Theme is sandboxed - CANNOT fetch weather itself
  // But CAN consume data from weather plugin
  const weather = await ShinkaiiLock.getPluginData('weather');
  document.getElementById('weather').textContent =
    `${weather.temperature} in ${weather.location}`;

  const quote = await ShinkaiiLock.getPluginData('quotes');
  document.getElementById('quote').innerHTML =
    `"${quote.text}" - ${quote.author}`;

  const wallpaper = await ShinkaiiLock.getPluginData('anime-walls');
  document.body.style.backgroundImage = `url(${wallpaper.wallpaper})`;
  ```

### Deliverables:
- ✅ Plugin system that works
- ✅ At least 2 example plugins
- ✅ Themes can use plugin data
- ✅ Documentation for plugin developers

---

## 🎯 Phase 6: Live Preview & Theme Tools (Week 16-17)
**Goal:** Make theme development easy

### Tasks:
- [ ] **Create preview mode**
  - `shinkai-lock --preview` - Run without locking
  - Hot reload on file changes
  - Windowed mode (not fullscreen)
  - Fake password (always succeeds)

- [ ] **Theme generator CLI**
  ```bash
  shinkai-lock create-theme my-awesome-theme
  # Creates template with boilerplate
  ```

- [ ] **Theme validator**
  ```bash
  shinkai-lock validate-theme ./my-theme/
  # Checks theme.json, required files, etc.
  ```

- [ ] **Settings GUI**
  - GTK app to configure themes
  - Live preview window
  - Theme switcher
  - Setting adjustments (sliders, colors, etc.)

### Deliverables:
- ✅ Easy to test themes without locking
- ✅ Template generator for new themes
- ✅ Validation tool
- ✅ User-friendly settings app

---

## 📦 Phase 7: Polish & Release (Week 18-20)
**Goal:** Make it production-ready

### Tasks:
- [ ] **Documentation**
  - README with screenshots
  - Theme creation guide
  - Plugin development guide
  - API reference
  - Installation instructions

- [ ] **Packaging**
  - Nix package (flake.nix)
  - AUR package (PKGBUILD)
  - Maybe: Flatpak?

- [ ] **Example themes**
  - Makoto Shinkai (your default)
  - Minimalist
  - Cyberpunk
  - Nord theme
  - Catppuccin theme

- [ ] **Testing**
  - Test on different Wayland compositors
  - Test on different hardware
  - Test multi-monitor setups
  - Security audit (ask for reviews)

- [ ] **Community setup**
  - GitHub repo
  - Contributing guidelines
  - Issue templates
  - Discord/Matrix?
  - Reddit post / announcement

- [ ] **Theme repository**
  - GitHub repo for sharing themes
  - Submission guidelines
  - Theme gallery website?

### Deliverables:
- ✅ Public GitHub release
- ✅ Packaged for Nix (at minimum)
- ✅ Complete documentation
- ✅ 5+ example themes
- ✅ Community ready to share themes!

---

## 📚 Resources & Learning

### Wayland & Lock Screens
- [Wayland Book](https://wayland-book.com/) - Comprehensive Wayland guide
- [ext-session-lock-v1 spec](https://wayland.app/protocols/ext-session-lock-v1)
- [swaylock source code](https://github.com/swaywm/swaylock) - Reference implementation
- [gtklock source code](https://github.com/jovanlanik/gtklock) - GTK-based example

### PAM Authentication
- [Linux-PAM Documentation](https://www.linux-pam.org/Linux-PAM-html/)
- [python-pam](https://github.com/FirefighterBlu3/python-pam) - Python bindings
- [PAM Tutorial](https://www.linux.com/news/understanding-pam/)

### WebKit2GTK
- [WebKit2GTK API Docs](https://webkitgtk.org/reference/webkit2gtk/stable/index.html)
- [PyGObject WebKit2 Docs](https://lazka.github.io/pgi-docs/WebKit2-4.1/)
- [WebKit2GTK Tutorial](https://github.com/TingPing/webkit2gtk-python-webextension-tutorial)

### GTK4 & Layer Shell
- You already know this from desktop-ui! ✅
- [gtk-layer-shell](https://github.com/wmww/gtk-layer-shell)

### Security Resources
- [OWASP Secure Coding](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [Sandboxing JavaScript](https://blog.risingstack.com/writing-a-javascript-framework-sandboxed-code-evaluation/)

---

## ⏱️ Timeline Estimate

### Minimal Viable Product (Phases 0-3)
**10-13 weeks** - Basic themeable lock screen (includes buffer for WebKit security)

### Full Featured (Phases 0-5)
**17-20 weeks** - With plugins and API (includes buffer for plugin isolation)

### Polished Release (Phases 0-7)
**24-28 weeks** - Production ready, documented, packaged (includes security audit time)

### Reality Check:
- This is **part-time** estimate (10-15 hrs/week)
- **Full-time** would be ~8-10 weeks for MVP
- Some phases may be faster (you already know GTK!)
- Some may be slower (PAM/Wayland/security hardening are new to you)
- **Added 4-6 weeks buffer** for debugging security, Wayland quirks, and compositor testing

### Phase-by-Phase Timeline:
- **Phase 0 (Weeks 1-2):** Research & Learning
- **Phase 1 (Weeks 3-4):** Basic lock screen
- **Phase 2 (Weeks 5-8):** WebKit + hardening + fallback ⚠️ *Extended for security*
- **Phase 3 (Weeks 9-11):** Theme system
- **Phase 4 (Weeks 12-15):** JavaScript API + testing ⚠️ *Buffer for compositor testing*
- **Phase 5 (Weeks 16-19):** Plugin system + isolation ⚠️ *Buffer for debugging*
- **Phase 6 (Weeks 20-22):** Live preview & tools
- **Phase 7 (Weeks 23-28):** Polish, security audit, docs ⚠️ *Extended for security review*

### Milestones:
- ✅ **Week 4:** Can lock/unlock screen (ugly but works!)
- ✅ **Week 8:** HTML/CSS rendering works, WebKit hardened, fallback mode functional
- ✅ **Week 11:** Theme system works, Shinkai theme beautiful!
- ✅ **Week 15:** JavaScript API complete, tested on Sway + Hyprland
- ✅ **Week 19:** Plugins working with isolation
- ✅ **Week 22:** Live preview and theme tools ready
- ✅ **Week 28:** Security audited, public release! 🎉

### Why the Buffer Weeks?

**Weeks 5-8 (Phase 2):** WebKit sandboxing is complex
- Need time to test IPC validation
- Fallback mode needs thorough testing
- Multi-monitor support can be fiddly

**Weeks 12-15 (Phase 4):** Compositor compatibility
- Wayland implementations vary (Sway vs Hyprland vs GNOME)
- Session lock protocol quirks
- Multi-monitor edge cases

**Weeks 23-28 (Phase 7):** Security is critical
- External security review/audit
- Penetration testing
- Bug fixes from security findings
- Documentation of security model

---

## 🎯 Success Metrics

### Security Success:
- ✅ No bypasses (VT switching, Alt+Tab blocked)
- ✅ Password never exposed to WebKit/JS
- ✅ IPC messages validated (no code injection)
- ✅ Fallback mode works (screen stays locked if WebKit crashes)
- ✅ Plugin crashes don't take down locker
- ✅ External security audit passed (Phase 7)
- ✅ No critical vulnerabilities reported

### Performance Success:
- ✅ Idle: < 1% CPU, < 50 MB RAM
- ✅ Animated: < 10% CPU, < 100 MB RAM
- ✅ Unlock time: < 500ms
- ✅ Theme load time: < 2 seconds
- ✅ Runs 24+ hours without memory leaks
- ✅ Works on low-end hardware (4GB RAM)
- ✅ Multi-monitor: no performance degradation
- ✅ See "Performance Budget" section for full metrics

### Technical Success:
- ✅ Works on major Wayland compositors (Hyprland, Sway, GNOME)
- ✅ Loads themes reliably
- ✅ JavaScript API is stable
- ✅ Plugin system is robust
- ✅ Multi-monitor support works

### User Success:
- ✅ Non-programmers can install themes
- ✅ Web developers can create themes easily
- ✅ Documentation is clear
- ✅ Theme validation catches errors
- ✅ Recovery from broken themes is simple
- ✅ No major bugs reported

### Community Success:
- ✅ 10+ community-created themes
- ✅ 100+ GitHub stars
- ✅ Featured on /r/unixporn
- ✅ Others contributing code/themes
- ✅ Theme repository established

---

## 🚀 Next Steps

### To Start Right Now:

1. **Create the repo:**
   ```bash
   mkdir -p ~/Projects/shinkai-lock
   cd ~/Projects/shinkai-lock
   git init
   ```

2. **Start Phase 0 research:**
   - Clone swaylock and read the code
   - Test python-pam with a simple script
   - Read ext-session-lock-v1 protocol

3. **Set up project:**
   - Copy this plan to the repo
   - Create initial file structure
   - Set up Nix development shell

### First Concrete Task:
**Write a simple PAM test script** that:
- Asks for username/password
- Verifies using python-pam
- Prints success/failure

This gets you familiar with PAM before building the full lock screen!

---

## 🛡️ Security FAQ

### Q: Is it safe to run HTML/CSS/JS in a lock screen?

**A: Yes, IF you separate untrusted rendering from trusted authentication.**

The key is the **two-process architecture**:
- **Core locker** (trusted) handles password input via native GTK
- **Theme renderer** (untrusted) displays visuals via WebKit
- Theme code never sees keyboard input or password data

### Q: What if a malicious theme tries to steal my password?

**A: It can't.**

The theme runs in WebKit and only has access to:
- Display data (time, music, battery)
- Unlock event notifications (success/failure)
- Plugin-provided data

The theme **cannot:**
- Capture keyboard input (GTK handles it)
- Access the password field (it's native GTK)
- Intercept authentication (PAM runs in core process)

Even if you install a malicious theme, the worst it can do is:
- Look ugly
- Waste CPU with animations
- Display wrong information

It **cannot** steal your password or bypass the lock.

### Q: What about plugins? Can they access my password?

**A: No, plugins don't have access to auth state.**

Plugins run in the trusted core process, but:
- They **cannot** access the password or auth state
- They **can** provide data to themes (weather, quotes, etc.)
- They **can** access the system (network, files, etc.)

Plugins are like backend services - they fetch data but don't touch authentication.

### Q: How is this different from a normal web browser?

**A: The password field is NOT part of the web content.**

In a normal browser, form inputs are part of the HTML and JavaScript can access them. In Shinkai Lock:

- **Browser:** `<input type="password">` → JS can read it → UNSAFE
- **Shinkai Lock:** GTK Entry widget → JS never sees it → SAFE

We use WebKit only for visuals (background, animations, decorations), not for the actual password input.

### Q: What if there's a bug in WebKit?

**A: The two-process model provides defense in depth.**

Even if WebKit has a vulnerability:
1. Theme renderer runs in a separate process (process isolation)
2. It's sandboxed (no network, no file access)
3. Password input happens in a different process
4. Keyboard input goes directly to GTK, not WebKit

A WebKit exploit could crash the theme renderer, but:
- The lock screen stays locked (core locker is separate)
- Your password remains secure (never touched WebKit)
- You can still unlock (GTK input still works)

### Q: Why not just block all HTML/CSS/JS for maximum security?

**A: You can! But you lose beautiful theming.**

This is the classic **security vs usability** trade-off:

**Maximum Security (swaylock approach):**
- ✅ No attack surface from themes
- ❌ Limited customization (just colors/fonts)
- ❌ No animations or rich visuals

**Shinkai Lock approach:**
- ✅ Beautiful, cinematic themes (HTML/CSS/JS)
- ✅ Still secure (two-process architecture)
- ⚠️ Slightly larger attack surface (but mitigated)

We chose security **AND** beauty by carefully separating concerns.

### Q: Should I trust themes from the internet?

**⚠️ SECURITY WARNING ⚠️**

While the architecture prevents password theft, themes can still be malicious:

**What a malicious theme CANNOT do:**
- ❌ Steal your password (GTK handles input, not WebKit)
- ❌ Bypass authentication
- ❌ Access your files (sandboxed)
- ❌ Make network requests (blocked)

**What a malicious theme CAN do:**
- ⚠️ Display fake UI to trick you (phishing attempt)
- ⚠️ Show offensive/NSFW content
- ⚠️ Waste CPU/battery with heavy animations
- ⚠️ Display misleading error messages

**Recommendations:**
- ✅ **Safe:** Official themes from Shinkai Lock repository
- ✅ **Safe:** Themes you create yourself
- ⚠️ **Review First:** Community themes (check HTML/CSS/JS code)
- ⚠️ **Caution:** Themes from GitHub (review before installing)
- ❌ **Avoid:** Themes from random websites
- ❌ **Never:** Run themes from untrusted sources without review

**How to Review a Theme:**
```bash
# Before installing a theme, check the code
cd ~/.config/shinkai-lock/themes/suspicious-theme
cat theme.json index.html style.css script.js

# Look for:
# - Suspicious network URLs
# - Base64-encoded strings (obfuscation)
# - Eval or Function() calls
# - Excessive file size (should be < 5MB for most themes)
```

**Best Practice:**
1. Only install themes from trusted sources
2. Review theme code before using
3. Test in preview mode first (`shinkai-lock --preview`)
4. Report suspicious themes to maintainers

Even though your password is safe, **a convincing fake UI could trick you into typing it elsewhere**. Always review themes!

---

## 💭 Final Thoughts

This is an ambitious project, but **totally achievable!**

You have:
- ✅ GTK4 experience (desktop-ui)
- ✅ Python skills
- ✅ Nix knowledge
- ✅ Design vision (your amazing demos!)
- ✅ Motivation (you love this aesthetic!)

What you'll learn:
- 🎓 Wayland protocols
- 🎓 Security (PAM, sandboxing, process isolation)
- 🎓 Plugin architectures
- 🎓 Open source project management
- 🎓 Building platforms, not just apps

**This could become THE lock screen for aesthetic-focused Wayland users!**

### Security First

This plan has been refined based on extensive security feedback to ensure **both beauty and safety**:

**Core Security Principles:**
- ✅ **Two-process architecture** - Untrusted rendering separated from trusted auth
- ✅ **Native password input** - GTK Entry widget, never HTML
- ✅ **IPC validation** - Whitelist messages, type checking, rate limiting
- ✅ **WebKit hardening** - Disabled WebGL, fetch(), eval, network access
- ✅ **CSP headers** - Content Security Policy blocks unauthorized resources
- ✅ **Fallback mode** - Plain GTK UI if WebKit crashes (screen stays locked)

**Runtime Protections:**
- ✅ **Plugin isolation** - Thread-based with timeout, health monitoring
- ✅ **Performance budgets** - CPU/RAM limits with monitoring
- ✅ **Resource limits** - Max data size, call frequency caps
- ✅ **Crash recovery** - Auto-fallback, no unlock on failure

**Development Process:**
- ✅ **Multi-compositor testing** - Hyprland, Sway, GNOME (Phase 4)
- ✅ **Security testing** - Escape attempts, fuzzing, penetration testing
- ✅ **External audit** - Security review before public release (Phase 7)
- ✅ **Buffer weeks** - 4-6 weeks extra for security hardening

The architecture balances the **visual richness** you want with the **security** you need. You get cinematic Makoto Shinkai themes without compromising your password security.

**Thanks to community feedback**, this plan now includes production-grade security measures from day one.

### Development Strategy

Take it one phase at a time:

1. **Phases 0-1:** Build a basic, ugly-but-secure lock screen
2. **Phase 2:** Add WebKit rendering (where security matters!)
3. **Phases 3-4:** Make it beautiful and themeable
4. **Phases 5-7:** Add plugins, polish, release

Start small, build confidence, then add features. You've got this! 🚀✨

---

**Ready to start? Let's build something beautiful AND secure! 🎬🔒**
