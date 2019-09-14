export QBasedPolicy, get_prob

using Flux:softmax

Base.@kwdef struct QBasedPolicy{Q<:AbstractLearner, S<:AbstractActionSelector} <: AbstractPolicy
    learner::Q
    selector::S
end

(π::QBasedPolicy)(obs::Observation) = obs |> π.learner |> π.selector

get_prob(π::QBasedPolicy, s) = get_prob(π.selector, π.learner(s))

function update!(π::QBasedPolicy{<:Union{PrioritizedDQNLearner, RainbowLearner}}, buffer::AbstractTurnBuffer)
    indexed_batch = extract_transitions(buffer, π)
    if !isnothing(indexed_batch)
        inds, batch = indexed_batch
        priorities = update!(π, batch)
        isnothing(priorities) || (priority(buffer)[inds] .= priorities)
    end
end

update!(π::QBasedPolicy, model::AbstractEnvironmentModel;kw...) = update!(π.learner, model;kw...)

#####
# dispatches
#####

extract_transitions(buffer, π::QBasedPolicy) = extract_transitions(buffer, π.learner)

function extract_transitions(buffer::EpisodeTurnBuffer, π::QBasedPolicy{<:TDLearner{<:AbstractQApproximator, :ExpectedSARSA}})
    if length(buffer) > 0
        n = π.learner.n
        transitions = @views (
            states=state(buffer)[max(1, end - n - 1):end-1],
            actions=action(buffer)[max(1, end - n - 1):end-1],
            rewards=reward(buffer)[max(1, end - n):end],
            terminals=terminal(buffer)[max(1, end - n):end],
            next_states=state(buffer)[max(1, end - n):end]
            )
        s′ = transitions.next_states[end]
        merge(transitions, (probs_of_a′ = get_prob(π, s′),))
    else
        nothing
    end
end