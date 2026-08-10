%% STEP 1-2: Define ISS Orbit and Propagate with ode45
% This script sets up the ISS's Keplerian elements, converts them to a
% state vector (position + velocity), then propagates the orbit forward
% 48 hours using numerical integration of the two-body equation of motion.

clear; clc; close all;

%% --- Constants ---
mu_earth = 398600.4418;   % Earth's gravitational parameter [km^3/s^2]
R_earth  = 6378.137;      % Earth's equatorial radius [km]

%% --- ISS Keplerian Orbital Elements (approximate, epoch-independent example) ---
% In a real project you'd pull these from a current TLE (e.g. via
% www.celestrak.com), but for now we use representative values so you
% can see the pipeline work end to end.

a     = 6798;              % semi-major axis [km] (~420 km altitude)
e     = 0.0006;            % eccentricity (nearly circular)
i     = deg2rad(51.6);     % inclination [rad]
RAAN  = deg2rad(120);      % right ascension of ascending node [rad]
argp  = deg2rad(60);       % argument of perigee [rad]
nu0   = deg2rad(0);        % true anomaly at epoch [rad] (start at perigee)

%% --- Convert Keplerian elements to ECI state vector (r, v) ---
% This is the classic "orbital elements -> Cartesian" conversion.
% Step A: position/velocity in the perifocal (orbit-plane) frame
% Step B: rotate into ECI using RAAN, inclination, argument of perigee

p = a * (1 - e^2);                     % semi-latus rectum
r_mag = p / (1 + e*cos(nu0));          % orbital radius at nu0

% Position in perifocal frame
r_pf = [r_mag*cos(nu0); r_mag*sin(nu0); 0];

% Velocity in perifocal frame
v_pf = sqrt(mu_earth/p) * [-sin(nu0); e + cos(nu0); 0];

% Rotation matrix: perifocal -> ECI (3-1-3 Euler sequence: RAAN, i, argp)
R3_RAAN = [cos(RAAN) -sin(RAAN) 0; sin(RAAN) cos(RAAN) 0; 0 0 1];
R1_i    = [1 0 0; 0 cos(i) -sin(i); 0 sin(i) cos(i)];
R3_argp = [cos(argp) -sin(argp) 0; sin(argp) cos(argp) 0; 0 0 1];

Q_pf2eci = R3_RAAN * R1_i * R3_argp;

r_eci0 = Q_pf2eci * r_pf;   % initial position [km] in ECI
v_eci0 = Q_pf2eci * v_pf;   % initial velocity [km/s] in ECI

fprintf('Initial position (ECI): [%.2f, %.2f, %.2f] km\n', r_eci0);
fprintf('Initial velocity (ECI): [%.4f, %.4f, %.4f] km/s\n', v_eci0);
fprintf('Orbital period: %.2f minutes\n', 2*pi*sqrt(a^3/mu_earth)/60);

%% --- Propagate with ode45 (two-body equation of motion) ---
% State vector: [x y z vx vy vz]
state0 = [r_eci0; v_eci0];

tspan = 0 : 60 : 48*3600;   % 48 hours, sampled every 60 seconds

options = odeset('RelTol', 1e-10, 'AbsTol', 1e-10);
[t, state] = ode45(@(t,y) two_body_eom(t, y, mu_earth), tspan, state0, options);

r_eci = state(:, 1:3);   % position over time [km]
v_eci = state(:, 4:6);   % velocity over time [km/s]

%% --- Quick sanity check plot: 3D orbit in ECI frame ---
figure('Name', 'ISS Orbit Propagation (ECI Frame)');
plot3(r_eci(:,1), r_eci(:,2), r_eci(:,3), 'b-', 'LineWidth', 1);
hold on;

% Draw Earth as a reference sphere
[xs, ys, zs] = sphere(30);
surf(xs*R_earth, ys*R_earth, zs*R_earth, ...
     'FaceColor', [0.3 0.6 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4);

axis equal; grid on;
xlabel('X [km]'); ylabel('Y [km]'); zlabel('Z [km]');
title('ISS Orbit Propagated 48 Hours (ode45, two-body)');
view(45, 25);

%% --- Local function: two-body equation of motion ---
function dydt = two_body_eom(~, y, mu)
    r = y(1:3);
    v = y(4:6);
    r_norm = norm(r);
    a_grav = -mu * r / r_norm^3;   % Newton's law of gravitation
    dydt = [v; a_grav];
end