# fdb Cheat Sheet — DocTak

**fdb = Flutter Debug Bridge** (CLI tool, installed via `dart pub global activate fdb`).
Lets you launch, inspect, log, and drive the running Flutter app from the terminal.

Workflow: **launch → watch logs → spot the bug → fix → reload → verify**

---

## 1. Setup (once per terminal)
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"   # only if `fdb` isn't found (already in ~/.zshrc)
cd /Users/hassan/Documents/MyProjects/Doctak_project/doctak_app
```

## 2. 🟢 Launch / connect
```bash
fdb devices                                   # list devices (get the ID)
fdb launch --device emulator-5554             # build + run the app
fdb attach --device emulator-5554             # attach to an ALREADY-running app
fdb status                                    # is the app running?
fdb doctor                                    # health check (VM service, device, etc.)
```

## 3. 🔍 CHECK DEBUG LOGS  ← "debug log check here"
```bash
fdb logs                                      # last 50 Flutter log lines
fdb logs --last 100                           # last 100 lines
fdb logs --follow                             # live stream (Ctrl+C to stop)
fdb logs --tag Story                          # only lines containing "Story"
fdb logs --tag 🔴 --last 80                    # only error lines
fdb logs --tag StoryApiService                # one service's logs
fdb syslog                                    # native Android logcat / iOS syslog
fdb crash-report                              # last OS-level crash record
```
> This is where you spot errors like `type 'String' is not a subtype of type 'int'`.

## 4. 👀 Inspect what's on screen
```bash
fdb screenshot                                # saves to .fdb/screenshot.png
fdb tree --depth 5                            # widget tree
fdb describe                                  # interactive elements + text (@N refs)
```

## 5. 🛠️ FIX → RELOAD → VERIFY  ← "fixs start here"
```bash
# 1. Edit the Dart file in your IDE (e.g. story_model.dart)
fdb reload                                     # hot reload (keeps app state)
fdb restart                                    # hot restart (resets state)
fdb logs --tag 🔴 --last 50                     # confirm the error is gone
fdb screenshot                                 # confirm UI renders
```

## 6. 🤖 Drive the UI (reproduce bugs)
```bash
fdb tap "Stories"            # tap a widget by text/selector
fdb tap --x 200 --y 400      # tap by coordinates
fdb input "hello"            # type text
fdb scroll down              # scroll
fdb scroll-to <selector>     # scroll until a widget is visible
fdb back                     # navigator pop
fdb wait <selector>          # wait for a widget/route
fdb swipe <selector>         # swipe (PageView, Dismissible)
```

## 7. 🧠 Memory / performance
```bash
fdb mem profile              # heap usage
fdb gc                       # force garbage collection
fdb heap dump --output heap.snapshot
```

## 8. 🛑 Stop
```bash
fdb kill                     # stop the app
```

---

## Typical debug loop for type/parsing bugs
```bash
fdb logs --tag 🔴 --follow     # 1. watch errors live
# ...see the crash, edit the Dart file to fix...
fdb reload                     # 2. apply fix
fdb logs --tag 🔴 --last 30     # 3. confirm clean
fdb screenshot                 # 4. confirm UI
```

## Notes
- Session artifacts are stored in `.fdb/` (logs.txt, screenshot.png, app_id.txt).
- `fdb skill` prints the tool's full AI-agent reference (SKILL.md).
- Avoid piping fdb output to `head` on this machine — `head` is shadowed by another tool.
