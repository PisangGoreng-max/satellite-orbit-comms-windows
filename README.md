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

*(Add screenshots/plots here once generated, e.g. the ground track image
and the elevation-vs-time plot with shaded comm windows.)*

## Possible next steps

- Pull a live TLE from Celestrak and validate the propagated ground track
  against a known pass prediction (e.g. from Heavens-Above or N2YO).
- Add J2 perturbation for improved long-duration accuracy.
- Switch to a WGS84 ellipsoidal Earth model for the geodetic conversions.
