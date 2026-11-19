# Performance measurement — 4 GB and 8 GB devices

Use the same exported build, scene, resolution, graphics settings and 3-minute route on both devices. Close unrelated applications. Record idle baseline and gameplay peak.

## Windows measurements
1. Open Task Manager → Performance → Memory and GPU.
2. Open Task Manager → Details; add columns for CPU, memory and GPU engine if available.
3. Launch the exported game and wait 60 seconds.
4. Record process memory, total system memory, CPU utilisation, GPU utilisation, frame rate (if an in-game counter exists), load time and any stutter.
5. Repeat the same route three times; report median and worst observation.
6. Repeat after a fresh reboot if results are anomalous.

## Record
- Device RAM: 4 GB / 8 GB
- CPU/GPU, Windows version, resolution
- Build identifier and graphics preset
- Idle and gameplay memory (MB)
- Average/peak CPU and GPU (%)
- Average/minimum FPS if measured reliably
- Level load time (seconds)
- Stutters, crashes, thermal/battery observations

Do not invent thresholds after testing. Agree targets with the team first. Prioritise stable playability on 4 GB; reduce texture sizes, shadow quality, scene complexity and simultaneous audio/particle effects if necessary. Avoid running audits during gameplay measurements.
