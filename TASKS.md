Replace apt installation of kitty with follwing:

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
mkdir -p ~/.local/bin ~/.local/share/applications ~/.config && \
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty && \
ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten && \
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/ && \
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/ && \
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop && \
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop && \
echo 'kitty.desktop' > ~/.config/xdg-terminals.list && \
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```
