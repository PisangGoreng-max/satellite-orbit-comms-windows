%% STEP 5: Ground Track, Animated 3D Globe, and Polished Elevation Plot
% Continues from step1_propagator.m and step2_ground_station_los.m.
% Assumes r_eci, r_ecef, t, elevation, rise_idx, set_idx, station_lat,
% station_lon, R_earth are already in the workspace.

%% --- Convert satellite ECEF positions -> geodetic lat/lon (ground track) ---
% We're treating Earth as a sphere (consistent with earlier steps), so
% this is the simple spherical conversion. Longitude wraps naturally via
% atan2; latitude is the angle up from the equatorial plane.

sat_lon = atan2d(r_ecef(:,2), r_ecef(:,1));                     % [-180, 180]
sat_lat = atan2d(r_ecef(:,3), sqrt(r_ecef(:,1).^2 + r_ecef(:,2).^2));

%% --- 2D Ground Track Plot (flat map view) ---
% This is often more useful than the 3D globe for actually reading
% lat/lon values, and it's a standard way to present orbit tracks.

figure('Name', 'Ground Track (2D)');
hold on;

% Ground track tends to wrap around +/-180 longitude, which draws ugly
% horizontal lines if plotted naively. Break the line wherever it jumps.
lon_plot = sat_lon; 
jump = [false; abs(diff(lon_plot)) > 180];
lon_plot(jump) = NaN;

plot(lon_plot, sat_lat, 'b-', 'LineWidth', 0.75);
plot(station_lon, station_lat, 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
text(station_lon+3, station_lat, 'Ground Station', 'Color', 'r', 'FontWeight', 'bold');

% Highlight the ground track during each communication window in green
for p = 1:length(rise_idx)
    idx = rise_idx(p):set_idx(p);
    lon_seg = sat_lon(idx);
    plot(lon_seg, sat_lat(idx), 'g-', 'LineWidth', 2.5);
end

xlim([-180 180]); ylim([-90 90]);
xlabel('Longitude [deg]'); ylabel('Latitude [deg]');
title('Satellite Ground Track (green = communication windows)');
grid on;
set(gca, 'XTick', -180:30:180, 'YTick', -90:30:90);
axis equal; xlim([-180 180]); ylim([-90 90]);

%% --- 3D Animated Globe ---
% This shows the satellite physically orbiting a rotating Earth, with a
% fading trail behind it, and the ground station marked as a fixed point
% on the surface (fixed in ECEF, so it must be rotated into ECI frame
% at each animation frame to stay correctly plotted).

figure('Name', 'Animated 3D Orbit');
[xs, ys, zs] = sphere(40);
earth_surf = surf(xs*R_earth, ys*R_earth, zs*R_earth, ...
    'FaceColor', [0.3 0.6 1], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on; axis equal; grid on;
xlabel('X [km]'); ylabel('Y [km]'); zlabel('Z [km]');
title('Animated ISS Orbit with Ground Track');
xlim([-8000 8000]); ylim([-8000 8000]); zlim([-8000 8000]);
view(45, 25);

sat_marker = plot3(r_eci(1,1), r_eci(1,2), r_eci(1,3), ...
    'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
trail_line = plot3(r_eci(1,1), r_eci(1,2), r_eci(1,3), 'y-', 'LineWidth', 1.5);
station_marker = plot3(station_ecef(1), station_ecef(2), station_ecef(3), ...
    'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 10);

trail_length = 150;   % number of trailing points to show (150 * 60s = 2.5 hr trail)
frame_step = 10;      % skip frames for animation speed (plot every 10th sample)

for k = 2:frame_step:length(t)
    % Update satellite marker position
    set(sat_marker, 'XData', r_eci(k,1), 'YData', r_eci(k,2), 'ZData', r_eci(k,3));

    % Update fading trail (last N points only, for a clean visual)
    trail_start = max(1, k - trail_length);
    set(trail_line, 'XData', r_eci(trail_start:k,1), ...
                     'YData', r_eci(trail_start:k,2), ...
                     'ZData', r_eci(trail_start:k,3));

    % Rotate the ground station marker (it's fixed in ECEF, so its ECI
    % position changes as Earth rotates beneath the fixed orbit frame)
    theta = omega_earth * t(k);
    Rz_inv = [cos(theta) -sin(theta) 0; sin(theta) cos(theta) 0; 0 0 1];
    station_eci_now = Rz_inv * station_ecef;
    set(station_marker, 'XData', station_eci_now(1), ...
                         'YData', station_eci_now(2), ...
                         'ZData', station_eci_now(3));

    % Rotate the Earth surface itself to match
    rotate(earth_surf, [0 0 1], rad2deg(omega_earth * t(frame_step)), [0 0 0]);

    drawnow limitrate;
end

%% --- Polished Elevation Plot with Shaded Communication Windows ---
figure('Name', 'Elevation Angle (Polished)');
hold on;

% Shade each communication window
for p = 1:length(rise_idx)
    x_patch = [t(rise_idx(p)) t(set_idx(p)) t(set_idx(p)) t(rise_idx(p))] / 3600;
    y_patch = [-90 -90 90 90];
    patch(x_patch, y_patch, [0.7 1 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
end

plot(t/3600, elevation, 'b-', 'LineWidth', 1.2);
yline(min_elevation, 'r--', 'LineWidth', 1.2);
yline(0, 'k:');

xlabel('Time [hours]');
ylabel('Elevation angle [deg]');
title(sprintf('Elevation from Ground Station (%.2f°, %.2f°) — %d passes over 48h', ...
    station_lat, station_lon, length(rise_idx)));
legend({'Comm. window', 'Elevation', 'Mask angle (10°)'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
grid on;
ylim([-90 90]); xlim([0 48]);