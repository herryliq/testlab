################################################################################
#
#      Author: Zachary Patten <zachary AT jovelabs DOT com>
#   Copyright: Copyright (c) Zachary Patten
#     License: Apache License, Version 2.0
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
################################################################################
#!/bin/bash
set -x

cat <<EOF | tee /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF
chmod 755 /usr/sbin/policy-rc.d

mkdir -p /lib/modules/$(uname -r)
depmod -a

apt-get -qq update
add-apt-repository -y ppa:serge-hallyn/lxc-backport
apt-get -qq update

# apt-get install linux-headers-$(uname -r)

apt-get -qq install lxc
lxc-version

git clone git://github.com/jpetazzo/sekexe

(iptables -L -t nat) || true
(grep -i iptables /etc/vz/vz.conf) || true
(lsmod | grep nat) || true

mkdir -p $HOME/.ssh
ssh-keygen -N '' -f $HOME/.ssh/id_rsa

cat $HOME/.ssh/id_rsa.pub | tee $HOME/.ssh/authorized_keys
cat $HOME/.ssh/id_rsa.pub | tee $HOME/.ssh/authorized_keys2

chown -R $SUDO_USER:$SUDO_USER $HOME/.ssh

ls -la $HOME/.ssh

eval `ssh-agent -s`
ssh-add $HOME/.ssh/id_rsa
ssh-add -L
