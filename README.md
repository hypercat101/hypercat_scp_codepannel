# SCP Facility Control Panel

A professional Garry's Mod addon for SCP facility management and emergency response system.

## Features

- Comprehensive alert system with 6 levels (Code 0-5)
- Facility-wide announcement system
- Secure access control for staff
- SQL-based logging system
- Rate limiting for security
- Modern, clean UI
- Console commands for server operators

## Installation

1. Clone this repository to your addons folder
2. Restart your server
3. Configure access in `lua/autorun/sh_scp_panel.lua`

## Usage

### In-Game Commands
- `!codepanel` - Open the control panel
- F6 (default) - Quick access key

### Console Commands
- `scp_alert <code>` - Set facility alert level (0-5)
- `scp_announce <category> <id> [custom_text]` - Make an announcement

## Access Control

### Default Access Groups
- superadmin
- admin
- operator

### Default Access Jobs
- Site Director
- Security Chief
- Senior Researcher
- Facility Manager

## Configuration

All configuration is in `lua/autorun/sh_scp_panel.lua`:
- Access control
- Alert settings
- Announcement categories
- UI customization
- Emergency response jobs

