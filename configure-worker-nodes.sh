#!/bin/bash

join_to_cluster ()
{
echo 'Start join_to_cluster'         
sudo /vagrant/join_command.sh
echo 'END join_to_cluster' 
}


join_to_cluster

