# Julianda

[![Build Status][travis-ci-badge]][travis-ci]
[![Code Cov][code-cov-badge]][code-cov]
[![TODOs][todos-badge]][todos]
[![License][license-badge]][license]

Julianda is a API wrapper for the Oanda REST 2.0 API. The current version is fairly barebones, but it's planned for it to have additional features that can be optionally enabled by using additional libraries.

If you want to see what's going on with development check out the roadmap [here.](https://github.com/CalebDepatie/Julianda/projects/2)

## Documentation
 - [![Stable][docs-stable-badge]][docs-stable] &mdash; Most recent stable version (master branch)
 - [![Dev][docs-dev-badge]][docs-dev] &mdash; Latest updated version, only use if you need specific features not yet in the stable release (dev branch)

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
If the config file was setup correctly the following code should work and output your Oanda account info:
```Julia
using Julianda
foo = Julianda.Config.loadConfig("config")
bar = Julianda.Account.getAccount(foo)
println(bar)
```

[travis-ci]: https://travis-ci.org/CalebDepatie/Julianda
[travis-ci-badge]: https://travis-ci.org/CalebDepatie/Julianda.svg?branch=master

[code-cov]: https://codecov.io/gh/CalebDepatie/Julianda
[code-cov-badge]: https://codecov.io/gh/CalebDepatie/Julianda/branch/master/graph/badge.svg

[docs-stable]: https://calebdepatie.github.io/Julianda/stable
[docs-stable-badge]: https://img.shields.io/badge/docs-stable-blue.svg

[docs-dev]: https://calebdepatie.github.io/Julianda/dev
[docs-dev-badge]: https://img.shields.io/badge/docs-dev-blue.svg

[todos]: https://www.tickgit.com/browse?repo=github.com/CalebDepatie/Julianda
[todos-badge]: https://badgen.net/https/api.tickgit.com/badgen/github.com/CalebDepatie/Julianda

[license]: https://github.com/CalebDepatie/Julianda/blob/master/LICENSE
[license-badge]:https://img.shields.io/github/license/CalebDepatie/Julianda
