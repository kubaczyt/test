# FiveM FindObject Resource

This repository contains a simple FiveM resource that lets you locate all spawned objects with a specific hash (or model name), teleport to them, and optionally save their coordinates to a text file inside the resource.

## Usage

1. Add the `resources/findobject` folder to your FiveM server resources directory.
2. Add `ensure findobject` to your `server.cfg`.
3. In-game, use the following commands:
   - `/findobject <objectHash|modelName>` — Lists matching objects in chat.
   - `/findobject <objectHash|modelName> save` — Lists matching objects and saves their coordinates to `findobject_results.txt` in the resource folder.
   - `/gotoobject <index>` — Teleports you to a previously listed object.

Coordinates are cached per player session; run `/findobject` again to refresh the list.
