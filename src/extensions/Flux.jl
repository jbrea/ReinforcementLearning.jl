export Descent, InvDecay

using CuArrays

import Flux.Optimise: apply!, Descent, InvDecay, gpu

function apply!(o::Descent, x, δ::Number)
    o.eta * δ
end

function apply!(o::InvDecay, x, δ::Number)
    γ = o.gamma
    n = get!(o.state, x, 0)
    o.state[x] = n + 1
    δ / (1 + γ * n)
end

gpu(a::SubArray) = CuArray{Float32}(a)