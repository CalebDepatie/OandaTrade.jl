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

"""
    loadConfig(path::String)

Loads a YAML config

# Arguments
- path: The relative path to the config file
"""
function loadConfig(path::String)
    data = YAML.load(open(path))
    temp = config(data["hostname"], data["streaming_hostname"], data["token"], data["username"], data["account"], data["datetime"])
    return temp
end

"""
    saveConfig(path::String, config::config)

Saves a config as a YAML file

# Arguments
- path: Path to save the config at
- config: The config struct to save
"""
function saveConfig(path::String, config::config)
    #Convert config file to string for saving
    conf_string = string("hostname: ", config.hostname,
                        "\nstreaming_hostname: ", config.streamingHostname,
                        "\ntoken: ", config.token,
                        "\ndatetime: ", config.datetime,
                        "\nusername: ", config.username,
                        "\naccount: ", config.account
                        )
    #YAML.write_file seems to be unreleased, will have to use a custom function
    open(path, "w") do io
        write(io, conf_string)
    end

    return true
end

"""
    changeAccount(config::config, acc::string)

Returns the config with the new account number

# Arguments
- conf: The config file to update
- acc: The string of the account identifier
"""
function changeAccount(conf::config, acc::String)
    temp = config(conf.hostname, conf.streamingHostname, conf.token,
                conf.username, acc, conf.datetime)
    return temp
end

end