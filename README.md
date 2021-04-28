# SpaceX - Real Solar System 
Kerbal Operating System scripts used in SpaceX - RSS Videos. 

![Falcon9Ascent](https://cdn.discordapp.com/attachments/806297573911560203/836911517990387742/unknown.png)

The rockets currently in use are:
* Falcon 9 - Stage 1
* Falcon 9 - Stage 2

The scripts in the folder: **Guidance To Orbit**, is what controls the second stage all the way to Payload Deployment.
On the other hand, the **First Stage Recovery** folder contains the neccessary scripts required for landing Stage 1.

## Features In The Codebase
In the current version of the codebase, you can find multiple features on top of the standard launch sequence.
When opening the Telemetry kOS Terminal, you'll see the T- countdown, fuel on board, time in KSP, and some other data points which all you *nerds* can enjoy to look at.

During the countdown procedure, you'll see things being printed onto the console such as: "Fuel Load Start".
After reading through this site [here](https://spaceflight101.com/falcon-9-countdown-timeline/), I've listed all of the events on the T-Clock, and all the way from L-8:30:00 (If you choose to set the countdown this far back that is).

__**Listed Features__** as of 28/04/2021 (Version 0.1.0)
* Countdown Sequence with all sequences (No Data past L-8:30:00)
* Vehicle tests prior to T-0
* Max Q Throttling
* Throttle Down for MECO
* Stage Seperation Events, with the Landing Script activation
* First stage boostback, entry burn, landing (Not too great atm, improving slowly)
* Guidance to orbit
* Payload Deployment

After all these events, the script ends.

__**Upcoming Features**__
* Dragon Capsule Procedures
* Falcon Heavy Flight Software
* First stage script improvements & optimisations
* Guidance computer improvements & optimisations

If you have any ideas on anything I should add or remove, please let me know by either contacting me @oscarfleet12@Gmail.com OR use discord, where I am 99% of the time, Quasy#7014

### Credits

I did take some of the functions from the script that this great guy made!
https://www.youtube.com/watch?v=8xEUebcFP4c

And applied it to a more realistic scale to fit the real sort of SpaceX procedures.
