# Global
extends Node

onready var all_completed = ProjectSettings.get("levels/all_completed")
var completed_levels = {}
var next_level = 1
var has_played_ending = false

const MAX_LEVEL = 25
const ENDING_LEVEL = -1

var levels = {
	1: preload("res://levels/LevelSplitIntro.tscn"),
	2: preload("res://levels/LevelMergeIntro.tscn"),
	3: preload("res://levels/LevelSequence.tscn"),
	4: preload("res://levels/LevelTetrisStarch.tscn"),
	5: preload("res://levels/LevelTower.tscn"),
	6: preload("res://levels/LevelJumpSplit.tscn"),
	7: preload("res://levels/LevelTable.tscn"),
	8: preload("res://levels/LevelHouse.tscn"),
	9: preload("res://levels/LevelElevator.tscn"),
	10: preload("res://levels/LevelZipper.tscn"),
	11: preload("res://levels/LevelSteppyStep.tscn"),
	12: preload("res://levels/LevelHorizontal.tscn"),
	13: preload("res://levels/LevelPlank.tscn"),
	14: preload("res://levels/LevelFlyingSplit.tscn"),
	15: preload("res://levels/LevelBridge.tscn"),
	16: preload("res://levels/LevelLeap.tscn"),
	17: preload("res://levels/LevelViper.tscn"),
	18: preload("res://levels/LevelBuggyStarch.tscn"),
	19: preload("res://levels/LevelThereAndBackAgain.tscn"),
	20: preload("res://levels/LevelFrog.tscn"),
	21: preload("res://levels/LevelRightArrow.tscn"),
	22: preload("res://levels/LevelBear.tscn"),
	23: preload("res://levels/LevelChaseLower.tscn"),
	24: preload("res://levels/LevelStarchNest.tscn"),
	25: preload("res://levels/LevelSkydive.tscn"),
	-1: preload("res://levels/LevelEnding.tscn")
}
