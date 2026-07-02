# GPU Ops

Ansible and GitOps scaffolding for a k3s-based GPU cluster managed with NVIDIA GPU Operator.

Start by copying `inventory/gpu-cluster/hosts.yml` to real hostnames/IPs, then run:

```bash
uv run ansible-playbook -i inventory/gpu-cluster/hosts.yml playbooks/site.yml --syntax-check
```
