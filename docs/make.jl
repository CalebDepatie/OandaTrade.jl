push!(LOAD_PATH,"../src/")

import Pkg
Pkg.add("Documenter")

using Documenter, Julianda

makedocs(
    modules = [Julianda],
    sitename = "Julianda",
    format = Documenter.HTML(),
    pages = ["Introduction" => "index.md",
            "Endpoints" => ["config.md", "account.md", "instrument.md",
                            "order.md", "position.md", "pricing.md",
                            "trade.md", "transaction.md"]]
)

deploydocs(
    repo = "github.com/CalebDepatie/Julianda.git",
    versions = ["stable" => "v^", "v#.#", "dev"]
    )
