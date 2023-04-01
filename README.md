# Custom Health API
A rewrite of the HP system of The Binding of Isaac: Repentance into Lua, allowing for expansion of API features and the adding of new custom HP types by modders.

To add to your project, complete the following steps:
1) Extract the "resources" folder into the root directory of your Isaac mod.
2) Extract the "customhealthapi" folder into your mod's "scripts" folder.
3) Follow the steps in "customhealthapi/core.lua" to update the "root", "modname" and "modinitial" variables located at the top of the file to identify your mod for CHAPI features.
4) Add the following line to your mod's main.lua file, replacing [INSERT_CHAPI_SCRIPTS_DIRECTORY_HERE] with the path of the folder you extracted the "customhealthapi" folder to earlier, to load CHAPI features:

       include("[INSERT_CHAPI_SCRIPTS_DIRECTORY_HERE].customhealthapi.core")

5) Add callbacks for CustomHealthAPI.Enums.Callbacks.ON_SAVE and CustomHealthAPI.Enums.Callbacks.ON_LOAD to your mod to handle Custom Health API save data (see wiki for details).

Any further information about Custom Health API and it's features are located in the Github project's wiki (currently unfinished).
