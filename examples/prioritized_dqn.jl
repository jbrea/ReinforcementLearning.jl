using Flux
using ReinforcementLearningEnvironments
using ReinforcementLearning

env = CartPoleEnv()
ns, na = length(observation_space(env)), length(action_space(env))
model = Chain(
    Dense(ns, 128, relu),
    Dense(128, 128, relu),
    Dense(128, na)
)

app = NeuralNetworkQ(model, ADAM(0.0005))
selector = EpsilonGreedySelector(0.01;decay_steps=500, decay_method=:exp)

hook=TotalRewardPerEpisode()

buffer =  circular_PRTSA_buffer(;capacity=10000, state_eltype=Vector{Float64}, state_size=(ns,))

function loss_cal(ŷ, y)
    batch_losses = (ŷ .- y).^2
    loss = sum(batch_losses) * 1 // length(y)
    (loss=loss, batch_losses=batch_losses)
end

init_loss = (loss=param(0.f0), batch_losses=param(zeros(Float32,32)))

learner = QLearner(app, loss_cal, init_loss;γ=0.99f0)
agent = DQN(learner, buffer, selector;γ=0.99)
train(agent, env, StopAfterStep(10000);hook=hook)