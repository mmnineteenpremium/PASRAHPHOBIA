# Mobile Room Browser Fix 2026-04-11

## Context

- issue surfaced during real manual smoke on `2` iPhones after latest published build
- device pair:
  - `iPhone 14 Pro Max`
  - `iPhone 13 Pro`
- both devices now honor landscape after cold reopen of Roblox app
- blocking UX issue was not orientation, but Room Browser usability on mobile landscape

## Problem

- host could not reach `Create Room` because the button stack sat too low in the viewport
- fallback through `quick queue` / auto teleport was rejected as the main smoke path because it does not guarantee both devices enter the same investigation room through the intended room flow
- effect:
  - final `2`-client smoke stayed blocked
  - room creation / join on mobile landscape was not reliable enough for publish sign-off

## Scope of Fix

- file updated:
  - `src/client/UI/Main.lua`
- change was intentionally limited to Room Browser layout / labels for mobile landscape
- no gameplay / networking / room logic was changed

## Layout Decisions

### Browser State

- added a dedicated wide-mobile layout for compact mobile landscape (`~844x390` class viewport)
- left column:
  - room preview panel
- right column:
  - room list
  - primary CTA `JOIN ROOM`
  - secondary CTA row `REFRESH` + `BUAT ROOM`
- `QuickJoinClassic` and `QuickJoinRanked` are hidden in this wide-mobile browser state so the main room-flow CTA stays visible and the user is not nudged toward a less-valid smoke path

### Room List Rows

- room rows are taller on wide mobile
- row text is shortened to a two-line summary:
  - room id / occupancy
  - host / status
- goal: better scanability on iPhone landscape widths

### In-Room State

- added a wide-mobile room-panel layout so host/joiner action buttons stay near the upper-left action lane instead of being buried far below the fold
- `READY` / `MULAI PERMAINAN` / `KELUAR ROOM` are now positioned earlier in the canvas for this mobile-wide path

## Runtime Verification

- verified in active Studio with viewport override:
  - `PasrahUIViewportOverrideX = 844`
  - `PasrahUIViewportOverrideY = 390`
- Room Browser browser-state result:
  - panel size: `836x420`
  - `RoomList` visible at right column
  - `JOIN ROOM` visible at `414x40`
  - `BUAT ROOM` visible at `204x36`
  - `QuickJoinClassic` hidden
  - `QuickJoinRanked` hidden
- host action lane layout also reflowed for the same mobile-wide path
- no new runtime boot error surfaced in Studio console during this verification pass

## Operational Note

- next multiplayer retest should use the proper room path:
  - host opens Room Browser
  - host taps `BUAT ROOM`
  - joiner selects host room
  - joiner taps `JOIN ROOM`
  - joiner taps `READY`
  - host starts match
- do not use quick queue as the substitute path for final publish smoke
