using Documenter, SymEngine

pages = [
    "index.md",
    "basicUsage.md",
    "apidocs.md",
]

makedocs(sitename="Symengine Julia API Docs"; pages)
