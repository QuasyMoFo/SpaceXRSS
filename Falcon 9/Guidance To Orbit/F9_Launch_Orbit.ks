// Falcon 9 - Launch To Orbit Script
// Codebase v0.2.3
// Licensed under GNU General Public License 3.0

GLOBAL INIT IS LEXICON(

    "Launch Vehicle", "Falcon 9 B5", // [Falcon 9 B5] [Falcon Heavy]
    "Config", "Payload", // [Payload] [Dragon]
    
    "Apogee", 450000, // Apoapsis
    "Perigee", 450000, // Periapsis
    "Inclination", 92, // 39a = 28-62 ~ 40 = 28-93
    "LAN", false, // leave as false for untimed launch

    "AFTS", "SAFED", // [SAFED] [AUTO]
    "Recovery", "ASDS", // [RTLS] [ASDS] [NONE]

    "Countdown Time", 10, // Time in seconds for countdown
    "Countdown NET", true, // Leave as true for telemetry
    "CPU IPU", 400 // Required for good operating speed

).

function f9_Init {
    runOncePath("0:/Libraries/lib_lazcalc.ks").
    runOncePath("0:/Libraries/Systems.ks").

    global launch_Vehicle is INIT["Launch Vehicle"].
    global vehicle_Config is INIT["Config"].

    global Apogee is INIT["Apogee"].
    global Perigee is INIT["Perigee"].
    global Inclination is INIT["Inclination"].
    global LAN is INIT["LAN"].

    global AFTS is INIT["AFTS"].
    global recovery_Mode is INIT["Recovery"].

    global countdown_Time is INIT["Countdown Time"].
    global countdown_NET is INIT["Countdown NET"].

    global az_Calc is LAZcalc_init(Apogee, Inclination).
    global roll is 0.
    global dynamic_P_Limit is 0.30.
    
    
    set config:ipu to INIT["CPU IPU"].
    set steeringManager:maxstoppingtime to 1.
    set steeringManager:rollts to 5.
    set steeringManager:pitchts to 5.
    set steeringManager:yawts to 5.

    lock throttle_Limiter to max(0, ship:airspeed - 450) / 450.

    if vehicle_Config = "Payload" {
        global fairing_Halves_Attatched is true.
    } else {
        global fairing_Halves_Attatched is false.
    }

    if recovery_Mode = "ASDS" {
        global meco_Propellant is 22500.
    } else if recovery_Mode = "RTLS" {
        global meco_Propellant is 30000.
    } else if recovery_Mode = "NONE" {
        global meco_Propellant is 100.
    }

    print "Init Complete! Proceeding".
}

function f9_Main {
    if countdown_NET {
        launch_Count().
    }

    data_Output(). // Telemetry

    p1_Liftoff().
    p2_S1_GravityTurn().
    p3_S1_S2_Separation().
    p4_S2_Guidance().
}

// FLIGHT PHASES --------------------------------------------
function p1_Liftoff {
    local curr_Heading is facing.
    lock steering to curr_Heading.
    stage. // Release from strongback

    until ship:velocity:surface:mag > 80 {
        f9_Steering(90, 90, roll).
        wait 0.
    }
}

function p2_S1_GravityTurn {
    until stage:kerosene <= meco_Propellant {
        local az_Steer is LAZcalc(az_Calc).
        local pitch_Steer is (90 - 1.1 * sqrt(ship:velocity:surface:mag - 50)).

        f9_Steering(az_Steer, pitch_Steer, roll).
        f9_Throttle(max(min(1 - (10 * ((-1 * dynamic_P_Limit) + ship:q)), 1) - throttle_Limiter, 0.775)).
    }
}

function p3_S1_S2_Separation {
    f9_Throttle(0).
    local curr_Heading is facing.
    lock steering to curr_Heading.
    rcs on.

    wait 2.
    toggle ag8.
    stage.

    wait 3.
    f9_Throttle(1).
    set roll to 0.
}

function p4_S2_Guidance {
    set steeringManager:maxstoppingtime to 0.25.

    until ship:apoapsis >= Apogee and ship:periapsis >= Perigee - 30000 {
        if ship:velocity:surface:mag < 4000 {
            local pitch_Modifier is (-6.75 * ln(eta:apoapsis) + 30.6).

            set pitch_Steer to ((90 - 1.4 * sqrt(ship:velocity:surface:mag - 49)) + pitch_Modifier).
        } else if ship:velocity:surface:mag < 5600 {
            if eta:apoapsis > eta:periapsis {
                local pitch_Modifier is (-8.05 * ln(eta:apoapsis) + 60).

                set pitch_Steer to pitch_Modifier.
            } else {
                local pitch_Modifier is (-9.16 * ln(eta:apoapsis) + 37.55).
                if pitch_Modifier < 0 {
                    set pitch_Modifier to 0.
                }

                set pitch_Steer to pitch_Modifier.
            }
        } else if ship:velocity:surface:mag < 6900 {
            if eta:apoapsis > eta:periapsis {
                local eta_Neg is ((2 * eta:periapsis) - eta:apoapsis).
                local pitch_Modifier is (0.008 * (eta_Neg) ^ 2 - 0.4 * (eta_Neg)).

                set pitch_Steer to pitch_Modifier.
            } else if eta:apoapsis < eta:periapsis {
                local pitch_Modifier is (-0.182 * eta:apoapsis + 1.521).
                
                set pitch_Steer to pitch_Modifier.
            }
        } else if ship:velocity:surface:mag < 7700 {
            if eta:apoapsis > eta:periapsis {
                local eta_Neg is ((2 * eta:periapsis) - eta:apoapsis).
                local pitch_Modifier is (0.006 * (eta_Neg) ^ 2 - 0.453 * (eta_Neg)).

                set pitch_Steer to pitch_Modifier.
            } else {
                local pitch_Modifier is (0.006 * (eta:apoapsis) ^ 2 - 0.453 * (eta:apoapsis)).

                set pitch_Steer to pitch_Modifier.
            }
        }

        if ship:altitude >= 140000 and fairing_Halves_Attatched {
            stage.
            set fairing_Halves_Attatched to false.
        }

        local az_Steer is round(LAZcalc(az_Calc), 2).
        f9_Steering(az_Steer, pitch_Steer, roll).
        f9_Throttle(1).
        if ship:periapsis >= Perigee - 250000 {
            break.
        }   

        wait 0.
    }

    rcs on.
    lock steering to prograde.
    f9_Throttle(min(max(0.1, (Apogee - ship:apoapsis) / (Apogee - body:atm:height)) + max(0, ((60 - eta:apoapsis) * 0.075)), 1)).

    until ship:periapsis >= Perigee - 3000 or ship:apoapsis > Apogee {
        wait 0.
    }
    
    f9_Throttle(0).
    wait 6.
}

// SEQUENCE -------------------------------------------------
f9_Init().
f9_Main().