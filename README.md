# cosmere_extended
Fantasy Grounds extension for cosmere

# Cosmere Extended

A Fantasy Grounds extension for the Cosmere RPG ruleset
- Singer Forms that modify attributes based on your current form
- Defense Modifier window to add modifiers for talents.

## Features

This extension adds a Singer Form selector to the character sheet for characters with the Singer ancestry. When a form is selected, it automatically:

- **Modifies Attributes**: Adds stat bonuses based on the selected form

- **Dynamic Form Availability**: Forms are only available if the character has the required talents:

- **Deflect Calculation**: deflect value is automatically compared with equipped armor, using the higher value

- **Stormform's Unleash Lightning**: Adds this attack to your weapons.

- **Combat Tracker Integration**: The active form appears as an effect in the combat tracker

- **Chat Notifications**: Displays a chat message when a character assumes a form

- **Defense Modifiers**: Adds a defense modifier window accessible via buttons next to each defense value on the character sheet
  - **Physical Defense**: Shows derived value (10 + Strength + Speed), allows manual modifier input, and displays total
  - **Cognitive Defense**: Shows derived value (10 + Intellect + Willpower), allows manual modifier input, and displays total
  - **Spiritual Defense**: Shows derived value (10 + Awareness + Presence), allows manual modifier input, and displays total
  - Modifier values are automatically applied to defense calculations on the character sheet

## Installation

1. Download this repository as a zip and rename it to .ext instead of .zip
2. Copy the .ext to your Fantasy Grounds extensions directory:
   - **Windows**: `%APPDATA%\Fantasy Grounds\extensions\`
   - **Mac**: `~/Library/Application Support/Fantasy Grounds/extensions/`
   - **Linux**: `~/.config/Fantasy Grounds/extensions/`
3. Start Fantasy Grounds
4. When creating or loading a campaign, enable the "Cosmere Extended" extension in the extension selection window
5. The extension will automatically load for campaigns using the CosmereRPG ruleset

## Usage

1. Create a character with the **Singer** ancestry
2. Add the appropriate talents (Forms of Resolve, Forms of Finesse, or Forms of Wisdom) to unlock forms
3. On the character sheet, scroll down to the **Singer Form** section (located below the Weapons section)
4. Select a form from the dropdown menu
5. Attributes and other stats will update automatically

## Requirements

- Fantasy Grounds Unity
- CosmereRPG ruleset
- CoreRPG ruleset

## Version

1.0.0

