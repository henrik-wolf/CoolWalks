const MAX_TRIP_LENGTH = 2400.0

# MARK: real cities with buildings
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
    :walk,
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
    :walk,
    SB_City,
    VALENCIA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

# MARK: Real cities with buildings and parks
const MANHATTAN_PARK_BIKE = RealCitySetup(
    :manhattan,
    :bike,
    SBP_City,
    MANHATTAN_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)
const MANHATTAN_PARK_WALK = RealCitySetup(
    :manhattan,
    :walk,
    SBP_City,
    MANHATTAN_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

const BARCELONA_PARK_BIKE = RealCitySetup(
    :barcelona,
    :bike,
    SBP_City,
    BARCELONA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)
const BARCELONA_PARK_WALK = RealCitySetup(
    :barcelona,
    :walk,
    SBP_City,
    BARCELONA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

const VALENCIA_PARK_BIKE = RealCitySetup(
    :valencia,
    :bike,
    SBP_City,
    VALENCIA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)
const VALENCIA_PARK_WALK = RealCitySetup(
    :valencia,
    :walk,
    SBP_City,
    VALENCIA_CENTER,
    MAX_TRIP_LENGTH,
    true,
    false
)

const MANHATTAN_AVERAGE_HEIGHT = 40.0
const BARCELONA_AVERAGE_HEIGHT = 18.5
const VALENCIA_AVERAGE_HEIGHT = 16.7

# MARK: synthetic cities
const MANHATTAN_GRID = RectangleCitySetup(
    :manhattan,
    80.0,
    270.0,
    61.0,
    11.5,
    MANHATTAN_AVERAGE_HEIGHT,
    MANHATTAN_CENTER,
    tz"America/New_York",
    0.0,
    1,
    MAX_TRIP_LENGTH,
    false,
)

const MANHATTAN_RANDOM = RandomCitySetup(
    :manhattan,
    80 * 270,
    11.5,
    MANHATTAN_AVERAGE_HEIGHT,
    MANHATTAN_CENTER,
    tz"America/New_York",
    1,
    MAX_TRIP_LENGTH,
    false
)

const BARCELONA_GRID = RectangleCitySetup(
    :barcelona,
    133,
    133,
    45,
    9,
    BARCELONA_AVERAGE_HEIGHT,
    BARCELONA_CENTER,
    tz"Europe/Madrid",
    0,
    1,
    MAX_TRIP_LENGTH,
    false
)