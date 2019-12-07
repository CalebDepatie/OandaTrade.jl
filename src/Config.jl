module Config
export loadConfig, config

import YAML

"Config struct required for connecting to Oanda"
struct config
    hostname::String # Either practice host or live
    streamingHostname::String # Practice or live streaming host
    token::String # Unique user token
    username::String # Account Username
    account::String # Account being actively used
    datetime::String # Accepted datetime format
end

"Loads a YAML config from path"
function loadConfig(path::String)
    data = YAML.load(open(path))
    temp = config(data["hostname"], data["streaming_hostname"], data["token"], data["username"], data["account"], data["datetime"])
    return temp
end

end
