import { toFahrenheit } from './temperature.js';

export function describe(celsius) {
  return `${celsius}°C is ${toFahrenheit(celsius)}°F`;
}
