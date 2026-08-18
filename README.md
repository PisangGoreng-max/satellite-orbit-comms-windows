# Satellite Orbit Propagation & Ground Station Communication Windows

A MATLAB pipeline that propagates a satellite's orbit from its Keplerian
elements, then computes when it's visible (line-of-sight) from a fixed
ground station on Earth. Built as a self-directed project to apply orbital
mechanics and numerical methods outside of coursework.

## What it does

1. **Orbit propagation** (`step1_propagator.m`) — Converts classical
   Keplerian orbital elements (semi-major axis, eccentricity, inclination,
   RAAN, argument of perigee) into an ECI (Earth-Centered Inertial) state
   vector, then numerically integrates the two-body equation of motion
   using `ode45` over a 48-hour window.

2. **Ground station visibility** (`step2_ground_station_los.m`) — Converts
   satellite positions from ECI to ECEF (Earth-Centered Earth-Fixed),
   computes elevation/azimuth/range from a specified ground station using
   an ENU (East-North-Up) local frame, and detects rise/set events to
   identify discrete communication windows above a 10° elevation mask.

3. **Visualization** (`step3_ground_track_visualization.m`) — Produces a
   2D ground track (with communication windows highlighted), an animated
   3D globe showing the satellite orbiting a rotating Earth, and a
   polished elevation-vs-time plot with shaded pass windows.

## Example orbital parameters

The current example uses representative ISS-like orbital elements
(~420 km altitude, 51.6° inclination) and a ground station located in
Medan, Indonesia. Both are easy to swap, see "How to run" below.

## Methodology notes

- Two-body dynamics only (no J2 perturbation, drag, or third-body
  effects). This is standard for a first-pass propagator but means
  long-duration accuracy will drift compared to a full perturbation model.
- `ode45` is used with tight tolerances (RelTol/AbsTol = 1e-10) since
  orbital propagation is sensitive to integration error over time.

## Known limitations (being upfront about these)

This is a self-directed project without external validation, so I'm
stating the simplifications explicitly rather than letting them hide in
the code:

- **Spherical Earth assumption.** Ground station geodetic-to-ECEF
  conversion and the ground track calculation both treat Earth as a
  perfect sphere, not the WGS84 ellipsoid. This introduces small
  position errors (up to a few km) versus a full ellipsoidal model.
- **GMST = 0 at epoch.** The ECI-to-ECEF rotation assumes the two frames
  are aligned at t = 0, rather than using the actual sidereal time for a
  real calendar date. This means the ground track is internally
  consistent but not tied to real-world pass times.
- **Representative orbital elements, not a live TLE.** The current run
  uses illustrative values rather than a current TLE pulled from
  Celestrak, so results haven't yet been cross-checked against a
  published/independent source. Swapping in a real TLE and comparing
  against a known pass prediction is the natural next validation step.

## How to run

Requires MATLAB (no additional toolboxes beyond base MATLAB, `ode45` is
built in).

1. Run `step1_propagator.m` first, this populates the workspace with
   `r_eci`, `v_eci`, `t`, `mu_earth`, `R_earth`.
2. Run `step2_ground_station_los.m` in the same session, edit
   `station_lat` / `station_lon` / `station_alt` to change ground station
   location.
3. Run `step3_ground_track_visualization.m` for the ground track, 3D
   animation, and polished elevation plot.

## Results

Simulation run for the ISS (a = 6798 km, e = 0.0006, i = 51.6°) against a
ground station at 3.60°N, 98.67°E, propagated over 48 hours.

### Orbit Propagation
![ISS Orbit](images/orbit_propagation.png)

Two-body propagation via `ode45`, plotted in the ECI frame. The orbit
holds a constant radius of ~6798 km (eccentricity of only 0.0006 keeps
it very close to circular), confirming stable, physically consistent
propagation.

### Ground Track
![Ground Track](images/ground_track.png)

The satellite's ground track forms the characteristic sinusoidal weave
pattern for a 51.6° inclined orbit, bounded between ±51.6° latitude.
Green segments mark the 6 arcs where the satellite passed within
line-of-sight of the ground station.

### Animated 3D Orbit
![3D Orbit](images/animated_globe.png)

Full animation shows the satellite orbiting a rotating Earth in real
time, with the ground station (red) staying fixed to the surface as
Earth rotates beneath the orbit plane.

### Elevation Angle Over Time
![Elevation Plot](images/elevation_plot.png)

Each spike corresponds to one orbital pass (~92 min period). Shaded
green regions mark the 6 windows where elevation exceeded the 10°
mask angle.

### Communication Windows (48-hour window, 10° elevation mask)

| Rise (AOS) | Set (LOS) | Duration | Max Elevation |
|---|---|---|---|
| 01:15:00 | 01:21:00 | 6.0 min | 43.2° |
| 12:50:00 | 12:56:00 | 6.0 min | 42.4° |
| 24:31:00 | 24:31:00 | 0.0 min | 10.6° |
| 26:05:00 | 26:10:00 | 5.0 min | 23.7° |
| 36:05:00 | 36:06:00 | 1.0 min | 10.7° |
| 37:40:00 | 37:45:00 | 5.0 min | 24.6° |

**Total: 6 passes in 48 hours**, averaging roughly 1 pass every 8 hours,
with usable pass durations of 1–6 minutes and peak elevations ranging
from a low grazing pass (10.6°) to a strong near-overhead pass (43.2°).

## Possible next steps

- Pull a live TLE from Celestrak and validate the propagated ground track
  against a known pass prediction (e.g. from Heavens-Above or N2YO).
- Add J2 perturbation for improved long-duration accuracy.
- Switch to a WGS84 ellipsoidal Earth model for the geodetic conversions.
- Extend to multiple ground stations tracked simultaneously.
