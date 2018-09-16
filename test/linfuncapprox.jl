using Random: seed!
import ReinforcementLearning: preprocessstate
using ReinforcementLearningBase
using ReinforcementLearningEnvironmentDiscrete

struct OneHotPreprocessor 
    ns::Int64
end

preprocessstate(p::OneHotPreprocessor, s) = Float64[i == s for i in 1:p.ns]

using Flux
struct Id end 
(l::Id)(x) = x

@testset "linfuncapprox" begin
    ns = 10; na = 4;
    env = MDP(ns = ns, na = na, init = "deterministic")
    policy = ForcedPolicy(rand(1:na, 200))
    learner = DQN(Linear(ns, na), replaysize = 1, updatetargetevery = 1, 
                  updateevery = 1, startlearningat = 1, 
                  opttype = x -> Flux.SGD(x, .1/2), 
                  minibatchsize = 1, doubledqn = false)
    x = RLSetup(learner = learner, 
                preprocessor = OneHotPreprocessor(ns),
                policy = policy,
                environment = env, 
                callbacks = [EvaluationPerT(10^3, MeanReward()), RecordAll()],
                stoppingcriterion = ConstantNumberSteps(60))
    x2 = RLSetup(learner = QLearning(λ = 0, γ = .99, initvalue = 0., α = .1), 
                 policy = policy,
                 environment = env, 
                 callbacks = [EvaluationPerT(10^3, MeanReward()), RecordAll()], 
                 stoppingcriterion = ConstantNumberSteps(60))
    seed!(445)
    reset!(env)
    learn!(x)
    seed!(445)
    reset!(env)
    x2.policy.t = 1
    learn!(x2)
    @test x.learner.net.W.data ≈ x2.learner.params

    ns = 10; na = 4;
    env = MDP(ns = ns, na = na, init = "deterministic")
    policy = ForcedPolicy(rand(1:na, 200))
    learner = DeepActorCritic(net = Id(), nh = 10, na = 4, αcritic = 0.,
                              opttype = x -> Flux.SGD(x, .1), nsteps = 4)
    x = RLSetup(learner = learner, 
                preprocessor = OneHotPreprocessor(ns),
                policy = policy,
                environment = env, 
                callbacks = [EvaluationPerT(10^3, MeanReward()), RecordAll()],
                stoppingcriterion = ConstantNumberSteps(5))
    x2 = RLSetup(learner = ActorCriticPolicyGradient(nsteps = 4, αcritic = 0.), 
                 policy = policy,
                 environment = env, 
                 callbacks = [EvaluationPerT(10^3, MeanReward()), RecordAll()], 
                 stoppingcriterion = ConstantNumberSteps(5))
    seed!(445)
    reset!(env)
    learn!(x)
    seed!(445)
    reset!(env)
    x2.policy.t = 1
    learn!(x2)
    @test x.learner.policylayer.W.data ≈ x2.learner.params
end