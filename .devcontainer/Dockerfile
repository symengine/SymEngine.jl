FROM julia:1.10-rc

RUN apt-get update && apt-get install -y git

RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
