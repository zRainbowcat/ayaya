#define SOUNDBREAKER_NOTE_STRIKE     1
#define SOUNDBREAKER_NOTE_WAVE       2
#define SOUNDBREAKER_NOTE_DULCE      3
#define SOUNDBREAKER_NOTE_OVERLOAD   4
#define SOUNDBREAKER_NOTE_ENCORE     5
#define SOUNDBREAKER_NOTE_SOLO       6

#define SB_COMBO_ICON_ECHO        "combo_echo"
#define SB_COMBO_ICON_TEMPO       "combo_tempo"
#define SB_COMBO_ICON_SNAPBACK    "combo_snap"
#define SB_COMBO_ICON_BASS        "combo_bass"
#define SB_COMBO_ICON_CROSSFADE   "combo_cross"
#define SB_COMBO_ICON_REVERB      "combo_reverb"
#define SB_COMBO_ICON_SYNC        "combo_sync"
#define SB_COMBO_ICON_RITMO       "combo_ritmo"
#define SB_COMBO_ICON_CRESCENDO   "combo_crescendo"
#define SB_COMBO_ICON_OVERTURE    "combo_overture"
#define SB_COMBO_ICON_BLADE       "combo_blade"
#define SB_COMBO_ICON_HARMONIC    "combo_harmonic"

#define SB_COMBO_WINDOW (8 SECONDS)
#define SB_MAX_HISTORY 6
#define SB_BASE_COOLDOWN (1.5 SECONDS)

#define COMSIG_SOUNDBREAKER_COMBO_CLEARED "soundbreaker_combo_cleared"

/mob/living
	var/datum/soundbreaker_combo_tracker/soundbreaker_combo
	var/list/sb_note_history
	var/list/sb_note_overlays
