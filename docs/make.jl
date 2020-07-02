push!(LOAD_PATH,"../src/")

import Pkg
Pkg.add("Documenter")

using Documenter, OandaTrade

makedocs(
    modules = [OandaTrade],
    sitename = "OandaTrade.jl",
    format = Documenter.HTML(),
    pages = ["Introduction" => "index.md",
            "Endpoints" => ["config.md", "account.md", "instrument.md",
                            "order.md", "position.md", "pricing.md",
                            "trade.md", "transaction.md"]]
)

deploydocs(
    repo = "github.com/CalebDepatie/OandaTrade.jl.git",
    versions = ["stable" => "v^", "v#.#", "dev"]
    )
