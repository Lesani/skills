# config

Tool configuration that is not a skill. These files are stored here for version control. No installer reads them.

## ccstatusline.json

The status line layout for [ccstatusline](https://github.com/sirmalloc/ccstatusline), exported from version 2.2.27.

Claude Code runs ccstatusline through the `statusLine` command in `~/.claude/settings.json`. The tool reads its own settings from `~/.config/ccstatusline/settings.json`.

To restore the layout on a new machine:

1. Copy the file:

```bash
cp config/ccstatusline.json ~/.config/ccstatusline/settings.json
```

2. Start a new Claude Code session to see the status line.

To save changes back after you edit the layout in the ccstatusline menu:

```bash
cp ~/.config/ccstatusline/settings.json config/ccstatusline.json
```
