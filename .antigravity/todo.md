# Tactical Memory (FISHMAN23)
*Constraint: Cleanliness is the rule. Completely delete completed items.*

- [ ] Test the new Cyborg Autofarm to ensure the memory-leak GC patching holds up properly.
- [ ] Monitor the 0-Bait Flight sequence in the Fishing script to verify the logic correctly executes even when "Auto Buy" is toggled off.
- [ ] Verify the joiner system teleport sequence with native dynamic yielding (RemoteFunction & ConfirmationPrompt UI yielding) across server hops and rejoins.
- [ ] Verify that `CombinedAutoLoad.lua` does not auto-start on game launch and only executes when triggered via the UI button or teleport queue.
- [ ] Verify that clicking "Teleport Now!" or "Return to Base" invokes `queue_on_teleport` and automatically routes from the Main Lobby to the destination without requiring a second click.
