iso_url="https://software-download.microsoft.com/download/sg/17763.379.190312-0539.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
iso_checksum_type="sha256"
iso_checksum="221f9acbc727297a56674a0f1722b8ac7b6e840b4e1ffbdd538a9ed0da823562"
switch_name="MyNewSwitch"
vlan_id="2"
vm_name="sam-windows-2019-base"
disk_size="80000"
output_directory="output-sam-windows-2019-base"
secondary_iso_image="./extra/files/gen2-2019/std/secondary.iso"
output_vagrant="./vbox/packer-windows-2019-std-g2.box"
vagrantfile_template="./vagrant/hv_win2019_std.template"
sysprep_unattended="./extra/files/gen2-2019/std/unattend.xml"
vagrant_sysprep_unattended="./extra/files/gen2-2019/std/unattend_vagrant.xml"
upgrade_timeout="240"
memory = "6144"
cpus = "2"