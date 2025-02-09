# HardenedSSHConfig
> Advanced SSH Server Hardening on Debian 12

### About HardenedSSHConfig

HardenedSSHConfig is a linode stackscript.

This StackScript allows you to deploy a secure SSH server on a Debian 12 instance by applying advanced configurations to enhance security and reduce the risk of unauthorized access.  

### **Main Features**:  
- **Advanced SSH Configuration**:  
  - Custom SSH port modification  
  - Optional password authentication disabling  
  - Root login restriction or allowance  
  - Security hardening (session limits, disabling unnecessary features)  

- **Creation of a Limited User with Sudo Access**:  
  - Adding a user with a predefined password  
  - Configuring SSH keys for this user  
  - Secure permissions for the `.ssh` directory and authorized keys  

- **Automated System Updates**:  
  - Updating and upgrading packages before applying configurations  

- **SSH Service Restart and Verification**:  
  - Backing up the original configuration  
  - Applying changes and securely restarting the service  

This script is ideal for any Debian 12 instance requiring secure SSH access with customizable options.


