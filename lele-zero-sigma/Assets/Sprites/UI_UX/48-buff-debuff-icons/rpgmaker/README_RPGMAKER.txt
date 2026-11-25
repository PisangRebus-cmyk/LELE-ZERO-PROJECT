RPG MAKER MV / MZ ICONSET
=========================

IconSet.png        48 icons, 32x32, 16 per row, transparent background
IconSet_index.txt  icon number -> file name

HOW TO USE
----------
RPG Maker MV and MZ read every item, skill and state icon from ONE file:
    img/system/IconSet.png        (both MV and MZ, 32x32 icons, 16 per row)

Option A - replace (new project, you only need these icons):
    copy IconSet.png over img/system/IconSet.png.
    Icon numbers are listed in IconSet_index.txt.

Option B - append (keep the default icons):
    1. Open your project's img/system/IconSet.png in any image editor.
    2. Make the canvas taller by 96 px and paste this IconSet.png at the
       bottom, left aligned (x = 0).
    3. In the database, icon number = (rows in your old file x 16) + the
       number from IconSet_index.txt.

Icons are true 32x32 pixel art (no scaling), so they stay sharp at 100%.
VX Ace uses 24x24 icons - scale with your engine's own settings or use the
png_32 files directly through a plugin.
