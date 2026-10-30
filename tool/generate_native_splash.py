"""Export the approved fox app mark for OS launch screens (requires Pillow)."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MASCOT = ROOT / 'assets/gen/icons/app_icon_foreground.png'


def export_splash_assets():
    mascot = Image.open(MASCOT).convert('RGBA')
    ios = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for scale, suffix in [(1, ''), (2, '@2x'), (3, '@3x')]:
        mascot.resize((220 * scale, 220 * scale), Image.Resampling.LANCZOS).save(
            ios / f'LaunchImage{suffix}.png', optimize=True
        )

    resources = ROOT / 'android/app/src/main/res'
    for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2),
                           ('xxhdpi', 3), ('xxxhdpi', 4)]:
        directory = resources / f'drawable-{density}'
        directory.mkdir(exist_ok=True)
        mascot.resize((round(220 * scale), round(220 * scale)),
                      Image.Resampling.LANCZOS).save(
            directory / 'native_splash_mascot.png', optimize=True
        )
        # Android 12 uses a 288dp icon canvas and a circular safe area.
        # Inset the transparent mark so its ears and glasses stay visible.
        canvas_size = round(288 * scale)
        mascot_size = round(176 * scale)
        canvas = Image.new('RGBA', (canvas_size, canvas_size))
        inset = (canvas_size - mascot_size) // 2
        canvas.alpha_composite(
            mascot.resize((mascot_size, mascot_size), Image.Resampling.LANCZOS),
            (inset, inset),
        )
        canvas.save(directory / 'native_splash_icon.png', optimize=True)


if __name__ == '__main__':
    export_splash_assets()
