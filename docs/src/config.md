# Config

```@meta
CurrentModule = Julianda.Config
```

Config files are YAML files with the information required to make Oanda API Calls
A sample config file is as follows:

```YAML
hostname: <<api-fxpractice.oanda.com or api-fxtrade.oanda.com>>
streaming_hostname: <<stream-fxpractice.oanda.com or stream-fxtrade.oanda.com>>
token: <<your token>>
datetime: <<Your datetime format of choice IE UNIX>>
username: <<Account username>>
account: <<Account to initially interact with>>
```

## Functions
```@docs
Config.loadConfig
Config.saveConfig
Config.changeAccount
```
