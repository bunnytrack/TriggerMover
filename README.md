# TriggerMover

## Author
Sapphire (based on [AdminUtils](https://github.com/bunnytrack/AdminUtils) by >@tack!<).

## Description
Allows on-the-fly triggering and manipulation of movers.

## Usage
All commands are case insensitive.

| Command                                    | Description
| ---                                        | ---
| `mutate TriggerMover`                      | Triggers the targeted mover.
| `mutate TriggerMover True`                 | Triggers the targeted mover and keeps it open permanently.
| `mutate TriggerMover Nearest`              | Triggers the nearest mover to the player.
| `mutate TriggerMover Nearest [PlayerName]` | Triggers the nearest mover to `[PlayerName]`. `[PlayerName]` can be a partial string, e.g. "sap" for "Sapphire".
| `mutate TriggerMover GetTag`               | Displays the `Tag` property of the targeted mover. The player is notified if the targeted actor is not a mover.
| `mutate TriggerMover GetTag All`           | Displays a comma-separated list of all mover `Tag` properties in the current level.
| `mutate TriggerMover Tag [Name]`           | Triggers all movers with a `Tag` property of `[Name]`. The player is notified when no matches are found.
| `mutate TriggerMover Tag [Name] True`      | Same as above, but keeps the mover open permanently.
| `mutate TriggerMover Reset`                | Quickly resets the targeted mover to its first keyframe.
| `mutate TriggerMover Reset [Name]`         | Same as above, for all movers with a `Tag` property of `[Name]`.
| `mutate TriggerMover State`                | Toggles the targeted mover's `InitialState` property between `BumpOpenTimed` or `StandOpenTimed`, if its `InitialState` property is `BumpOpenTimed` or `StandOpenTimed`.

## Notes
Movers with an `InitialState` property of `TriggerControl` (a.k.a. dead man's switches) are ignored (and the player is notified when attempting to trigger one). Because these movers rely on player proximity, triggering them manually keeps them open permanently and can potentially ruin a game. An example of a `TriggerControl` mover is shown below in `KnighTmare][`:

![Screenshot of TriggerControl mover in CTF-BT-KnighTmare\]\[](https://i.imgur.com/TyGxnbH.jpg)

## Motivation
Many maps have movers with slow return times or mover-related obstacles at the beginning of the level. Such mapping practices often results in player frustration at having to continually re-trigger movers or wait for them to return. This is especially problematic for rushers. A few examples of well-known maps with annoying spawn room movers are shown below:

### BlitzCastle
![Spawn room of CTF-BT-BlitzCastle](https://i.imgur.com/AjMTlNU.jpg)

### Mesablanca
![Spawn room of CTF-BT-Mesablanca](https://i.imgur.com/dUCGSmA.jpg)

### SnowyPark
![Spawn room of CTF-BT-SnowyPark](https://i.imgur.com/eeM5dYP.jpg)

## Version
2018-09-07

## Website
https://bunnytrack.net/
