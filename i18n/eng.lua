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
	[keys.mcmDifficultyLabelSecurityFactor] = "Security Factor",
	[keys.mcmDifficultyDescSecurityFactor] =
	"How much the security skill contributes to the sweet spot size. Higher values reward skill more.",
	[keys.mcmDifficultyLabelLockLevelFactor] = "Lock Level Factor",
	[keys.mcmDifficultyDescLockLevelFactor] =
	"How much the lock level shrinks the sweet spot. Higher values make locks harder.",
	[keys.mcmDifficultyLabelQualityFactor] = "Quality Factor",
	[keys.mcmDifficultyDescQualityFactor] =
	"How much pick quality contributes to the sweet spot size. Higher values make pick choice matter more.",
	[keys.mcmDifficultyLabelMaxRadius] = "Max Sweet Spot Radius (degrees)",
	[keys.mcmDifficultyDescMaxRadius] = "Caps the sweet spot size regardless of skill or pick quality.",
	[keys.mcmDifficultyLabelGradientFactor] = "Gradient Factor",
	[keys.mcmDifficultyDescGradientFactor] =
	"Width of the gradient zone as a multiplier of the sweet spot radius.",
	[keys.mcmDifficultyCategoryPickDamage] = "Pick Damage",
	[keys.mcmDifficultyLabelBaseRate] = "Base Damage Rate",
	[keys.mcmDifficultyDescBaseRate] =
	"Pick damage per second when the sweet spot is at maximum size. Scales up as the sweet spot shrinks.",
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
}
