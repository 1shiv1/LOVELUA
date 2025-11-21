local config = {
    general = {
        particleCount = 300
    },

    window = {
        width = 800,
        height = 800,
        title = "Physics Engine Project"
    },

    physics = {
        gravity = 0.07, --0.07 default
        airFriction = 0.02,
        BroadphaseGridSize = 800, -- in pixels, anything over 400 is useless. Best in increments divisible into winsizes
        BroadphasePasses = 3 --max re-checks for preventing the overshooting problem.
    }
}

return config