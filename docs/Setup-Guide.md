# Setup Guide

This page walks through every step to get the Obby game running in Roblox Studio.

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Roblox Studio | Latest | [roblox.com/create](https://www.roblox.com/create) |
| Rojo CLI | ≥ 7.x | See below |
| Git | Any | [git-scm.com](https://git-scm.com) |

### Installing Rojo

**With Aftman (recommended):**
```bash
# Install aftman first: https://github.com/LPGhatguy/aftman
aftman install
```

**With Cargo:**
```bash
cargo install rojo
```

**With Foreman:**
```bash
foreman install
```

After installation, verify:
```bash
rojo --version
# Expected: rojo 7.x.x
```

### Installing the Rojo Studio Plugin

1. Open Roblox Studio.
2. Go to **Plugins → Manage Plugins → Search** for "Rojo".
3. Install the official Rojo plugin by Rojo Team.

---

## Cloning the Repository

```bash
git clone https://github.com/prasenjeet/roblox-app.git
cd roblox-app
```

---

## Serving the Project

```bash
rojo serve
```

You should see output like:
```
Rojo server listening on port 34872
```

Keep this terminal open.

---

## Connecting Studio

1. Open Roblox Studio with any place (a blank baseplate works fine).
2. Click the **Rojo** plugin button in the Plugins toolbar.
3. Click **Connect** and enter `localhost:34872` if prompted.
4. Rojo will sync all `src/` files into the correct Studio services.

> **Tip:** Enable **auto-sync** in the Rojo plugin so file saves are reflected immediately.

---

## Running the Game

Press **Play** (F5) in Studio. The server script `GameManager.server.lua` runs and:

1. Builds all 10 stages procedurally in `Workspace.Obbycourse`.
2. Scatters 30 coins into `Workspace.Coins`.
3. Creates `RemoteEvent` / `RemoteFunction` instances in `ReplicatedStorage`.
4. Starts the moving-platform and spinning-obstacle loops.

Players spawn on the Stage 1 platform and can begin the course.

---

## File Sync Details

`default.project.json` maps the `src/` folder tree to Roblox services:

| `src/` path | Roblox location |
|---|---|
| `ServerScriptService/*.server.lua` | `ServerScriptService` (Scripts) |
| `StarterPlayerScripts/*.client.lua` | `StarterPlayer.StarterPlayerScripts` (LocalScripts) |
| `StarterGui/ObbyGui/` | `StarterGui.ObbyGui` (ScreenGui) |
| `ReplicatedStorage/Shared/` | `ReplicatedStorage.Shared` (ModuleScripts) |
| `Workspace/CourseTemplate.lua` | `Workspace` (ModuleScript, informational) |

---

## Publishing to Roblox

1. In Studio, go to **File → Publish to Roblox As…**
2. Choose a name, description, and thumbnail.
3. Set **Genre** to "Adventure" and enable the **Public** toggle when ready.
4. Click **Create** (or **Save**).

The published place ID appears in the URL. Store it for future updates via the Roblox API or Studio's "Publish" shortcut (Ctrl+P).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Rojo can't connect | Ensure `rojo serve` is running and the port matches the plugin |
| Scripts not syncing | Check that file extensions are correct (`.server.lua`, `.client.lua`, `.lua`) |
| Course doesn't build | Open the Studio Output window; look for errors from `GameManager` |
| Kill bricks not killing | Make sure `CollectionService` tags are present — check the Tag Editor plugin |
| GUI not appearing | Confirm `ObbyGui` is a `ScreenGui` in `StarterGui` (set by Rojo via `default.project.json`) |
