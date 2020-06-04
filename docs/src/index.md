
# Introduction

Julianda is an API wrapper for Oanda's REST-v20 API. This wrapper allows you to access the full functionality of Oanda's API, including configuring your account, creating orders, and checking prices.

**Note: All functions are exported, but the structs are not**

**This Wrapper is currently incomplete and should be treated as such.**

**The docs are currently organized by Functions/structs, this does not allow for the clearest doc reading and will be changed**

## Getting Started

Getting started with Julianda is simple! Install it using:
```Julia
$ Pkg.add("https://github.com/CalebDepatie/Julianda.git")
```
You will need to create a config file with your Oanda account information in the following YAML format:
```YAML
hostname: <<api-fxpractice.oanda.com or api-fxtrade.oanda.com>>
streaming_hostname: <<stream-fxpractice.oanda.com or stream-fxtrade.oanda.com>>
token: <<your token>>
username: <<Account username>>
account: <<Account to initially interact with>>
```
If the config file was setup correctly the following code should work:
```Julia
using Julianda
foo = Julianda.Config.loadConfig("config")
bar = Julianda.Account.getAccount(foo)
println(bar)
```
This will gave you a basic readout of your active account's information! Congratulations on your first Julianda API call!
