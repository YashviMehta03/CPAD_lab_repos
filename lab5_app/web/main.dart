// ignore_for_file: avoid_print
import 'package:web/web.dart' as web;
import 'dart:js_interop';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
void main() {
  _setupFooterClock();
  _setupSection1TextManipulation();
  _setupSection2StyleManipulation();
  _setupSection3ClassToggle();
  _setupSection4EventCounter();
}

// ---------------------------------------------------------------------------
// Helper: get current time string HH:MM:SS
// ---------------------------------------------------------------------------
String _timestamp() {
  final now = DateTime.now();
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

// ---------------------------------------------------------------------------
// Footer live clock (updated every second via JS setInterval)
// ---------------------------------------------------------------------------
void _setupFooterClock() {
  final el = web.document.querySelector('#footer-time') as web.HTMLElement?;
  if (el == null) return;

  void tick() {
    final now = DateTime.now();
    final y = now.year;
    final mo = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    el.textContent = '$y-$mo-$d ${_timestamp()}';
  }

  tick(); // run immediately
  web.window.setInterval(tick.toJS, 1000.toJS);
}

// ---------------------------------------------------------------------------
// SECTION 1 — Text Content Manipulation
// Demonstrates: querySelector, textContent assignment
// ---------------------------------------------------------------------------
void _setupSection1TextManipulation() {
  final demoText =
      web.document.querySelector('#demo-text') as web.HTMLElement?;
  final textInput =
      web.document.querySelector('#text-input') as web.HTMLInputElement?;
  final btnChange =
      web.document.querySelector('#btn-change-text') as web.HTMLButtonElement?;
  final btnReset =
      web.document.querySelector('#btn-reset-text') as web.HTMLButtonElement?;

  if (demoText == null || textInput == null ||
      btnChange == null || btnReset == null) return;

  const originalText =
      'Hello! I am a paragraph element. Click the button to change my content.';

  // Attach click event listener to the Update button
  btnChange.onClick.listen((_) {
    final val = textInput.value.trim();
    if (val.isEmpty) {
      _flashRed(textInput);
      return;
    }
    // DOM manipulation: update textContent of the paragraph
    demoText.textContent = val;
    demoText.style.color = '#00d2ff';
    textInput.value = '';
  });

  // Attach click event listener to the Reset button
  btnReset.onClick.listen((_) {
    demoText.textContent = originalText;
    demoText.style.color = '';
  });
}

/// Briefly flash a red border on an input to indicate validation error.
void _flashRed(web.HTMLInputElement el) {
  el.style.borderColor = '#f87171';
  el.style.boxShadow = '0 0 0 3px rgba(248,113,113,0.2)';
  Future.delayed(const Duration(milliseconds: 800), () {
    el.style.borderColor = '';
    el.style.boxShadow = '';
  });
}

// ---------------------------------------------------------------------------
// SECTION 2 — Style & Colour Manipulation
// Demonstrates: element.style property changes at runtime
// ---------------------------------------------------------------------------
void _setupSection2StyleManipulation() {
  final box =
      web.document.querySelector('#style-box') as web.HTMLElement?;
  final label =
      web.document.querySelector('#style-box-label') as web.HTMLElement?;

  if (box == null || label == null) return;

  // Map button ID → (background, foreground accent)
  final colourMap = <String, (String, String)>{
    'btn-color-blue':   ('#0f2a5c, #1a3a7c', '#4F8EF7'),
    'btn-color-green':  ('#0a2e1a, #0f3d22', '#22C55E'),
    'btn-color-purple': ('#1e0d3a, #2a1050', '#A855F7'),
    'btn-color-rose':   ('#2e0d1a, #3d1022', '#F43F5E'),
    'btn-color-amber':  ('#2e1e00, #3d2800', '#F59E0B'),
  };

  colourMap.forEach((id, colors) {
    final btn = web.document.querySelector('#$id') as web.HTMLButtonElement?;
    if (btn == null) return;
    final (bg, fg) = colors;
    btn.onClick.listen((_) {
      // DOM manipulation: change inline style properties
      box.style.background = 'linear-gradient(135deg, $bg)';
      box.style.borderColor = fg;
      label.style.color = fg;
    });
  });

  // Font size buttons
  final sizeMap = <String, String>{
    'btn-font-small':  '0.82rem',
    'btn-font-medium': '1.1rem',
    'btn-font-large':  '1.5rem',
  };

  sizeMap.forEach((id, size) {
    final btn = web.document.querySelector('#$id') as web.HTMLButtonElement?;
    if (btn == null) return;
    btn.onClick.listen((_) => label.style.fontSize = size);
  });

  // Bold toggle
  final btnBold =
      web.document.querySelector('#btn-font-bold') as web.HTMLButtonElement?;
  if (btnBold != null) {
    btnBold.onClick.listen((_) {
      label.style.fontWeight =
          (label.style.fontWeight == '700') ? '400' : '700';
    });
  }
}

// ---------------------------------------------------------------------------
// SECTION 3 — CSS Class Toggling
// Demonstrates: classList.add, classList.remove
// ---------------------------------------------------------------------------
void _setupSection3ClassToggle() {
  final themeBox =
      web.document.querySelector('#theme-box') as web.HTMLElement?;
  final themeLabel =
      web.document.querySelector('#theme-label') as web.HTMLElement?;

  if (themeBox == null || themeLabel == null) return;

  const allThemes = [
    'theme-default',
    'theme-success',
    'theme-warning',
    'theme-danger',
    'theme-dark',
  ];

  void applyTheme(String themeClass, String name) {
    // Remove all theme classes, then add the selected one
    for (final t in allThemes) {
      themeBox.classList.remove(t);
    }
    themeBox.classList.add(themeClass); // DOM manipulation: add CSS class
    themeLabel.textContent = 'Theme: $name';
  }

  final themeButtons = <String, (String, String)>{
    'btn-theme-default': ('theme-default', 'Default'),
    'btn-theme-success': ('theme-success', 'Success'),
    'btn-theme-warning': ('theme-warning', 'Warning'),
    'btn-theme-danger':  ('theme-danger',  'Danger'),
    'btn-theme-dark':    ('theme-dark',    'Dark'),
  };

  themeButtons.forEach((id, info) {
    final btn = web.document.querySelector('#$id') as web.HTMLButtonElement?;
    if (btn == null) return;
    final (cls, name) = info;
    btn.onClick.listen((_) => applyTheme(cls, name));
  });
}

// ---------------------------------------------------------------------------
// SECTION 4 — Event Listeners & Counter
// Demonstrates: multiple event listeners, real-time DOM updates
// ---------------------------------------------------------------------------
int _counter = 0;

void _setupSection4EventCounter() {
  final countEl =
      web.document.querySelector('#click-count') as web.HTMLElement?;
  final eventLog =
      web.document.querySelector('#event-log') as web.HTMLElement?;
  final btnInc =
      web.document.querySelector('#btn-counter-inc') as web.HTMLButtonElement?;
  final btnDec =
      web.document.querySelector('#btn-counter-dec') as web.HTMLButtonElement?;
  final btnReset =
      web.document.querySelector('#btn-counter-reset') as web.HTMLButtonElement?;

  if (countEl == null || eventLog == null ||
      btnInc == null || btnDec == null || btnReset == null) return;

  void updateCounter(String action) {
    countEl.textContent = '$_counter';
    // Micro-animation: scale up then back
    countEl.style.transform = 'scale(1.4)';
    Future.delayed(const Duration(milliseconds: 150), () {
      countEl.style.transform = 'scale(1)';
    });
    _appendLogEntry(eventLog, action);
  }

  // Attach three separate event listeners to three different buttons
  btnInc.onClick.listen((_) {
    _counter++;
    updateCounter('Incremented → $_counter');
  });

  btnDec.onClick.listen((_) {
    _counter--;
    updateCounter('Decremented → $_counter');
  });

  btnReset.onClick.listen((_) {
    _counter = 0;
    updateCounter('Counter reset to 0');
  });
}

/// Append a timestamped log entry to the event log panel.
void _appendLogEntry(web.HTMLElement log, String message) {
  final entry = web.document.createElement('div') as web.HTMLDivElement;
  entry.className = 'log-entry';

  final tsSpan = web.document.createElement('span') as web.HTMLSpanElement;
  tsSpan.className = 'ts';
  tsSpan.textContent = '[${_timestamp()}] ';

  final msgSpan = web.document.createElement('span') as web.HTMLSpanElement;
  msgSpan.className = 'msg';
  msgSpan.textContent = message;

  entry.appendChild(tsSpan);
  entry.appendChild(msgSpan);

  // Insert right after the header paragraph
  final header = log.querySelector('.log-header');
  if (header != null && header.nextSibling != null) {
    log.insertBefore(entry, header.nextSibling!);
  } else {
    log.appendChild(entry);
  }

  // Trim log to 20 entries maximum
  final entries = log.querySelectorAll('.log-entry');
  if (entries.length > 20) {
    (entries.item(entries.length - 1) as web.HTMLElement?)?.remove();
  }

  log.scrollTop = 0;
}
