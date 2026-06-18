import os

from kitty.boss import get_boss
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb
from kitty.fast_data_types import Screen

RAINBOW = [
    0xff5555,  # red
    0xffb86c,  # orange
    0xf1fa8c,  # yellow
    0x50fa7b,  # green
    0x8be9fd,  # cyan
    0xbd93f9,  # purple
    0xff79c6,  # pink
]


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    color = RAINBOW[(index - 1) % len(RAINBOW)]

    if tab.is_active:
        screen.cursor.bg = as_rgb(0x000000)
        screen.cursor.fg = as_rgb(color)
    else:
        screen.cursor.bg = as_rgb(color)
        screen.cursor.fg = as_rgb(0x000000)

    wd = ''
    tab_obj = get_boss().tab_for_id(tab.tab_id)
    if tab_obj is not None and tab_obj.active_window is not None:
        wd = (tab_obj.active_window.get_cwd_of_root_child() or '').strip()
    home = os.path.expanduser('~')
    if wd == home:
        name = '~'
    elif wd.startswith(home + '/'):
        name = os.path.basename(wd.rstrip('/')) or '~'
    else:
        name = os.path.basename(wd.rstrip('/')) or wd or '/'

    screen.draw(f' {name} ')

    screen.cursor.bg = as_rgb(0x000000)
    screen.cursor.fg = as_rgb(0x000000)
    return screen.cursor.x
