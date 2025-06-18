-- Constants for SRS algorithm
local srsConstants = {
    DEFAULT_EFACTOR = 2.5,
    MIN_EFACTOR = 1.3,
    LEARNING_PHASES = 3,
    FAILURE_INTERVAL_MINUTES = 30,
    LEARNING_FUZZ_FACTOR = 0.10,
    REVIEW_FUZZ_FACTOR = 0.05,
    EFACTOR_REDUCTION_ON_FAIL = 0.20,
    EFACTOR_INCREASE_ON_PASS = 0.1,
    LATENESS_BONUS_MULTIPLIER = 0.1,
    EARLY_REVIEW_THRESHOLD = -0.10,
    LATE_REVIEW_THRESHOLD = 0.10
}

local function getInitialState()
    -- Return the initial state for a new card
    return { n = 0, efactor = srsConstants.DEFAULT_EFACTOR, interval = 0.0 }
end

local function minutesToDays(minutes)
    -- Convert minutes to days
    return minutes / (24.0 * 60.0)
end

local function applyFuzzFactor(interval, fuzzPercentage)
    -- Apply a random fuzz factor to an interval to avoid bunching reviews
    return interval * (1.0 + math.random() * fuzzPercentage)
end

local function calculateLearningInterval(n)
    -- Calculate interval for learning phase based on repetition number
    if n == 1 then
        return minutesToDays(30) -- 30 minutes
    elseif n == 2 then
        return 0.5               -- 12 hours
    else
        return 1.0               -- 1 day
    end
end

local function calculateLatenessBonus(lateness)
    -- Calculate bonus efactor adjustment for late but correct reviews
    if lateness < srsConstants.LATE_REVIEW_THRESHOLD then
        return 0
    end

    local latenessFactory = math.min(1.0, lateness)
    return srsConstants.LATENESS_BONUS_MULTIPLIER * latenessFactory
end

local function calculateReviewInterval(previousN, previousInterval, efactor)
    -- Calculate interval for review phase
    if previousN == 0 then
        return 1 -- First review in 1 day
    elseif previousN == 1 then
        return 6 -- Second review in 6 days
    else
        return math.ceil(previousInterval * efactor)
    end
end

local function handleFailure()
    -- Handle a failed review - reset to learning phase
    return {
        n = 0,
        interval = minutesToDays(srsConstants.FAILURE_INTERVAL_MINUTES)
    }
end

local function handleLearningPhasePass(previousN)
    -- Handle a successful review in the learning phase
    local n = previousN + 1
    local interval = calculateLearningInterval(n)
    return { n = n, interval = interval }
end

local function handleEarlyReview(previous, evaluation)
    -- Handle reviews that were done too early
    local n = previous.n + 1

    -- Calculate weights for blending current and future performance
    local earliness = 1.0 + evaluation.lateness
    local futureWeight = math.min(math.exp(earliness * earliness) - 1.0, 1.0)
    local currentWeight = 1.0 - futureWeight

    -- Conservative efactor for early reviews
    local futureEfactor = math.max(
        srsConstants.MIN_EFACTOR,
        previous.efactor + srsConstants.EFACTOR_INCREASE_ON_PASS
    )

    -- Calculate future interval
    local futureInterval = calculateReviewInterval(previous.n, previous.interval, futureEfactor)

    -- Blend current and future values
    local efactor = previous.efactor * currentWeight + futureEfactor * futureWeight
    local interval = previous.interval * currentWeight + futureInterval * futureWeight

    return { n = n, efactor = efactor, interval = interval }
end

local function handleNormalReviewPass(previous, evaluation)
    -- Handle a normal (on-time or late) successful review
    local n = previous.n + 1

    -- Calculate efactor adjustment with potential lateness bonus
    local latenessBonus = calculateLatenessBonus(evaluation.lateness)
    local eFactorAdjustment = srsConstants.EFACTOR_INCREASE_ON_PASS + latenessBonus
    local efactor = math.max(
        srsConstants.MIN_EFACTOR,
        previous.efactor + eFactorAdjustment
    )

    -- Calculate new interval
    local interval = calculateReviewInterval(previous.n, previous.interval, efactor)

    return { n = n, efactor = efactor, interval = interval }
end

local function handleReviewPhase(previous, evaluation)
    -- Handle reviews in the review phase (n >= 3)
    if not evaluation.passed then
        -- Failed review
        local result = handleFailure()
        local efactor = math.max(
            srsConstants.minEFactor,
            previous.efactor - srsConstants.EFACTOR_REDUCTION_ON_FAIL
        )
        result.efactor = efactor
        return result
    end

    -- Passed review
    if evaluation.lateness >= srsConstants.EARLY_REVIEW_THRESHOLD then
        -- Normal or late review
        return handleNormalReviewPass(previous, evaluation)
    else
        -- Early review
        return handleEarlyReview(previous, evaluation)
    end
end

local function handleLearningPhase(previous, evaluation)
    -- Handle reviews in the learning phase (n < 3)
    if not evaluation.passed then
        -- Failed in learning phase
        local result = handleFailure()
        result.efactor = previous.efactor -- Don't change efactor in learning
        return result
    end

    -- Passed in learning phase
    local result = handleLearningPhasePass(previous.n)
    result.efactor = previous.efactor -- Don't change efactor in learning
    return result
end

local function srsFunc(previous, evaluation)
    --[[
    Adjusted Fresh Cards SRS algorithm (v2.0) - Lua implementation

    Args:
        previous (table or nil): Previous card state with keys 'n', 'efactor', 'interval'
        evaluation (table): Current evaluation with keys 'passed' (boolean), 'lateness'

    Returns:
        table: New card state with 'n', 'efactor', 'interval'
    ]] --
    -- Initialize state if this is a new card
    if previous == nil then
        previous = getInitialState()
    end

    -- Determine which phase we're in and handle accordingly
    local result, fuzzFactor
    if previous.n < srsConstants.LEARNING_PHASES then
        result = handleLearningPhase(previous, evaluation)
        fuzzFactor = srsConstants.LEARNING_FUZZ_FACTOR
    else
        result = handleReviewPhase(previous, evaluation)
        fuzzFactor = srsConstants.REVIEW_FUZZ_FACTOR
    end

    -- Apply fuzz factor to prevent review bunching
    result.interval = applyFuzzFactor(result.interval, fuzzFactor)

    return result
end

return srsFunc
