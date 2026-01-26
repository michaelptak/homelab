# Troubleshooting

Issues encountered during setup and their solutions.

## SSH password authentication not disabling

**Symptom:** After setting `PasswordAuthentication no` in `/etc/ssh/sshd_config` and restarting SSH, password login still works.

**Cause:** Ubuntu's cloud-init creates `/etc/ssh/sshd_config.d/50-cloud-init.conf` which overrides the main config.

**Solution:**
```bash
sudo rm /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo systemctl restart ssh
```
