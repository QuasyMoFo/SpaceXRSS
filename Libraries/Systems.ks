// Falcon 9 - Systems Script
// Codebase v0.3.0
// Licensed under GNU General Public License 3.0

function f9_Steering {
    parameter heading_Steer.
    parameter pitch_Steer.
    parameter roll_Steer is 0.

    lock steering to heading(heading_Steer, pitch_Steer, roll_Steer).
}

function f9_Throttle {
    parameter throt_Target.

    lock throttle to throt_Target.
}

function formatted_Time {
    parameter time_Unit.

    local hour_Zero is "".
    local minute_Zero is "".
    local second_Zero is "".

    local hour_Floor is floor(time_Unit / 3600).
    local minute_Floor is floor((time_Unit - (hour_Floor * 3600)) / 60).
    local second_Floor is floor(time_Unit - (hour_Floor * 3600) - (minute_Floor * 60)).

    if hour_Floor < 10 {set hour_Zero to "0".} else {set hour_Zero to "".}
    if minute_Floor < 10 {set minute_Zero to "0".} else {set minute_Zero to "".}
    if second_Floor < 10 {set second_Zero to "0".} else {set second_Zero to "".}
    
    local time_Unit_Formatted is hour_Zero + hour_Floor + ":" + minute_Zero + minute_Floor + ":" + second_Zero + second_Floor.
    return time_Unit_Formatted.
}

function time_Of_Day {
    return time:clock.
}

function launch_Status {
    if ag9 {
        return "HOLDING".
    } else {
        return "GO".
    }
}

// function propellant_Load_Procedure {
// }

// function propellant_Drain {
// }

function tank_Setup {
    parameter tankName, tankAction, tankValue is 0.

    if tankAction = "enable" or tankAction = "disable" or tankAction = true or tankAction = false {
        if tankAction = "enable" {
            set tankAction to true.
        } else if tankAction = "disable" {
            set tankAction to false.
        }

        for item in ship:partstagged(tankName) {
            local resourcePartList is item:resources.
            
            for resourceItem in resourcePartList {
                if tankValue = 0 {
                    if not(resourceItem:name = "ELECTRICCHARGE") {
                        set resourceItem:enabled to tankAction.
                    }
                } else {
                    if resourceItem:name = tankValue {
                        set resourceItem:enabled to tankAction.
                    }
                }
            }

            resourcePartList:clear.
        }
    } else if tankAction:endswith(" Cooling") {
        if ship:partstagged(tankName)[0]:getmodule("ModuleCryoTank"):hasaction(tankAction) {
            ship:partstagged(tankName)[0]:getmodule("ModuleCryoTank"):hasaction(tankAction).
        }
    }
}

function resource_Print {
    parameter resourceList.

    for item in resourceList {
        return item:name + ": " + round(item:amount, 3) + " (" + round((item:amount / item:capacity) * 100, 3) + "%)".
    }
}

function circularize {
    set circNode to node(time:seconds + eta:apoapsis, 0, 0, Hohmann("circ")).
    add circNode.

    ExecNode().
}

function time_To_Ap {
    set TTA to ETA:apoapsis.

    if eta:apoapsis > (ship:obt:period / 2) {
        set TTA to eta:apoapsis - ship:obt:period.
    }
}

function ptc_Of_Vect {
    parameter vecT.
    return 90 - vAng(ship:up:vector, vecT).
}

function launch_Count {
    until countdown_Time = 0 {
        clearscreen.
        switch to 0.

        print "T-" + formatted_Time(countdown_Time).
        log "T-" + formatted_Time(countdown_Time) to missionTime.txt.
        
        wait 1.
        set countdown_Time to countdown_Time - 1.

        if countdown_Time = 265 { // Strongback Retract
            toggle ag4.
        }

        if countdown_Time = 4 { // Ignition
            stage.
            f9_Throttle(1).
        }

        if ag9 { // Abort
            ag9 off.
            ag6 off.
            f9_Throttle(0).
            
            reboot.
        }
    }

}

function data_Output {
    set telem to true.
    when telem then {
        clearscreen.
        print "- SpaceX Telemetry -" at (2, 1).
        print "- " + launch_Vehicle + " & " + vehicle_Config + " -" at (2, 2).
        print "____________________________________________" at (2, 3).

        print "Time: " + time:clock at (2, 5).
        print "M.E.T: " + formatted_Time(missionTime) at (2, 6).
        print "Connection: " + homeConnection:isconnected at (2, 7).
        print "REAL___________________TARGET_______________" at (2, 9).

        print "Apogee: " + round(ship:apoapsis / 1000, 2) + " (Km)" at (2, 11).
        print "Target: " + Apogee + " (Km)" at (26, 11).
        print "Perigee: " + round(ship:periapsis / 1000, 2) + " (Km)" at (2, 12).  
        print "Target: " + Perigee + " (Km)" at (26, 12).
        print "Inc: " + round(ship:orbit:Inclination, 2) + " (Deg)" at (2, 13).
        print "Target: " + Inclination + " (Deg)" at (26, 13).
        print "LAN: " + round(orbit:longitudeofascendingnode, 2) + " (Deg)" at (2, 14).
        print "Target: " + LAN + " (Deg)" at (26, 14).
        print "____________________________________________" at (2, 15).
        
        print "VSpeed: " + round(ship:verticalspeed, 3) + " (M/s)" at (2, 17). 
        print "ASpeed: " + round(ship:airspeed, 3) + " (M/s)" at (2, 18).
        print "Srf Mag: " + round(ship:velocity:surface:mag, 3) + " (M/s)" at (2, 19). 
        print "Altitude: " + round(ship:altitude, 3) + " (Km)" at (2, 20).

        // Miscs
        print "|" at (24, 11).
        print "|" at (24, 12).
        print "|" at (24, 13).
        print "|" at (24, 14).

        preserve.
    }   
}