# Task: Rename a function across two files

Rename the exported function `toFahrenheit` to `celsiusToF`.

- In `src/temperature.js`: rename the function and its export.
- In `src/weather.js`: update the import and every call site.

The old name `toFahrenheit` must no longer be exported anywhere. Keep the
behavior and the output format of `describe` exactly the same. Both files must
end up consistent (an import of a name that no longer exists will break the
module).
