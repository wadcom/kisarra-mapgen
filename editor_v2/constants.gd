# Size of each cell in pixels for grid rendering
const CELL_SIZE_PX: int = 10

# Size of each cell in kilometers (for distance calculations)
const CELL_SIDE_KMS: float = 20.0

# Grid line color
const GRID_LINE_COLOR := Color(0.3, 0.3, 0.3, 1.0)

# Grid background color
const GRID_BACKGROUND_COLOR := Color(0.15, 0.15, 0.15, 1.0)

# Terrain colors
const TERRAIN_COLOR_SAND := Color(0.905882, 0.796078, 0.219608, 1.0)
const TERRAIN_COLOR_MOUNTAIN := Color(0.481474, 0.281624, 0.0667262, 1.0)

# Base colors
const BASE_COLOR := Color.BLUE

# Betirium colors
const BETIRIUM_DENSITY_COLOR := Color(0.65098, 0.25098, 0.137255, 1.0)
const BETIRIUM_SATELLITE_COLOR := Color(0.85, 0.35, 0.2, 1.0)
const BETIRIUM_EXTRA_COLOR := Color(0.9, 0.45, 0.15, 1.0)

# Constraint visualization colors (semi-transparent)
const CONSTRAINT_EDGE_BUFFER_COLOR := Color(0.3, 0.3, 0.3, 0.3)
const CONSTRAINT_DEAD_ZONE_COLOR := Color(0.4, 0.4, 0.4, 0.2)
const CONSTRAINT_INTER_BASE_COLOR := Color(0.0, 0.5, 1.0, 0.15)
