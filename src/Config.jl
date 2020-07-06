module Config

export loadConfig, saveConfig, changeAccount

import YAML

"""
Config struct required for connecting to Oanda

# Fields
- 'hostname::String': The hostname to direct the api to (practice or live)
- 'streamingHostname::String': Streaming version of the hostname
- 'token::String': The unique user token
- 'username::String': Account username
- 'account::String': Account presently being actively used
- 'datetime::String': Accepted datetime format (should not be actively changed)

"""
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

Returns object of type 'config'

# Arguments
- 'path::String': The relative path to the config file
"""
function loadConfig(path::String)
    data = YAML.load(open(path))
    temp = config(
        data["hostname"],
        data["streaming_hostname"],
        data["token"],
        data["username"],
        data["account"],
        "RFC3339",
    )
    return temp
end

"""
    saveConfig(path::String, config::config)

Saves a config as a YAML file

Returns true on success

# Arguments
- 'path::String': Path to save the config at
- 'config::config': The config struct to save
"""
function saveConfig(path::String, config::config)
    #Convert config file to string for saving
    conf_string = string(
        "hostname: ",
        config.hostname,
        "\nstreaming_hostname: ",
        config.streamingHostname,
        "\ntoken: ",
        config.token,
        "\nusername: ",
        config.username,
        "\naccount: ",
        config.account,
    )
    #YAML.write_file seems to be unreleased, will have to use a custom function
    open(path, "w") do io
        write(io, conf_string)
    end

    return true
end

"""
    changeAccount(config::config, account::string)

Change the active account

Returns object of type 'config'

# Arguments
- 'config::config': The config file to update
- 'account::String': The string of the account identifier
"""
function changeAccount(config::config, account::String)
    temp = config(
        conf.hostname,
        conf.streamingHostname,
        conf.token,
        conf.username,
        acc,
        conf.datetime,
    )
    return temp
end

end
