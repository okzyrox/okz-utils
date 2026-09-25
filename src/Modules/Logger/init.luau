--// Logger

-- return require(script.Logger)
local REQ_MODULE = require(script.Logger)

export type LoggerT = REQ_MODULE.LoggerT
export type LogLevel = REQ_MODULE.LogLevel

return REQ_MODULE
