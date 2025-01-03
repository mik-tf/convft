build:
	sudo bash convft.sh install

rebuild:
	sudo convft uninstall
	sudo bash convft.sh install
	
delete:
	sudo convft uninstall