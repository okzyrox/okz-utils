--// Logger
--// CC: okzyrox

--- @type LogLevel = "Error" | "Warn" | "Info" | "Debug"
--- @within Logger
export type LogLevel = "Error" | "Warn" | "Info" | "Debug"

export type LoggerT = {
	Name: string,
	LogLevel: number,
	IndentCharacter: string,
	
	new: (name: string, level: LogLevel?) -> LoggerT,

	SetLogLevel: (self: LoggerT, level: LogLevel) -> (),
	SetIndentCharacter: (self: LoggerT, char: string) -> (),
	
	-- Loggers
	Info: (self: LoggerT, message: string, ...any) -> (),
	Warn: (self: LoggerT, message: string, ...any) -> (),
	Error: (self: LoggerT, message: string, ...any) -> (),
	Debug: (self: LoggerT, message: string, ...any) -> (),
	Log: (self: LoggerT, message: string, ...any) -> (),
	LogWarn: (self: LoggerT, message: string, ...any) -> (),
	Assert: (self: LoggerT, expression: boolean, message: string, ...any) -> (),
	State: (self: LoggerT, message: string, ...any) -> (),
	StateWarn: (self: LoggerT, message: string, ...any) -> (),
}

--- @class Logger
--- A simple logging class, with support for adjustable levels and different means of displaying the messages.
local Logger = {}
Logger.__index = Logger

Logger.Name = "[Logger]"
Logger.LogLevel = 3 -- 1 = Error, 2 = Warn, 3 = Info, 4 = Debug
Logger.IndentCharacter = ""

local LevelsMap = {
	Error = 1,
	Warn = 2,
	Info = 3,
	Debug = 4,
}

--- Create a new Logger instance with the given name and log level.
--- @param name -- The name of the logger, which will be prefixed to all messages. (Optional, defaults to "[Logger]")
--- @param level -- The log level of the logger, which determines which messages will be printed. (Optional, defaults to "Info")
--- @return Logger -- The resulting Logger instance.
function Logger.new(name: string, level: LogLevel?): LoggerT
	local self = setmetatable({}, Logger)
	self.Name = name or self.Name
	if level then
		self.LogLevel = LevelsMap[level] or 3
	end
	return self :: LoggerT
end

--- Set the log level of the logger. Messages with a level lower than this will not be printed.
--- @param level -- The new log level to set, which determines which messages will be printed
--- :::warning
--- Setting the log level to something invalid will not error out or halt, but will throw a warning message.
--- :::
function Logger:SetLogLevel(level: LogLevel)
	local Level = LevelsMap[level]
	if Level then
		self.LogLevel = Level
	else
		warn(`[WARN]: Invalid Log Level {tostring(level)}, Valid levels are: Error, Warn, Info, Debug`)
	end
end

--- Set the indent character(s) for the logger. This will be prefixed to all messages after the logger name and level.
--- @param char -- The character(s) to prefix to all messages after the logger name and level.
function Logger:SetIndentCharacter(char: string)
	self.IndentCharacter = char or ""
end

--- Log's under the "INFO" level.
--- @param message -- The message to log.
function Logger:Info(message: string, ...: any)
	if self.LogLevel >= LevelsMap.Info then
		print(`[{self.Name}] [INFO]: {tostring(message)}`, ...)
	end
end

--- Log's under the "WARN" level.
--- @param message -- The message to log.
function Logger:Warn(message: string, ...: any)
	if self.LogLevel >= LevelsMap.Warn then
		warn(`[{self.Name}] [WARN]: {tostring(message)}`, ...)
	end
end

--- Log's under the "ERROR" level.
--- This will not halt the current thread, but will throw an error message and a traceback into the "warn" output.
--- @param message -- The message to log.
function Logger:Error(message: string, ...: any)
	if self.LogLevel >= LevelsMap.Error then
		pcall(error(`[{self.Name}] [ERROR]: {tostring(message)}`, 2), ...)
		warn(debug.traceback())
	end
end

--- Check's the given expression, and log's as an "ERROR" if it does not pass.
--- @param expression -- The expression to check. If this is falsy, the assertion will fail and an error message will be logged.
--- @param message -- The message to log if the assertion fails.
function Logger:Assert(expression: boolean, message: string, ...: any)
	if not expression then
		self:Error(message, ...)
	end
end

--- Log's under the "DEBUG" level.
--- @param message -- The message to log.
function Logger:Debug(message: string, ...: any)
	if self.LogLevel >= LevelsMap.Debug then
		print(`[{self.Name}] [DEBUG]: {tostring(message)}`, ...)
	end
end

--- Log's a message without any level prefix, but still with the logger name and indent character.
--- @param message -- The message to log.
function Logger:Log(message: string, ...: any)
	print(`[{self.Name}] {self.IndentCharacter}: {tostring(message)}`, ...)
end

--- Log's a message without any level prefix, but still with the logger name and indent character, under the "WARN" level.
--- @param message -- The message to log.
function Logger:LogWarn(message: string, ...: any)
	warn(`[{self.Name}] {self.IndentCharacter}: {tostring(message)}`, ...)
end

--- States a message to the output, with a clear divider for the message.
--- @param message -- The message to log.
--- Example: `--- [Logger] State message. ---`
function Logger:State(message: string, ...: any)
	print(`--- [{self.Name}] {tostring(message)} ---`)
end

--- States a warning message to the output, with a clear divider for the message.
--- @param message -- The message to log.
--- Example: `--- [Logger] State message. ---`
function Logger:StateWarn(message: string, ...: any)
	warn(`--- [{self.Name}] {tostring(message)} ---`)
end

return Logger :: LoggerT