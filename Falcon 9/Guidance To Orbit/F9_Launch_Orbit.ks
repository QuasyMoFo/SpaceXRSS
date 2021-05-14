// Falcon 9 - Launch To Orbit Script
// Codebase v0.3.0
// Licensed under GNU General Public License 3.0

GLOBAL INIT IS LEXICON(

    "Launch Vehicle", "Falcon 9 B5", // [Falcon 9 B5] [Falcon Heavy]
    "Config", "Starlink", // [Payload] [Dragon] [Starlink]
    
    "Apogee", 550000, // Apoapsis
    "Perigee", 550000, // Periapsis
    "Inclination", 53, // 39a = 28-62 ~ 40 = 28-93
    "LAN", false, // leave as false for untimed launch

    "Recovery", "ASDS", // [RTLS] [ASDS] [NONE]

    "Countdown Time", 10, // Time in seconds for countdown
    "Countdown NET", true, // Leave as true for telemetry
    "CPU IPU", 300 // Required for good operating speed

).

function f9_Init {
    runOncePath("0:/Libraries/lib_lazcalc.ks").
    runOncePath("0:/Libraries/lib_GNC.ks").

    global launch_Vehicle is INIT["Launch Vehicle"].
    global vehicle_Config is INIT["Config"].

    global Apogee is INIT["Apogee"].
    global Perigee is INIT["Perigee"].
    global Inclination is INIT["Inclination"].
    global LAN is INIT["LAN"].

    global recovery_Mode is INIT["Recovery"].

    global countdown_Time is INIT["Countdown Time"].
    global countdown_NET is INIT["Countdown NET"].

    global az_Calc is LAZcalc_init(Apogee, Inclination).
    global roll is 0.
    global dynamic_P_Limit is 0.30.
    
    set config:ipu to INIT["CPU IPU"].
    set steeringManager:maxstoppingtime to 1.
    set steeringManager:rollts to 20.
    set steeringManager:pitchts to 5.
    set steeringManager:yawts to 5.

    lock throttle_Limiter to max(0, ship:airspeed - 450) / 450.

    if vehicle_Config = "Payload" {
        global fairing_Halves_Attatched is true.
    } else if vehicle_Config = "Dragon" {
        set fairing_Halves_Attatched to false.
    } else {
        set fairing_Halves_Attatched to true.
    }

    if recovery_Mode = "ASDS" {
        global meco_Propellant is 22500.
    } else if recovery_Mode = "RTLS" {
        global meco_Propellant is 30000.
    } else if recovery_Mode = "NONE" {
        global meco_Propellant is 100.
    }

    runOncePath("0:/Libraries/Systems.ks").

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
    
    if vehicle_Config = "Starlink" {
        p5_S2_Spin_Deploy().
    }
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
    local ptc_Ang is 1.1.

    until stage:kerosene <= meco_Propellant {
        local az_Steer is LAZcalc(az_Calc).
        local pitch_Steer is (90 - ptc_Ang * sqrt(ship:velocity:surface:mag - 50)).

        if ship:altitude > 30000 {
            set ptc_Ang to 1.2.
        } else if ship:altitude > 40000 {
            set ptc_Ang to 1.3.
        }

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

    until ship:apoapsis >= Apogee and ship:altitude >= body:atm:height {
        
        local ap_Off is ship:apoapsis - 85000.
        local half_Eta is 30 - eta:apoapsis.
        local pitch_Steer is (half_Eta * 2) + ((ap_Off / 5000) * 10).

        if pitch_Steer < -5 {
            set pitch_Steer to -5.
        } else if pitch_Steer > 15 {
            set pitch_Steer to 15.
        }

        if ship:altitude >= body:atm:height and fairing_Halves_Attatched {
            stage.
            set fairing_Halves_Attatched to false.
        }

        if ship:apoapsis > Apogee - 50000 {
            set config:ipu to INIT["CPU IPU"] + 300.
        }

        local az_Steer is round(LAZcalc(az_Calc), 2).
        f9_Steering(az_Steer, pitch_Steer, roll).
        f9_Throttle(1).

        wait 0.
    }

    f9_Throttle(0).
    rcs on.
    lock steering to prograde.
    wait until ship:altitude >= Apogee / 2.

    if ship:apoapsis > Apogee and ship:periapsis < Perigee {
        set circNode to node(time:seconds + eta:apoapsis, 0, 0, Hohmann("circ")).
        add circNode.

        ExecNode().
    }
    
    f9_Throttle(0).
    wait 6.
}

function p5_S2_Spin_Deploy {
    unlock steering.
    set ship:control:pitch to 1.
    rcs on.

    wait 1.
    set ship:control:neutralize to true.

    wait 3.
    stage. // Should deploy Starlinks
}

// SEQUENCE -------------------------------------------------
f9_Init().
f9_Main().