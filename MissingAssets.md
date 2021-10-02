# Missing Assets

Some assets are not included in this repository. Here are instructions on how to download from their sources.

- Tileset

  1. Download from https://kronbits.itch.io/inca-game-assets
  2. Unzip `tileset.zip`
  3. Copy `inca_back2.png` and `inca_front.png` into `assets` directory
  4. Note that the `inca_back2.png` file used in the original game was darkened

- Merge Sound

  1. Download from https://opengameart.org/content/laser-shot-0
  2. Copy `Laser Shot.wav` into `assets/audio` directory

- Unmerge Sound

  1. Reverse `Laser Shot.wav` (Merge Sound) and name the output file `Laser Shot-reverse.wav`<br>
     Example using `sox`:
     ```
     sox Laser\ Shot.wav Laser\ Shot-reverse.wav reverse
     ```
  2. Copy `Laser Shot-reverse.wav` into `assets/audio` directory

- Reunited Sound

  1. Download from https://opengameart.org/content/ui-accept-or-forward
  2. Convert from MP3 to WAV format (from `Accept.mp3` to `Accept.wav`)
  3. Copy `Accept.wav` into `assets/audio` directory

- Remove Salt Sound

  1. Download from https://opengameart.org/content/spell-2
  2. Copy file into `assets/audio` directory

- Footstep Sound

  1. Download from https://www.fesliyanstudios.com/soundeffects-download.php?id=7089
  2. Copy file into `assets/audio` directory

- Background Music

  1. Download from https://incompetech.filmmusic.io/song/7012-bleeping-demo
  2. Copy file into `assets/audio` directory

- Ending Screen Music

  1. Download from https://incompetech.filmmusic.io/song/7015-neon-laser-horizon
  2. Copy file into `assets/audio` directory

- Signed Distance Field Font
  1. Download `font.font` from https://github.com/godotengine/godot-demo-projects/tree/master/gui/sdf_font
  2. Copy file into `assets` directory
