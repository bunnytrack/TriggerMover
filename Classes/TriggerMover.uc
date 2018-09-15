class TriggerMoverMod expands Mutator;

struct MoverInfo {
	var Mover MoverObj;
	var Sound OpeningSound;
	var Sound OpenedSound;
	var Sound ClosingSound;
	var Sound ClosedSound;
	var Sound MoveAmbientSound;
};

var MoverInfo AllMovers[1024];
var Mover     MostRecentMover;
var float     DefaultMoveTime;
var string    EncroachTypes[4];

function PreBeginPlay() {
	Level.Game.BaseMutator.AddMutator(self);
}

simulated event PostBeginPlay() {
	Super.PostBeginPlay();

	// Populate AllMovers array with movers.
	PopulateMoverInfo();

	// Sending a MoverEncroachType as a ClientMessage displays a number only
	// (e.g. ME_StopWhenEncroach is 0), so this array allows for meaningful messages.
	EncroachTypes[0] = "StopWhenEncroach";
	EncroachTypes[1] = "ReturnWhenEncroach";
	EncroachTypes[2] = "CrushWhenEncroach";
	EncroachTypes[3] = "IgnoreWhenEncroach";

	Log("");
	Log("+---------------------------------------------------------+");
	Log("| TriggerMover                                            |");
	Log("| ------------------------------------------------------- |");
	Log("| Authors:     Sapphire; >@tack!<                         |");
	Log("| Version:     2018-09-15                                 |");
	Log("| Website:     https://github.com/bunnytrack/TriggerMover |");
	Log("+---------------------------------------------------------+");
	Log("");
}

function Mutate(string MutateString, PlayerPawn Sender) {
	local string action, param1, param2, param3;

	// This mutator is for admins only.
	if (Sender.bAdmin) {

		// Split mutate string into action/parameter variables.
		SplitMutateString(MutateString, action, param1, param2, param3);

		if (action ~= "TriggerMover") {
			switch (param1) {
				// First param is "true": trigger the targeted mover then disable it.
				case "True":
					TriggerMover(Sender, true);
					break;

				// Trigger nearest mover to sender or a given player.
				case "Nearest":
					TriggerNearestMover(Sender, param2);
					break;

				// Trigger mover(s) from a given tag.
				case "Tag":
					if (param2 != "") {
						// bKeepOpen is true: keep mover(s) open permanently.
						if (param3 ~= "True") {
							TriggerMoverByTag(Sender, param2, true);
						}

						// Just trigger the mover(s).
						else {
							TriggerMoverByTag(Sender, param2);
						}
					}

					// Tag parameter is missing.
					else {
						Sender.ClientMessage("Missing mover tag parameter.");
					}
					break;

				// Toggle mover state.
				case "State":
					ToggleMoverState(Sender);
					break;

				// Toggle enroach types.
				case "Encroach":
					ToggleMoverEncroachType(Sender);
					break;

				// Toggle mover sounds.
				case "Mute":
					ToggleMoverSounds(Sender);
					break;

				// Toggle bTriggerOnceOnly.
				case "OnceOnly":
					ToggleMoverOnceOnly(Sender);
					break;

				// Reset mover(s) back to first keyframe.
				// Optional parameter MoverTag.
				case "Reset":
					// No mover tag specified; just reset the targeted mover.
					if (param2 == "") {
						ResetMover(Sender);
					}

					// Reset mover(s) from a given tag.
					else {
						ResetMover(Sender, param2);
					}
					break;

				// Display the targeted mover's tag.
				// Optional parameter bListAll.
				case "GetTag":
					// Just get the targeted mover's tag.
					if (param2 == "") {
						DisplayMoverTag(Sender);
					}

					// List all mover tags.
					else if (Caps(param2) == "ALL") {
						DisplayMoverTag(Sender, true);
					}
					break;

				// Default: just trigger the mover.
				default:
					TriggerMover(Sender);
					break;
			}
		}
	}

	if (NextMutator != none) {
		NextMutator.Mutate(MutateString, Sender);
	}
}

/**
 * Trigger the currently targeted mover.
 * Optional parameter bKeepOpen will keep the mover open permanently.
 */
function TriggerMover(PlayerPawn Sender, optional bool bKeepOpen) {
	local Mover M;

	M = GetCurrentMover(Sender);

	if (M != none) {
		// Keep this mover open permanently.
		if (M.InitialState != 'TriggerControl' && bKeepOpen) {
			M.bTriggerOnceOnly = true;
		}

		switch (M.InitialState) {
			case 'BumpOpenTimed':
				M.HandleDoor(Sender);
				break;

			case 'StandOpenTimed':
				M.Attach(Sender);
				break;

			// Triggering TriggerControl movers keeps them open permanently, so do nothing.
			case 'TriggerControl':
				Sender.ClientMessage("TriggerControl mover detected; ignoring.");
				break;

			default:
				M.Trigger(Sender, Sender);
				break;
		}
	}
}

/**
 * Trigger the nearest mover.
 * Optional parameter PlayerName will search for a player and open the nearest mover to them.
 * @usage: mutate TriggerMover Nearest Sapphire
 * PlayerName can be a partial string (e.g. "sap" for "Sapphire").
 */
function TriggerNearestMover(PlayerPawn Sender, optional string PlayerName) {
	local Mover      M, NearestMover;
	local PlayerPawn P, NearestPlayer;

	// No player specified; nearest player is the sender.
	if (PlayerName == "") {
		NearestPlayer = Sender;
	}

	// Iterate through each player and attempt to find a match for the given player name.
	else {
		foreach AllActors(Class'PlayerPawn', P) {
			if (InStr(Caps(P.PlayerReplicationInfo.PlayerName), Caps(PlayerName)) != -1) {
				NearestPlayer = P;

				// Player found; stop searching.
				break;
			}
		}
	}

	if (NearestPlayer != none) {
		// Iterate through each mover and check how close it is to the player's location.
		foreach AllActors(Class'Mover', M) {

			// The first mover will always be the first nearest mover.
			if (NearestMover == none) {
				NearestMover = M;
			}

			// Compare the current mover's location in this iteration to the nearest mover so far.
			else if (VSize(NearestPlayer.Location - M.Location) < VSize(NearestPlayer.Location - NearestMover.Location)) {
				NearestMover = M;
			}
		}

		// Finally, trigger the mover.
		if (NearestMover != none) {
			switch (NearestMover.InitialState) {
				case 'BumpOpenTimed':
					NearestMover.HandleDoor(Sender);
					break;

				case 'StandOpenTimed':
					NearestMover.Attach(Sender);
					break;

				// Triggering TriggerControl movers keeps them open permanently, so do nothing.
				case 'TriggerControl':
					Sender.ClientMessage("TriggerControl mover detected; ignoring.");
					break;

				default:
					NearestMover.Trigger(Sender, Sender);
					break;
			}
		}
	}
}

/**
 * Trigger a mover from a given tag.
 * This is possible using the default command "CauseEvent [Name]", however TriggerMoverByTag
 * explicitly targets movers whereas CauseEvent targets any actor with a matching name.
 */
function TriggerMoverByTag(PlayerPawn Sender, string MoverTag, optional bool bKeepOpen) {
	local Mover M;
	local int   TotalMovers;

	// Get total movers with given tag.
	foreach AllActors(Class'Mover', M) {
		if (string(M.Tag) == MoverTag) {
			TotalMovers++;
		}
	}

	// No mover found with the given tag; notify sender then stop function.
	if (TotalMovers == 0) {
		Sender.ClientMessage("Unable to find Mover(s) with tag: " $ MoverTag);
		return;
	}

	// Trigger the movers.
	foreach AllActors(Class'Mover', M) {
		if (string(M.Tag) == MoverTag) {
			// Keep this mover open permanently if specified.
			if (bKeepOpen) {
				M.bTriggerOnceOnly = true;
			}

			switch (M.InitialState) {
				case 'BumpOpenTimed':
					M.HandleDoor(Sender);
					break;

				case 'StandOpenTimed':
					M.Attach(Sender);
					break;

				// Triggering TriggerControl movers keeps them open permanently, so do nothing.
				case 'TriggerControl':
					Sender.ClientMessage("TriggerControl mover detected; ignoring.");
					break;

				default:
					M.Trigger(Sender, Sender);
					break;
			}
		}
	}
}

/**
 * Quickly resets the currently targeted mover back to its first keyframe.
 * Optional parameter MoverTag allows targeting of specific movers.
 */
function ResetMover(PlayerPawn Sender, optional string MoverTag) {
	local Mover M;
	local float ResetTime;
	local int   TotalMovers;

	// When resetting a mover, use this value as its MoveTime if possible.
	ResetTime = 0.1;

	// No mover tag specified; just reset the targeted mover.
	if (MoverTag == "") {
		M = GetCurrentMover(Sender);

		if (M != none) {
			MostRecentMover = M;
			DefaultMoveTime = M.MoveTime;

			M.MoveTime = ResetTime;
			M.GotoState(M.InitialState, 'Close');

			// Reset mover then restore its original MoveTime.
			SetTimer(ResetTime, false);
		}
	}

	// Reset mover(s) from a given tag.
	else {
		foreach AllActors(Class'Mover', M) {
			if (string(M.Tag) == MoverTag) {
				TotalMovers++;
			}
		}

		// No mover found with the given tag; notify sender then return.
		if (TotalMovers == 0) {
			Sender.ClientMessage("Unable to find Mover(s) with tag: " $ MoverTag);
			return;
		}

		// One mover found: reduce its MoveTime, reset it, then restore original MoveTime.
		else if (TotalMovers == 1) {
			foreach AllActors(Class'Mover', M) {
				if (string(M.Tag) == MoverTag) {
					MostRecentMover = M;
					DefaultMoveTime = M.MoveTime;

					M.MoveTime = ResetTime;
					M.GotoState(M.InitialState, 'Close');

					// Reset mover then restore its original MoveTime.
					SetTimer(ResetTime, false);
				}
			}
		}

		// Multiple movers found with the same tag: reset them "normally",
		// as the hacky method to reset them quickly fails with multiple movers.
		else {
			foreach AllActors(Class'Mover', M) {
				if (string(M.Tag) == MoverTag) {
					M.GotoState(M.InitialState, 'Close');
				}
			}
		}
	}

}

/**
 * Get the currently targeted mover under the crosshair
 */
function Mover GetCurrentMover(PlayerPawn Sender) {
	local Actor HitActor;
	local vector X, Y, Z, HitLocation, HitNormal, EndTrace, StartTrace;
	local Mover HitMover;

	GetAxes(Sender.ViewRotation, X, Y, Z);

	StartTrace = Sender.Location + Sender.EyeHeight * vect(0, 0, 1);
	EndTrace   = StartTrace + X * 10000;

	HitActor = Trace(HitLocation, HitNormal, EndTrace, StartTrace, false);
	HitMover = Mover(HitActor);

	return HitMover;
}

/**
 * Toggle the currently targeted mover between BumpOpenTimed/StandOpenTimed.
 * Note: changing the InitialState property does not actually affect the mover
 * state during play - GotoState() has to be invoked as well.
 */
function ToggleMoverState(PlayerPawn Sender) {
	local Mover M;

	M = GetCurrentMover(Sender);

	if (M != none) {
		switch (M.InitialState) {
			case 'BumpOpenTimed':
				M.InitialState = 'StandOpenTimed';
				M.GotoState('StandOpenTimed');
				Sender.ClientMessage("Mover state changed to " $ M.InitialState $ ".");
				break;

			case 'StandOpenTimed':
				M.InitialState = 'BumpOpenTimed';
				M.GotoState('BumpOpenTimed');
				Sender.ClientMessage("Mover state changed to " $ M.InitialState $ ".");
				break;

			default:
				break;
		}
	}
}

/**
 * Toggle between CrushWhenEncroach, IgnoreWhenEncroach, and ReturnWhenEncroach.
 */
function ToggleMoverEncroachType(PlayerPawn Sender) {
	local Mover M;

	M = GetCurrentMover(Sender);

	if (M != none) {
		switch (M.MoverEncroachType) {
			case ME_ReturnWhenEncroach:
				M.MoverEncroachType = ME_CrushWhenEncroach;
				break;

			case ME_CrushWhenEncroach:
				M.MoverEncroachType = ME_IgnoreWhenEncroach;
				break;

			case ME_IgnoreWhenEncroach:
				M.MoverEncroachType = ME_ReturnWhenEncroach;
				break;

			case ME_StopWhenEncroach:
				Sender.ClientMessage("StopWhenEncroach mover detected; ignoring.");
				return;

			default:
				Sender.ClientMessage("Unrecognised MoverEncroachType " $ M.MoverEncroachType);
				return;
		}

		Sender.ClientMessage("MoverEncroachType changed to " $ EncroachTypes[M.MoverEncroachType]);
	}
}

/**
 * Toggle bTriggerOnceOnly property then reset mover.
 */
function ToggleMoverOnceOnly(PlayerPawn Sender) {
	local Mover M;

	M = GetCurrentMover(Sender);

	if (M != none) {
		M.bTriggerOnceOnly = !M.bTriggerOnceOnly;
		M.GotoState(M.InitialState, 'Close');
		Sender.ClientMessage("bTriggerOnceOnly set to " $ M.bTriggerOnceOnly);
	}
}

/**
 * Output the currently targeted mover's tag to the sender.
 */
function DisplayMoverTag(PlayerPawn Sender, optional bool bListAll) {
	local Mover  M;
	local int    i, TotalMovers;
	local string AllMovers;

	// Just list the currently targeted mover's tag.
	if (!bListAll) {
		M = GetCurrentMover(Sender);

		if (M != none) {
			Sender.ClientMessage(M.Tag);
		} else {
			Sender.ClientMessage("Current actor is not a mover.");
		}
	}

	// List all tags
	else {
		foreach AllActors(Class'Mover', M) {
			TotalMovers++;
		}

		foreach AllActors(Class'Mover', M) {
			i++;

			AllMovers = AllMovers $ M.Tag;

			if (i != TotalMovers) {
				AllMovers = AllMovers $ ", ";
			} else {
				AllMovers = AllMovers $ ".";
			}
		}

		Sender.ClientMessage(AllMovers);
	}
}

/**
 * Sets all mover sounds to None / restores original mover sounds.
 */
function ToggleMoverSounds(PlayerPawn Sender) {
	local Mover M;
	local int   i;

	M = GetCurrentMover(Sender);

	if (M != none) {
		// If the mover isn't muted, mute it.
		if (!MoverIsMuted(M)) {
			M.OpeningSound     = none;
			M.OpenedSound      = none;
			M.ClosingSound     = none;
			M.ClosedSound      = none;
			M.MoveAmbientSound = none;
		}

		// Otherwise, find it in AllMovers and restore its sounds.
		else {
			for (i = 0; i < ArrayCount(AllMovers); i++) {
				if (AllMovers[i].MoverObj == M) {
					M.OpeningSound     = AllMovers[i].OpeningSound;
					M.OpenedSound      = AllMovers[i].OpenedSound;
					M.ClosingSound     = AllMovers[i].ClosingSound;
					M.ClosedSound      = AllMovers[i].ClosedSound;
					M.MoveAmbientSound = AllMovers[i].MoveAmbientSound;
					break;

				} else if (AllMovers[i].MoverObj == none) {
					break;
				}
			}
		}
	}
}

/**
 * Checks whether a mover has any sounds.
 */
function bool MoverIsMuted(Mover M) {
	return M.OpeningSound == none && M.OpenedSound == none && M.ClosingSound == none && M.ClosedSound == none && M.MoveAmbientSound == none;
}

/**
 * Add each mover in the level to AllMovers so their properties can be called on later.
 * Executed once during PostBeginPlay.
 */
function PopulateMoverInfo() {
	local int   i;
	local Mover M;

	// Sounds can't be called from MoverObj - need to set these properties also
	foreach AllActors(Class'Mover', M) {
		AllMovers[i].MoverObj         = M;
		AllMovers[i].OpeningSound     = M.OpeningSound;
		AllMovers[i].OpenedSound      = M.OpenedSound;
		AllMovers[i].ClosingSound     = M.ClosingSound;
		AllMovers[i].ClosedSound      = M.ClosedSound;
		AllMovers[i].MoveAmbientSound = M.MoveAmbientSound;
		i++;
	}
}

/**
 * Scans a string and splits it into an action and two optional parameters.
 * @example: "mutate TriggerMover Tag Crusher01_RedTeam True" becomes:
 * action = "TriggerMover"
 * param1 = "Reset"
 * param2 = "Crusher01_RedTeam"
 * param3 = "True"
 */
function SplitMutateString(String mString, out String action, out string param1, out string param2, out string param3) {
	if (InStr(mString, " ") != -1) {
		action = Left(mString, InStr(mString, " "));
		param1 = Right(mString, Len(mString) - InStr(mString, " ") - 1);

		if (InStr(param1, " ") != -1) {
			param2 = Right(param1, Len(param1) - InStr(param1, " ") - 1);
			param1 = Left(param1, InStr(param1, " "));

			if (InStr(param2, " ") != -1) {
				param3 = Right(param2, Len(param2) - InStr(param2, " ") - 1);
				param2 = Left(param2, InStr(param2, " "));
			}
		}
	} else {
		action = mString;
	}
}

/**
 * When a mover is being reset, its original MoveTime value is stored in DefaultMoveTime
 * then changed to 0.1; once reset, its original MoveTime value is restored here.
 */
function Timer() {
	MostRecentMover.MoveTime = DefaultMoveTime;
}
