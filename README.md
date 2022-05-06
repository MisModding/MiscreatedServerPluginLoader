# MiscreatedServerPluginLoader

This mod loads unpacked local Lua Scripts as `Plugins` on a Miscreated Server, used mainly for development. but also allows Servers to load
server side code easily. for implementation of additional features/system without using the steam workshop.
> NOTE: remember. these files do not exist on the client thus have no access to client side functionality (though you can use RMI)

Features:
- Load/Unload/Reload `Plugins` from a configurable Plugin directory
- Global and Per-Plugin Configuration
- AutoLoad and Error Handling Functionality
- Plugins can depend on other Plugins

Take a look in the MiscreatedServer Folder for a Simple Example Plugin
