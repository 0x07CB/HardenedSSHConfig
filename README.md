# HardenedSSHConfig
> **Advanced SSH Server Hardening with Fail2Ban on Debian 12**  

### **About HardenedSSHConfig**  

**HardenedSSHConfig** is a Linode StackScript designed to deploy a highly secure SSH server on a **Debian 12** instance. This script enhances SSH security with advanced configurations, restricted user access, and automated protection against brute-force attacks using **Fail2Ban**.  

### **Main Features**  

✅ **Advanced SSH Configuration**  
- Custom SSH port modification  
- Optional password authentication disabling  
- Root login restriction or allowance  
- Security hardening:  
  - Limiting authentication attempts  
  - Disabling unnecessary features (X11 forwarding, Rhosts, etc.)  
  - Restricting TCP keepalive and environment variables  

✅ **Creation of a Limited User with Sudo Access**  
- Adding a restricted user with a predefined password  
- Configuring SSH key authentication  
- Secure permissions for the `.ssh` directory and authorized keys  

✅ **Automated System Updates**  
- Updating and upgrading packages before applying configurations  

✅ **Fail2Ban Integration for Brute-Force Protection**  
- Installing **Fail2Ban** and configuring it to monitor SSH access  
- Enabling **incremental ban time** for repeated failed login attempts  
- Adjusting security policies, including:  
  - Custom ban durations and retry limits  
  - Support for IPv6 and systemd logging  
  - DNS resolution settings for better tracking  

✅ **SSH & Fail2Ban Service Management**  
- Backing up the original SSH configuration  
- Applying changes and securely restarting SSH and Fail2Ban  

### **Why Use HardenedSSHConfig?**  
This script is **ideal** for anyone deploying a Debian 12 instance that requires **secure SSH access**, **automated attack protection**, and **customizable user privileges**. It provides an all-in-one solution to enhance system security while maintaining flexibility.  
