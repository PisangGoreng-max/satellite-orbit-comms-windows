%% STEP 3-4: Ground Station Geometry and Line-of-Sight (LOS) Access
% Continues from step1_propagator.m. Assumes r_eci, v_eci, t, mu_earth,
% R_earth are already in the workspace (either re-run step 1 first, or
% run this script right after it in the same session).

%% --- Ground Station Location (geodetic coordinates) ---
% Example: a ground station in Medan, Indonesia. Swap these for wherever
% you actually want to track passes over.

station_lat = 3.5952;      % degrees, geodetic latitude
station_lon = 98.6722;     % degrees, longitude
station_alt = 0.025;       % km above sea level (~25 m)

%% --- Convert ground station geodetic coords -> ECEF (fixed point on Earth) ---
% We treat Earth as a sphere here for simplicity (fine for LEO access
% calculations). For higher precision you'd use the WGS84 ellipsoid model.

lat_r = deg2rad(station_lat);
lon_r = deg2rad(station_lon);
r_station_mag = R_earth + station_alt;

station_ecef = r_station_mag * [cos(lat_r)*cos(lon_r); ...
                                  cos(lat_r)*sin(lon_r); ...
                                  sin(lat_r)];

%% --- Convert satellite ECI positions -> ECEF at each time step ---
% ECI is fixed relative to the stars. ECEF rotates with the Earth.
% The two frames are related by Earth's rotation angle at each instant,
% called GMST (Greenwich Mean Sidereal Time).
%
% For this demo we assume propagation starts at t=0 with GMST=0
% (i.e. ECI and ECEF are aligned at epoch). Earth's rotation rate is
% ~360.9856 deg per solar day (sidereal rate, slightly faster than 360/day).

omega_earth = 7.2921150e-5;   % Earth's rotation rate [rad/s]

n = length(t);
r_ecef = zeros(n, 3);

for k = 1:n
    theta = omega_earth * t(k);   % Earth rotation angle since epoch [rad]
    Rz = [ cos(theta)  sin(theta) 0; ...
          -sin(theta)  cos(theta) 0; ...
           0           0          1];
    r_ecef(k, :) = (Rz * r_eci(k, :)')';
end

%% --- Compute range vector, elevation angle, and azimuth at each time step ---
% Elevation angle is measured from the station's *local horizon*, so we
% need to rotate the range vector (satellite - station) into a local
% East-North-Up (ENU) frame centered on the station, not just use ECEF
% directly.

elevation = zeros(n, 1);
azimuth   = zeros(n, 1);
range_km  = zeros(n, 1);

% Rotation matrix ECEF -> ENU at the station's location
R_ecef2enu = [-sin(lon_r)             cos(lon_r)            0; ...
              -sin(lat_r)*cos(lon_r) -sin(lat_r)*sin(lon_r)  cos(lat_r); ...
               cos(lat_r)*cos(lon_r)  cos(lat_r)*sin(lon_r)  sin(lat_r)];

for k = 1:n
    rho_ecef = r_ecef(k, :)' - station_ecef;   % vector from station to satellite
    rho_enu = R_ecef2enu * rho_ecef;

    east  = rho_enu(1);
    north = rho_enu(2);
    up    = rho_enu(3);

    range_km(k) = norm(rho_enu);
    elevation(k) = asind(up / range_km(k));       % elevation angle [deg]
    azimuth(k)   = mod(atan2d(east, north), 360);  % azimuth [deg], 0=N
end

%% --- Determine rise/set times (communication windows) ---
% A pass is "visible" whenever elevation crosses above the minimum mask
% angle. We scan for sign changes to find rise and set events.

min_elevation = 10;   % degrees; typical mask angle to avoid horizon noise

visible = elevation >= min_elevation;
rise_idx = find(diff(visible) == 1) + 1;   % transitions from 0 -> 1
set_idx  = find(diff(visible) == -1);      % transitions from 1 -> 0

% Handle edge case: satellite already visible at t=0, or still visible at t=end
if visible(1)
    rise_idx = [1; rise_idx];
end
if visible(end)
    set_idx = [set_idx; n];
end

fprintf('\n--- Communication Windows (elevation mask = %d deg) ---\n', min_elevation);
fprintf('%-20s %-20s %-12s %-10s\n', 'Rise (AOS)', 'Set (LOS)', 'Duration', 'Max Elev');
for p = 1:length(rise_idx)
    t_rise = t(rise_idx(p));
    t_set  = t(set_idx(p));
    dur_min = (t_set - t_rise) / 60;
    max_el = max(elevation(rise_idx(p):set_idx(p)));

    fprintf('%-20s %-20s %-12s %-10s\n', ...
        duration(0,0,t_rise), duration(0,0,t_set), ...
        sprintf('%.1f min', dur_min), sprintf('%.1f deg', max_el));
end
fprintf('\nTotal passes in 48 hours: %d\n', length(rise_idx));

%% --- Plot: elevation angle vs time, with visibility windows highlighted ---
figure('Name', 'Elevation Angle vs Time');
plot(t/3600, elevation, 'b-', 'LineWidth', 1); hold on;
yline(min_elevation, 'r--', 'Mask angle', 'LineWidth', 1);
yline(0, 'k:');

for p = 1:length(rise_idx)
    xline(t(rise_idx(p))/3600, 'g-', 'Alpha', 0.3);
    xline(t(set_idx(p))/3600, 'm-', 'Alpha', 0.3);
end

xlabel('Time [hours]');
ylabel('Elevation angle [deg]');
title(sprintf('Satellite Elevation from Ground Station (%.2f, %.2f)', station_lat, station_lon));
grid on;
ylim([-90 90]);