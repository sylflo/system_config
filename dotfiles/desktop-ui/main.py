import os
import random
import gi
import subprocess
from ctypes import CDLL

# Load layer shell
CDLL("/nix/store/wx6b8hcxsw80pn6vjv8469kv3gbzyvzd-gtk4-layer-shell-1.0.4/lib/libgtk4-layer-shell.so")

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gdk, GLib, Gtk4LayerShell as LayerShell

TRANSITION_INTERVAL_MS = 100
TRANSITION_DURATION_MS = 3000
STEPS = TRANSITION_DURATION_MS // TRANSITION_INTERVAL_MS


def get_random_wallpaper(folder):
    valid_exts = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
    files = [
        os.path.join(folder, f)
        for f in os.listdir(folder)
        if os.path.isfile(os.path.join(folder, f)) and os.path.splitext(f)[1].lower() in valid_exts
    ]
    if not files:
        raise FileNotFoundError("No image files found in the wallpaper folder.")
    return random.choice(files)


def set_background_image(path):
    css = Gtk.CssProvider()
    css.load_from_data(f"""
    .background {{
        background-image: url("file://{path}");
        background-size: cover;
        background-repeat: no-repeat;
        background-position: center;
    }}
    """.encode("utf-8"))
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
    )


def set_system_brightness(value_percent):
    try:
        value_percent = max(0, min(100, int(value_percent)))
        subprocess.run(["brightnessctl", "set", f"{value_percent}%"], check=True)
    except Exception as e:
        print(f"Failed to set brightness: {e}")


def get_current_brightness():
    try:
        current = int(subprocess.check_output(["brightnessctl", "get"]).decode().strip())
        maximum = int(subprocess.check_output(["brightnessctl", "max"]).decode().strip())
        return (current / maximum) * 100
    except Exception as e:
        print(f"Failed to read brightness: {e}")
        return 75


def animate_transition(from_widget, to_widget, container):
    if not from_widget or not to_widget or not container:
        return

    to_widget.set_opacity(0.0)
    to_widget.set_visible(True)
    to_widget.set_margin_start(100)
    to_widget.set_margin_top(100)
    to_widget.set_margin_bottom(100)
    to_widget.set_vexpand(True)
    container.set_child(to_widget)

    from_widget.set_margin_start(0)
    to_widget.set_margin_start(100)

    step = {"count": 0}

    def animate():
        t = step["count"] / STEPS
        from_widget.set_opacity(max(0.0, 1.0 - t))
        to_widget.set_margin_start(int(100 * (1.0 - t)))
        to_widget.set_opacity(min(1.0, t))
        step["count"] += 1
        if step["count"] <= STEPS:
            return True
        from_widget.set_visible(False)
        to_widget.set_margin_start(0)
        background_path = get_random_wallpaper("/home/sylflo/Pictures/Wallpapers-tests")
        set_background_image(background_path)
        return False

    GLib.timeout_add(TRANSITION_INTERVAL_MS, animate)


def on_key_press(controller, keyval, keycode, state):
    if keyval == Gdk.KEY_Escape:
        controller.get_widget().get_root().close()
        return True
    return False


def on_activate(app):
    window = Gtk.Window(application=app)
    window.set_default_size(1920, 1080)
    window.set_focusable(True)
    window.set_can_focus(True)

    LayerShell.init_for_window(window)
    LayerShell.set_layer(window, LayerShell.Layer.OVERLAY)
    LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.ON_DEMAND)

    for edge in [LayerShell.Edge.TOP, LayerShell.Edge.BOTTOM, LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT]:
        LayerShell.set_anchor(window, edge, True)

    LayerShell.auto_exclusive_zone_enable(window)

    # Load external CSS
    css = Gtk.CssProvider()
    css_path = os.path.join(os.path.dirname(__file__), "style.css")
    css.load_from_path(css_path)
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    # Set initial background
    background_path = get_random_wallpaper("/home/sylflo/Pictures/Wallpapers-tests")
    set_background_image(background_path)

    builder = Gtk.Builder()
    builder.add_from_file("layouts/layout.ui")

    overlay = builder.get_object("overlay")
    main_box = builder.get_object("main_box")

    def get(obj_id):
        o = builder.get_object(obj_id)
        if o is None:
            raise Exception(f"Missing object: {obj_id}")
        return o

    brightness_revealer = get("brightness_revealer")
    brightness_slider = get("brightness_slider")
    brightness_slider.set_value(get_current_brightness())
    brightness_slider.connect("value-changed", lambda slider: set_system_brightness(slider.get_value()))

    def connect_row_click(row_id, target=None):
        row = get(row_id)
        click = Gtk.GestureClick()
        if isinstance(target, Gtk.Revealer):
            click.connect("pressed", lambda *_: target.set_reveal_child(not target.get_reveal_child()))
        elif target:
            click.connect("pressed", lambda *_: animate_transition(main_box, target, overlay))
        row.add_controller(click)

    connect_row_click("brightness_row", brightness_revealer)

    def load_page(name):
        b = Gtk.Builder()
        b.add_from_file(f"layouts/pages/{name}.ui")
        page = b.get_object(f"{name}_page")
        back = b.get_object(f"{name}_back")
        if page is None or back is None:
            raise Exception(f"Missing ids in {name}.ui")
        overlay.add_overlay(page)
        connect_row_click(f"{name}_row", page)
        back.connect("clicked", lambda *_: animate_transition(page, main_box, overlay))

    for name in ["sound", "vpn", "bluetooth", "wifi"]:
        load_page(name)

    controller = Gtk.EventControllerKey()
    controller.connect("key-pressed", on_key_press)
    window.add_controller(controller)

    window.set_child(overlay)
    window.present()
    window.set_focus(window)


app = Gtk.Application(application_id="com.example.LayerShellButtons")
app.connect("activate", on_activate)
app.run()
