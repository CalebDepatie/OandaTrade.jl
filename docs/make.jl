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
                            "position.md", "transaction.md"]]
)

deploydocs(
    repo = "github.com/CalebDepatie/Julianda.git",
    devbranch = "dev",
    versions = ["stable" => "v^", "v#.#", "dev"]
    )
