local keys = require("tauer.modern-lockpicking.services.translations.enums.translationKeys")

return {
	[keys.modName] = "Modern Lockpicking",
	[keys.messageBoxNoLockpicks] = "You have no lockpicks.",
	[keys.messageBoxOutOfLockpicks] = "You are out of lockpicks.",
	[keys.messageBoxPicksTooWeak] = "Your remaining lockpicks are too weak for this lock.",
	[keys.interfaceControlsHeader] = "Controls",
	[keys.interfaceControlsRotatePick] = "Rotate Pick",
	[keys.interfaceControlsRotateLock] = "Rotate Lock",
	[keys.interfaceControlsCyclePicks] = "Cycle Picks",
	[keys.interfaceControlsExit] = "Exit",
	[keys.interfacePicksHeader] = "Lockpicks",
	[keys.mcmLabelsLeft] = "Counter clockwise",
	[keys.mcmLabelsRight] = "Clockwise",
	[keys.mcmLabelsPrevious] = "Previous",
	[keys.mcmLabelsNext] = "Next",
	[keys.mcmLabelsOther] = "Other",
	[keys.mcmLabelsSettings] = "Settings",
	[keys.mcmDescriptionRotateLock] = "Configure the controls for rotating the lock.",
	[keys.mcmDescriptionRotateLockCounterclockwise] = "Set the key to rotate the lock counter clockwise.",
	[keys.mcmDescriptionRotateLockClockwise] = "Set the key to rotate the lock clockwise.",
	[keys.mcmDescriptionCyclePicks] = "Configure the controls for cycling through picks.",
	[keys.mcmDescriptionCyclePreviousPick] = "Set the key for cycling to the previous pick.",
	[keys.mcmDescriptionCycleNextPick] = "Set the key for cycling to the next pick.",
	[keys.mcmDescriptionExit] = "Set the key to exit the lockpicking interface.",
	[keys.mcmDescriptionOther] = "Other keybinds.",
	[keys.mcmHeaderDebugging] = "Debugging",
	[keys.mcmDebuggingLabelShowRenderer] = "Show Sweet Spot Renderer",
	[keys.mcmDebuggingDescShowRenderer] =
	"Visualizes the sweet spot and gradient as colored lines on the lock. Intended for debugging only.",
	[keys.mcmHeaderDifficulty] = "Difficulty",
	[keys.mcmDifficultyCategorySweetSpot] = "Sweet Spot",
	[keys.mcmDifficultyCategoryGradient] = "Gradient",
	[keys.mcmDifficultyLabelSecurityFactor] = "Security Weight",
	[keys.mcmDifficultyDescSecurityFactor] =
	"How much the security skill contributes to the sweet spot size. 1.0 is the default; higher values reward skill more.",
	[keys.mcmDifficultyLabelLockLevelFactor] = "Lock Level Weight",
	[keys.mcmDifficultyDescLockLevelFactor] =
	"How much the lock level shrinks the sweet spot. 1.0 is the default; higher values make high-level locks much harder.",
	[keys.mcmDifficultyLabelQualityFactor] = "Quality Weight",
	[keys.mcmDifficultyDescQualityFactor] =
	"How much pick quality contributes to the sweet spot size. 1.0 is the default; higher values make pick choice matter more.",
	[keys.mcmDifficultyLabelMinRadius] = "Min Sweet Spot Radius (degrees)",
	[keys.mcmDifficultyDescMinRadius] =
	"Floors the sweet spot size so locks stay pickable even at high difficulty.",
	[keys.mcmDifficultyLabelMaxRadius] = "Max Sweet Spot Radius (degrees)",
	[keys.mcmDifficultyDescMaxRadius] = "Caps the sweet spot size regardless of skill or pick quality.",
	[keys.mcmDifficultyLabelGradientFactor] = "Gradient Factor",
	[keys.mcmDifficultyDescGradientFactor] =
	"Width of the gradient zone outside the sweet spot. 1.0 is the default; higher values widen the forgiving zone.",
	[keys.mcmDifficultyCategoryPickDamage] = "Pick Damage (per second)",
	[keys.mcmDifficultyLabelMinDamage] = "Min Pick Damage",
	[keys.mcmDifficultyDescMinDamage] =
	"Pick damage per second, as a percent of the pick's maximum health, at the largest sweet spot (easiest locks). Raise this if picks last too long. The rate rises toward Max as the sweet spot shrinks.",
	[keys.mcmDifficultyLabelMaxDamage] = "Max Pick Damage",
	[keys.mcmDifficultyDescMaxDamage] =
	"Pick damage per second, as a percent of the pick's maximum health, at the smallest sweet spot (hardest locks). The rate is always between Min and Max; sweet-spot size decides where it lands.",
	[keys.mcmDifficultyTextResetToDefaults] = "Reset",
	[keys.mcmDifficultyLabelResetToDefaults] = "Reset to Defaults",
	[keys.mcmDifficultyDescResetToDefaults] = "Reset all difficulty settings to their default values.",
	[keys.tooltipPickHealth] = "Health",
	[keys.mcmActivationMethodCategory] = "Activation",
	[keys.mcmActivationMethodLabel] = "Mode",
	[keys.mcmActivationMethodDesc] =
	"How lockpicking is activated.\n'Activate' opens the interface when interacting with a locked object.\n'Attack' intercepts the vanilla lockpick attack and opens the interface instead.",
	[keys.mcmActivationMethodDefault] = "Activate",
	[keys.mcmActivationMethodAttack] = "Attack",
	[keys.mcmAllowEquipPicksLabel] = "Allow Equipping Picks",
	[keys.mcmAllowEquipPicksDesc] =
	"When enabled, lockpicks can be equipped from the inventory like in the vanilla game. Note: disabling this while using Attack mode makes lockpicking impossible.",
	[keys.mcmUseLockComplexityLabel] = "Respect lock complexity",
	[keys.mcmUseLockComplexityDesc] =
	"Blocks the player from entering the lockpicking mini-game if the lock is too complex (based on the same formula as the vanilla game).\n Note, this will also prevent lockpicks with too low quality to be selected for complex locks.",
	[keys.mcmDifficultyLabelDamageSkeletonKey] = "Damage Skeleton Key",
	[keys.mcmDifficultyDescDamageSkeletonKey] =
	"When enabled, the Skeleton Key can be damaged and broken like any other lockpick. When disabled, it is indestructible.",
	[keys.mcmEnabledLabel] = "Enable Mod",
	[keys.mcmEnabledDesc] =
	"When disabled, the lockpicking minigame is skipped and the vanilla lockpicking behavior is used instead.",
	[keys.mcmLitRenderingLabel] = "Lit Rendering",
	[keys.mcmLitRenderingDesc] =
	"When enabled, lock meshes are lit by scene lighting. When disabled, meshes are rendered unlit.",
	[keys.mcmHeaderVisuals] = "Visuals",
	[keys.mcmVisualsLabelEnableDof] = "Depth of Field",
	[keys.mcmVisualsDescEnableDof] =
	"When enabled, a bokeh depth of field effect is applied during lockpicking.",
	[keys.mcmVisualsLabelLockDistance] = "Lock Distance",
	[keys.mcmVisualsDescLockDistance] =
	"Scales how far away the lock is placed during lockpicking. The distance automatically adapts to your screen aspect ratio and field of view; lower this to bring the lock closer, raise it to push the lock farther away.",
	[keys.mcmVisualsLabelShowPickHealth] = "Show Pick Health",
	[keys.mcmVisualsDescShowPickHealth] =
	"When enabled, displays the active pick's current health in the lockpick list during lockpicking.",
}
