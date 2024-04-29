const MAX_TRIP_LENGTH = 800.0

# MARK: real cities
const MANHATTAN_BIKE = RealCitySetup(
    :manhattan,
    :bike,
    SB_City,
    MANHATTAN_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)
const MANHATTAN_WALK = RealCitySetup(
    :manhattan,
    :walk,
    SB_City,
    MANHATTAN_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

const BARCELONA_BIKE = RealCitySetup(
    :barcelona,
    :bike,
    SB_City,
    BARCELONA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)
const BARCELONA_WALK = RealCitySetup(
    :barcelona,
    :bike,
    SB_City,
    BARCELONA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

const VALENCIA_BIKE = RealCitySetup(
    :valencia,
    :bike,
    SB_City,
    VALENCIA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)
const VALENCIA_WALK = RealCitySetup(
    :valencia,
    :bike,
    SB_City,
    VALENCIA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

# MARK: synthetic cities
const MANHATTAN_GRID = RectangleCitySetup(
    :manhattan,
    80.0,
    270.0,
    61.0,
    11.5,
    71.0,
    MANHATTAN_CENTER,
    tz"America/New_York",
    0.0,
    1,
    MTL,
    false,
)

const MANHATTAN_RANDOM = RandomCitySetup(
    :manhattan,
    80 * 270,
    11.5,
    71.0,
    MANHATTAN_CENTER,
    tz"America/New_York",
    1,
    MTL,
    false
)

const BARCELONA_GRID = RectangleCitySetup(
    :barcelona,
    133,
    133,
    45,
    9,
    20,
    BACELONA_CENTER,
    tz"Europe/Madrid",
    0,
    1,
    MAX_TRIP_LENGTH,
    false
)