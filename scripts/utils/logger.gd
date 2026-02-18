# 统一日志工具
# 发布版自动静默，避免日志泄露和性能损耗
# 使用方式: Logger.debug("MyTag", "消息内容")
class_name Logger
extends RefCounted

## 日志级别
enum Level {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3
}

## 当前最低输出级别（发布版自动设为 ERROR）
static var min_level: Level = Level.DEBUG if OS.is_debug_build() else Level.ERROR

## 调试日志 — 仅开发环境输出
static func debug(tag: String, msg: String) -> void:
	if min_level <= Level.DEBUG:
		print("[%s] %s" % [tag, msg])

## 信息日志
static func info(tag: String, msg: String) -> void:
	if min_level <= Level.INFO:
		print("[%s] %s" % [tag, msg])

## 警告日志
static func warn(tag: String, msg: String) -> void:
	if min_level <= Level.WARN:
		push_warning("[%s] %s" % [tag, msg])

## 错误日志
static func error(tag: String, msg: String) -> void:
	push_error("[%s] %s" % [tag, msg])
