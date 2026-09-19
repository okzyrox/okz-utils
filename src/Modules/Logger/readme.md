# Logger

## Usage

### Creating and Using a Logger
```lua

local Logger = require(path.to.Logger)

local LoggerInstance = Logger.new("Example", --[[LogLevel]])
-- local LoggerInstance = Logger.new("Example", "Error")

--...
LoggerInstance:Info("Something happened")
LoggerInstance:Debug("Something interesting happened")
LoggerInstance:Warn("Something happened badly!")
```