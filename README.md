# String Tension Calculator & Workshop Reporter

An advanced, data-driven Open-Source string tension calculator for guitars and basses, featuring a Dark Mode studio interface, real-time tension curves, custom preset management, and automated luthier adjustment reports.

## Features
- **Extended Range Support:** Built-in calculation matrices for 4- to 9-string instruments.
- **Dynamic INI Databases:** Modify or add string packs (`strings.ini`) and legendary metal or signature tunings (`tunings.ini`) without recompiling.
- **Integrated Visual Curve:** Real-time tension visualization drawn directly inside the UI matrix to check for balanced tension or heavy-bottom profiles.
- **Truss Rod Adjustment Assistant:** Automatic mathematical prognosis of required hardware adjustments based on custom cumulative reference weight baselines.
- **Automated Workshop Report:** Instantly generates a formatted HTML sheet for easy archiving or immediate PDF-printing for your clients.

## How to Build (Windows)
1. Ensure you have the Free Pascal Compiler / Lazarus (`lazbuild`) installed and added to your system environment PATH.
2. Clone this repository to your local machine.
3. Run `compile.bat` to assemble the executable.
4. Launch `StringSelectorApp.exe`.

## Legal Disclaimer
This software provides mathematical estimations based on theoretical luthier formulas. The author is in no way liable for any mechanical or physical damages to instruments resulting from improper technical adjustments. Use at your own risk.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Support & Contributions
**Please note:** This project is provided "as-is". I do **not** provide any further official support, feature updates, or troubleshooting for this software. 

However, since this is an open-source project, anyone is highly welcome and encouraged to fork or clone this repository, modify the source code, and adapt it to their own needs. 

If you discover any critical or serious bugs that break the core physical calculations, feel free to open an **Issue** here on GitHub to inform me. I will review and address game-breaking bugs when time permits.
