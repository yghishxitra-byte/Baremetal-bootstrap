bash#!/bin/bash
echo "=== Запуск универсальной сборки ISO ==="
xorriso -as mkisofs -r \
  -V "Ubuntu Autoinstall" \
  -J -joliet-long -l \
  -b boot/grub/i386-pc/eltorito.img \
  -c boot.catalog \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -o ../UbuntuAutoinstall.iso .
echo "=== Сборка завершена ==="
