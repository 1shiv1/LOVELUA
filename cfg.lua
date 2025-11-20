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
        BroadphaseGridSize = 200, -- in pixels, anything over 400 is useless. Best in increments divisible into winsizes
        BroadphasePasses = 1 --how many times collision is checked per frame (prevents soup, as 1 pass can leave stuf finside eachother after movement)
    }
}

return config