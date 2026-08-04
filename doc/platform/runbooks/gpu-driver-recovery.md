# GPU Driver Recovery

Use this procedure when a kernel update leaves the GPU Operator driver pod
unable to replace `nouveau`, especially when the driver manager reports
`failed to unload nouveau driver: device or resource busy`.

## Contain the Retry Loop

Stop k3s so GPU Operator cannot continue the failing driver transition:

```bash
uv run ansible -i inventory/gpu-cluster/hosts.yml gpu_nodes -b \
  -m systemd_service -a 'name=k3s state=stopped' \
  --vault-password-file=.vault_pass
```

Confirm the boot ID and uptime remain stable before changing boot state:

```bash
uv run ansible -i inventory/gpu-cluster/hosts.yml gpu_nodes -b \
  -m shell -a 'cat /proc/sys/kernel/random/boot_id; uptime -s; systemctl is-active k3s || true' \
  --vault-password-file=.vault_pass
```

## Disable nouveau

Apply the GPU host prerequisites. The role writes the modprobe policy and
rebuilds all installed initramfs images when required:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml \
  playbooks/02-gpu-runtime.yml --vault-password-file=.vault_pass
```

Do not try to unload `nouveau` from a live graphical framebuffer.

## Select a Recovery Kernel

List installed kernels and exact GRUB entries:

```bash
ls -l /boot/vmlinuz-* /boot/initrd.img-*
grep -E '^submenu |^[[:space:]]*menuentry ' /boot/grub/grub.cfg
```

When the newest kernel has not been validated with the managed NVIDIA driver,
select the last known-good entry for one boot with `grub-reboot`. Preserve the
exact submenu and menu-entry spelling from `grub.cfg`.

Reboot the node once. k3s is enabled and starts automatically after boot.

## Validate Recovery

Confirm that the expected kernel booted, `nouveau` is absent, and NVIDIA
modules are loaded:

```bash
uname -r
lsmod | grep -E 'nvidia|nouveau'
nvidia-smi
```

Then run the platform checks:

```bash
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-k3s.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-operator.sh
KUBECONFIG_PATH=kubeconfig-gpu-cluster.yaml scripts/check-gpu-runtime-test.sh
```

Only make a recovery kernel the persistent GRUB default after confirming that
it boots successfully. Re-test future kernels before changing the default.
