push!(LOAD_PATH,"../src/")

import Pkg
Pkg.add("Documenter")

using Documenter, Julianda

makedocs(
    modules = [Julianda],
    sitename = "Julianda",
    format = Documenter.HTML(),
    pages = ["Introduction" => "index.md",
            "Endpoints" => ["account.md", "config.md"]]
)

deploydocs(repo = "github.com/CalebDepatie/Julianda.git")
