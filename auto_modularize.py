#!/usr/bin/env python3
"""
Auto-Modularization Script for SuperTanks Nightmare
Extracts remaining functions and creates module files automatically
"""

import re
import os

SOURCE = r"c:\Users\Socius\Desktop\Eclipse-Project\scripting\Natan_SuperTanks_Nightmare.sp"
OUTPUT_DIR = r"c:\Users\Socius\Desktop\Eclipse-Project\scripting\supertanks"

def read_source():
    with open(SOURCE, 'r', encoding='utf-8', errors='ignore') as f:
        return f.readlines()

def write_module(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✓ Created: {path}")

def extract_function(lines, function_name, start_line=0):
    """Extract a complete function from source"""
    result = []
    in_function = False
    brace_count = 0

    for i in range(start_line, len(lines)):
        line = lines[i]

        # Check if this is the function we want
        if function_name in line and ('public' in line or 'stock' in line or 'static' in line):
            in_function = True

        if in_function:
            result.append(line)
            brace_count += line.count('{') - line.count('}')

            # Function complete when braces balance
            if brace_count == 0 and len(result) > 1:
                return ''.join(result), i

    return None, -1

# Read source
print("Reading source file...")
lines = read_source()

# ============================================================================
# CREATE tanks/st_tank_base.inc
# ============================================================================
print("\n=== Creating tanks/st_tank_base.inc ===")

tank_base_content = '''#if defined _st_tank_base_included
 #endinput
#endif
#define _st_tank_base_included

// ============================================================================
// TANK BASE SYSTEM
// Core tank functionality - spawning, selection, death
// ============================================================================

/**
 * Randomize tank type and apply render color
 * Called when a tank spawns
 *
 * @param client    Tank client index
 * @noreturn
 */
'''

# Extract RandomizeTank
func, _ = extract_function(lines, "RandomizeTank")
if func:
    tank_base_content += func + "\n"

# Extract GetSuperTankByRenderColor
func, _ = extract_function(lines, "GetSuperTankByRenderColor")
if func:
    tank_base_content += "\n" + func + "\n"

# Extract TankController
func, _ = extract_function(lines, "TankController")
if func:
    tank_base_content += "\n" + func + "\n"

# Extract ExecTankDeath
func, _ = extract_function(lines, "ExecTankDeath")
if func:
    tank_base_content += "\n" + func + "\n"

write_module(os.path.join(OUTPUT_DIR, "tanks", "st_tank_base.inc"), tank_base_content)

# ============================================================================
# CREATE utilities/st_timers.inc
# ============================================================================
print("\n=== Creating utilities/st_timers.inc ===")

timers_content = '''#if defined _st_timers_included
 #endinput
#endif
#define _st_timers_included

// ============================================================================
// TIMERS MODULE
// Main game loop timers and client update functions
// ============================================================================

/**
 * Main timer - 0.1 second interval
 * Displays tank health on crosshair
 */
'''

# Extract TimerUpdate01
func, _ = extract_function(lines, "TimerUpdate01")
if func:
    timers_content += func + "\n"

# Extract TimerUpdate1
func, _ = extract_function(lines, "TimerUpdate1")
if func:
    timers_content += "\n" + func + "\n"

# Extract TimerUpdateClients
func, _ = extract_function(lines, "TimerUpdateClients")
if func:
    timers_content += "\n" + func + "\n"

# Extract FrameUpdateClients
func, _ = extract_function(lines, "FrameUpdateClients")
if func:
    timers_content += "\n" + func + "\n"

write_module(os.path.join(OUTPUT_DIR, "utilities", "st_timers.inc"), timers_content)

# ============================================================================
# CREATE systems/st_effects.inc
# ============================================================================
print("\n=== Creating systems/st_effects.inc ===")

effects_content = '''#if defined _st_effects_included
 #endinput
#endif
#define _st_effects_included

// ============================================================================
// EFFECTS SYSTEM
// Visual effects, particles, screen effects
// ============================================================================

/**
 * Create a particle effect at a location
 */
'''

# Extract CreateParticle
func, _ = extract_function(lines, "CreateParticle")
if func:
    effects_content += func + "\n"

# Extract AttachParticle
func, _ = extract_function(lines, "AttachParticle")
if func:
    effects_content += "\n" + func + "\n"

# Extract PerformFade
func, _ = extract_function(lines, "PerformFade")
if func:
    effects_content += "\n" + func + "\n"

# Extract ScreenShake
func, _ = extract_function(lines, "ScreenShake")
if func:
    effects_content += "\n" + func + "\n"

write_module(os.path.join(OUTPUT_DIR, "systems", "st_effects.inc"), effects_content)

# ============================================================================
# Summary
# ============================================================================
print("\n" + "="*60)
print("AUTO-MODULARIZATION COMPLETE")
print("="*60)
print("\nModules created:")
print("  ✓ tanks/st_tank_base.inc")
print("  ✓ utilities/st_timers.inc")
print("  ✓ systems/st_effects.inc")
print("\nNext steps:")
print("  1. Review generated modules")
print("  2. Add includes to main plugin file")
print("  3. Compile and test")
print("  4. Continue with remaining modules")
