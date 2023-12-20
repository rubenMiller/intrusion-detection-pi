eval "dpkg -V aide; if [ $? -ne 0 ]; 
            then echo 'The package aide will be (re-)installed.'; 
            apt-get --reinstall install aide; 
            fi; 
            aide --config=/etc/aide/aide.conf --check"